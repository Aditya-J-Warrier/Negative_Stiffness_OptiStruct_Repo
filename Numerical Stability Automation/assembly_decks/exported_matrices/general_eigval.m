% =========================================================================
% Script: automate_eigenanalysis_full_spectrum.m
% Phase 4: Structural Partitioning Spectral Analysis for Superelement Sweeps
% Formulated for Generalized Eigenvalue Problem (GEVP): K*v = lambda*M*v
% =========================================================================
clear; clc; close all;

%% 1. Auto-Detect PCH Files & Extract Physical Thickness Steps
pch_files = dir('*.pch');
num_cases = length(pch_files);
if num_cases == 0
    error('No .pch files found in the current directory: %s', pwd);
end

% Preallocate tracking arrays for sorting
file_names = {pch_files.name}';
thickness_steps = zeros(num_cases, 1);

for i = 1:num_cases
    % Regex targets the number directly following '_T_' (e.g., 90.0 from master_beam_T_90.0_AX.pch)
    tokens = regexp(file_names{i}, '_T_(\d+\.\d+)', 'tokens');
    if ~isempty(tokens)
        thickness_steps(i) = str2double(tokens{1}{1});
    else
        % Fallback regex if file naming format varies slightly
        tokens_fallback = regexp(file_names{i}, '(\d+\.\d+)', 'match');
        if ~isempty(tokens_fallback)
            thickness_steps(i) = str2double(tokens_fallback{1});
        else
            thickness_steps(i) = i; 
        end
    end
end

% Sort all files sequentially by actual physical thickness
[thickness_steps, sort_idx] = sort(thickness_steps);
pch_files = pch_files(sort_idx);

% Initialize output directories
export_dir = 'Eigenvalue_Results';
if ~exist(export_dir, 'dir')
    mkdir(export_dir);
end
output_master_excel = 'Master_Eigenvalue_Summary.xlsx';

% Dynamic storage allocation
results_cell = cell(num_cases, 1);
valid_count = 0;

fprintf('==================================================================\n');
fprintf('Starting Full-Spectrum Automated GEVP Analysis for %d Cases...\n', num_cases);
fprintf('==================================================================\n\n');

%% 2. Processing Loop
for k = 1:num_cases
    filename = pch_files(k).name;
    current_thickness = thickness_steps(k);
    [~, clean_name, ~] = fileparts(filename);
    fprintf('[%3d/%3d] Thickness: %5.1f mm | Processing: %s ... ', k, num_cases, current_thickness, filename);
    
    try
        % Extract aligned K and M matrices sharing a single DOF map
        [K_sparse, M_sparse] = parse_nastran_pch_fixed_field_KM(filename);
    catch ME
        fprintf('\n  --> ERROR reading %s: %s (Skipping)\n', filename, ME.message);
        continue;
    end
    
    K_dense = full(K_sparse);
    M_dense = full(M_sparse);
    N = size(K_dense, 1);
    
    % Force physical symmetry on both matrices
    K_dense = 0.5 * (K_dense + K_dense.');
    M_dense = 0.5 * (M_dense + M_dense.');
    
    % --- GENERALIZED EIGENVALUE SOLVER: K*v = lambda*M*v ---
    % lambda = omega^2
    try
        evs_raw = eig(K_dense, M_dense);
    catch ME
        fprintf('\n  --> WARNING: Standard GEVP failed (%s). Attempting regularized solver...\n', ME.message);
        % Regularize mass matrix if singular due to mass-less DOFs
        M_reg = M_dense + 1e-12 * max(diag(M_dense)) * eye(N);
        evs_raw = eig(K_dense, M_reg);
    end
    
    % Clean non-physical numerical artifacts (NaNs, Infs, high imaginary components)
    valid_idx = ~isnan(evs_raw) & ~isinf(evs_raw) & (abs(imag(evs_raw)) < 1e-4);
    evs_clean = real(evs_raw(valid_idx));
    
    % Sort generalized eigenvalues in ascending order
    [all_eigenvalues_sorted, ~] = sort(evs_clean, 'ascend');
    N_clean = length(all_eigenvalues_sorted);
    
    % Compute corresponding natural frequencies in Hz: f = sqrt(max(0, lambda)) / (2*pi)
    freqs_hz_sorted = sqrt(max(0, all_eigenvalues_sorted)) / (2 * pi);
    
    % Macro-elastic mode cutoff marker based on 318 Boundary DOF constraint
    target_idx = 319;       % 106 nodes * 3 DOFs = 318
    if N_clean < target_idx
        fprintf('\n  --> WARNING: Matrix size (%d) smaller than target index (319). Using final index.\n', N_clean);
        target_idx = N_clean;
    end
    
    % Extract Spectral Anchors (Generalized Eigenvalues lambda = w^2)
    lam_residual_min = all_eigenvalues_sorted(1);          % Lowest artificial boundary drilling value
    lam_physical_min = all_eigenvalues_sorted(target_idx); % Absolute lowest TRUE physical structural mode
    lam_max          = all_eigenvalues_sorted(end);        % Highest structural mode
    
    % Extract Spectral Anchors (Physical Natural Frequencies in Hz)
    f_residual_min = freqs_hz_sorted(1);
    f_physical_min = freqs_hz_sorted(target_idx);
    f_max          = freqs_hz_sorted(end);
    
    % Count physical matrix breakdowns (Negative physical modes)
    num_negative_physical_modes = sum(all_eigenvalues_sorted(target_idx:end) < -1e-5);
    
    % Store metrics sequentially
    valid_count = valid_count + 1;
    results_cell{valid_count} = struct(...
        'Thickness_mm', current_thickness, ...
        'TestCase', {clean_name}, ...
        'Matrix_Dimension', N, ...
        'Eigenvalue_Drilling_Residual_Min', lam_residual_min, ...
        'Eigenvalue_Physical_Lowest', lam_physical_min, ...
        'Eigenvalue_Largest_Max', lam_max, ...
        'Freq_Hz_Physical_Lowest', f_physical_min, ...
        'Freq_Hz_Largest_Max', f_max, ...
        'Negative_Physical_Mode_Count', num_negative_physical_modes, ...
        'Condition_Number_Elastic', (abs(lam_max) / max(eps, abs(lam_physical_min)))...
    );
    
    % Export Full Spectrum (Eigenvalues and Frequencies) to CSV
    detail_table = table((1:N_clean)', all_eigenvalues_sorted, freqs_hz_sorted, ...
        'VariableNames', {'Mode_Index', 'Generalized_Eigenvalue_lambda', 'Natural_Frequency_Hz'});
    
    xlsx_detail_filename = fullfile(export_dir, sprintf('GEVP_Eig_%s.xlsx', clean_name));
    writetable(detail_table, xlsx_detail_filename);
    
    fprintf('Done (N: %d | Drilling Min: %+.2e | Physical Min Hz: %.2f Hz | Max Hz: %.2f Hz)\n', ...
        N, lam_residual_min, f_physical_min, f_max);
end

if valid_count == 0
    error('No files were successfully processed.');
end

results_struct = [results_cell{1:valid_count}];
SummaryTable = struct2table(results_struct);
writetable(SummaryTable, output_master_excel, 'Sheet', 'GEVP_Summary_Metrics');

%% 3. Visual Analytics & Growth Nature Verification
x_physical = SummaryTable.Thickness_mm;
max_ev_vec = SummaryTable.Eigenvalue_Largest_Max;
min_phys_ev_vec = SummaryTable.Eigenvalue_Physical_Lowest;
min_phys_freq_vec = SummaryTable.Freq_Hz_Physical_Lowest;

figure('Name', 'Superelement GEVP Spectral Dashboard', 'Color', 'w', 'Position', [100 50 1200 900]);
t = tiledlayout(3, 1, 'Padding', 'compact', 'TileSpacing', 'loose');

% --- Subplot 1: Semi-Log Complete Spectrum Study ---
nexttile;
semilogy(x_physical, abs(max_ev_vec), '-o', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.8, 'DisplayName', '\lambda_{max} (Largest)');
hold on;
semilogy(x_physical, abs(min_phys_ev_vec), '-s', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.6, 'DisplayName', '\lambda_{319} (Lowest Physical Elastic)');
semilogy(x_physical, abs(SummaryTable.Eigenvalue_Drilling_Residual_Min), '--x', 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1.2, 'DisplayName', '\lambda_{1} (Drilling Boundary)');
hold off;

ax1 = gca;
set(ax1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
ax1.GridColor = [0.2 0.2 0.2]; ax1.GridAlpha = 0.15; grid on; grid minor;
xlabel('Continuous Beam Thickness (mm)', 'Color', 'k', 'FontSize', 11);
ylabel('Generalized Eigenvalue Scale |\lambda|', 'Color', 'k', 'FontSize', 11);
title('Task 2: Global Spectrum Trajectory [GEVP Modes, Log-Mapped]', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'eastoutside', 'TextColor', 'k', 'Color', 'w');

% --- Subplot 2: Generalized Eigenvalue Regression ---
nexttile;
plot(x_physical, min_phys_ev_vec, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Computed \lambda_{319}');
hold on;

p1 = polyfit(x_physical, min_phys_ev_vec, 1);
p2 = polyfit(x_physical, min_phys_ev_vec, 2);
p3 = polyfit(x_physical, min_phys_ev_vec, 3);
x_fine = linspace(min(x_physical), max(x_physical), 300);

plot(x_fine, polyval(p1, x_fine), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Linear Trend');
plot(x_fine, polyval(p2, x_fine), 'g-.', 'LineWidth', 1.5, 'DisplayName', 'Quadratic Trend');
plot(x_fine, polyval(p3, x_fine), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Cubic Trend');
hold off;

y_mean = mean(min_phys_ev_vec);
ss_tot = sum((min_phys_ev_vec - y_mean).^2);
R2_lin  = 1 - (sum((min_phys_ev_vec - polyval(p1, x_physical)).^2) / ss_tot);
R2_quad = 1 - (sum((min_phys_ev_vec - polyval(p2, x_physical)).^2) / ss_tot);
R2_cube = 1 - (sum((min_phys_ev_vec - polyval(p3, x_physical)).^2) / ss_tot);

% Set explicit black axis colors & readable text
ax2 = gca;
set(ax2, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');

title_str = sprintf('Task 1: Eigenvalue Growth (Lin R^2: %.4f | Quad R^2: %.4f | Cubic R^2: %.4f)', R2_lin, R2_quad, R2_cube);
title(title_str, 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Continuous Beam Thickness (mm)', 'Color', 'k', 'FontSize', 11);
ylabel('Lowest Physical Eigenvalue \lambda_{319}', 'Color', 'k', 'FontSize', 11);
legend('Location', 'eastoutside');

% --- Subplot 3: Numerical Stability Boundary & Validity Check ---
nexttile;
yyaxis left;
plot(x_physical, min_phys_ev_vec, '-v', 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1.5, 'DisplayName', '\lambda_{319}');
hold on;
plot([min(x_physical), max(x_physical)], [0 0], 'k:', 'LineWidth', 1.2, 'DisplayName', 'Zero Stability Limit');
ylabel('Lowest Physical \lambda_{319}', 'FontSize', 11);
hold off;

yyaxis right;
bar(x_physical, SummaryTable.Negative_Physical_Mode_Count, 'FaceColor', [0.4940 0.1840 0.5560], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', 'Negative Physical Modes');
ylabel('Count of Broken Modes', 'FontSize', 11);

ax3 = gca;
set(ax3, 'Color', 'w');
ax3.YAxis(1).Color = [0.6350 0.0780 0.1840];
ax3.YAxis(2).Color = [0.4940 0.1840 0.5560];
set(ax3, 'XColor', [0.15 0.15 0.15]);
ax3.GridColor = [0.2 0.2 0.2]; ax3.GridAlpha = 0.15; grid on;
xlabel('Continuous Beam Thickness (mm)', 'Color', 'k', 'FontSize', 11);
title('Numerical Health Check: Macro-Physical Breakdown Boundary', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'eastoutside', 'TextColor', 'k', 'Color', 'w');

%% =========================================================================
% Fixed-Field NASTRAN DMIG Parser Function (K and M Matrices)
% =========================================================================
function [K, M] = parse_nastran_pch_fixed_field_KM(filename)
    fid = fopen(filename, 'r');
    if fid == -1, error('Cannot open file: %s', filename); end
    
    capacity = 100000;
    row_keys = zeros(capacity, 1); 
    col_keys = zeros(capacity, 1); 
    vals     = zeros(capacity, 1);
    mat_ids  = zeros(capacity, 1); % 1 for Stiffness (K), 2 for Mass (M)
    
    count = 0; 
    current_col_node = 0; 
    current_col_dof  = 0;
    current_mat_id   = 1; % Default to K
    
    while ~feof(fid)
        line = fgetl(fid);
        if ~ischar(line) || isempty(line), continue; end
        
        if length(line) < 72
            line = [line, repmat(' ', 1, 72 - length(line))]; 
        end
        if line(1) == '$', continue; end
        
        % Detect matrix header lines (DMIG / DMIG*)
        if startsWith(line, 'DMIG')
            tokens = strsplit(strtrim(line));
            if length(tokens) >= 2
                mat_name = upper(tokens{2});
                % Flag matrix type based on NASTRAN DMIG naming conventions
                if contains(mat_name, 'M') || contains(mat_name, 'MASS')
                    current_mat_id = 2;
                elseif contains(mat_name, 'K') || contains(mat_name, 'STIFF')
                    current_mat_id = 1;
                end
            end
            
            if startsWith(line, 'DMIG*')
                col_node_str = strtrim(line(25:40));
                col_dof_str  = strtrim(line(41:56));
                if ~isempty(col_node_str) && ~isempty(col_dof_str)
                    current_col_node = str2double(col_node_str);
                    current_col_dof  = str2double(col_dof_str);
                end
            end
            continue;
        end
        
        % Parse matrix entry data lines
        if line(1) == '*'
            row_node_str = strtrim(line(9:24));
            row_dof_str  = strtrim(line(25:40));
            val_str      = strtrim(line(41:72));
            val_str      = strrep(val_str, 'D', 'E');
            
            row_node = str2double(row_node_str);
            row_dof  = str2double(row_dof_str);
            val      = str2double(val_str);
            
            if ~isnan(row_node) && ~isnan(row_dof) && ~isnan(val)
                count = count + 1;
                if count > capacity
                    capacity = capacity * 2;
                    row_keys(capacity) = 0;
                    col_keys(capacity) = 0;
                    vals(capacity)     = 0;
                    mat_ids(capacity)  = 0;
                end
                row_keys(count) = row_node * 1000 + row_dof;
                col_keys(count) = current_col_node * 1000 + current_col_dof;
                vals(count)     = val;
                mat_ids(count)  = current_mat_id;
            end
        end
    end
    
    fclose(fid);
    
    row_keys = row_keys(1:count);
    col_keys = col_keys(1:count);
    vals     = vals(1:count);
    mat_ids  = mat_ids(1:count);
    
    % UNIFIED global DOF map across both K and M
    all_keys = [col_keys; row_keys];
    unique_keys = unique(all_keys);
    N_true = length(unique_keys);
    
    if N_true == 0
        error('Extracted 0 valid matrix entries.');
    end
    
    [~, row_indices] = ismember(row_keys, unique_keys);
    [~, col_indices] = ismember(col_keys, unique_keys);
    
    idx_K = (mat_ids == 1);
    idx_M = (mat_ids == 2);
    
    K = sparse(row_indices(idx_K), col_indices(idx_K), vals(idx_K), N_true, N_true);
    M = sparse(row_indices(idx_M), col_indices(idx_M), vals(idx_M), N_true, N_true);
    
    % Fallback if M is missing or empty in the .pch file
    if nnz(M) == 0
        warning('Mass matrix M not found in PCH file %s. Defaulting to Identity matrix.', filename);
        M = speye(N_true);
    end
end