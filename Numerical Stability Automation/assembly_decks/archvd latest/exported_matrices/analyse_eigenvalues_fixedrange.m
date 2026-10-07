% =========================================================================
% Script: automate_eigenanalysis_full_spectrum.m
% Fully Patched Numerical & Spectral Analysis for Superelement Scaling
% =========================================================================
clear; clc; close all;

%% 1. Auto-Detect PCH Files & Setup Output Directories
pch_files = dir('*.pch');
num_cases = length(pch_files);
if num_cases == 0
    error('No .pch files found in the current directory: %s', pwd);
end

% Sort file names sequentially
file_names = {pch_files.name}';
[~, sort_idx] = sort(file_names);
pch_files = pch_files(sort_idx);

export_dir = 'Eigenvalue_Results';
if ~exist(export_dir, 'dir')
    mkdir(export_dir);
end

output_master_excel = 'Master_Eigenvalue_Summary.xlsx';

% Preallocate summary tracking arrays
testcase_names   = cell(num_cases, 1);
matrix_sizes     = zeros(num_cases, 1);
min_eigs_index1  = zeros(num_cases, 1); % Index 1 (Residual / Boundary compliance)
min_eigs_idx319  = zeros(num_cases, 1); % Index 319 (First macro-elastic mode)
max_eigs         = zeros(num_cases, 1); % Peak absolute spectral magnitude
cond_numbers_2   = zeros(num_cases, 1); % Elastic condition number (|lam_max| / |lam_319|)

fprintf('==================================================================\n');
fprintf('Starting Full-Spectrum Automated Analysis for %d Cases...\n', num_cases);
fprintf('==================================================================\n\n');

%% 2. Processing Loop
for k = 1:num_cases
    filename = pch_files(k).name;
    [~, clean_name, ~] = fileparts(filename);
    testcase_names{k} = clean_name;
    fprintf('[%3d/%3d] Processing: %s ... ', k, num_cases, filename);

    try
        K_sparse = parse_nastran_pch_fixed_field(filename);
    catch ME
        fprintf('\n  --> ERROR reading %s: %s (Skipping)\n', filename, ME.message);
        continue;
    end

    K_dense = full(K_sparse);
    N = size(K_dense, 1);
    matrix_sizes(k) = N;

    % --- 2b. Compute, Sanitize, & Order Full Eigenvalue Spectrum ---
    % --- FIXED SPECTRUM ORDERING FOR SUBTRACTION ---
    % Force physical symmetry by averaging with its transpose
    K_dense = 0.5 * (K_dense + K_dense.');

    % Compute raw eigenvalues
    evs_raw = eig(K_dense);
    evs_clean = evs_raw(~isnan(evs_raw) & ~isinf(evs_raw));

    % 1. Sort by absolute magnitude to keep boundary residuals at the front
    [~, magnitude_sort_idx] = sort(abs(evs_clean), 'ascend');

    % 2. Re-order the true algebraic eigenvalues using this magnitude mapping
    all_eigenvalues_sorted = evs_clean(magnitude_sort_idx);

    N_clean = length(all_eigenvalues_sorted);

    % Extract Spectral Anchors relative to the boundary residual block
    lam_index1   = all_eigenvalues_sorted(1);
    lam_index319 = all_eigenvalues_sorted(319); % Will now accurately map the macro-mode jump!
    lam_max      = max(abs(all_eigenvalues_sorted));

    % Save key metrics
    min_eigs_index1(k) = lam_index1;
    min_eigs_idx319(k) = lam_index319;
    max_eigs(k)        = lam_max;
    cond_numbers_2(k)  = lam_max / abs(lam_index319);

    % --- 2c. Export Entire Spectrum to CSV ---
    detail_table = table((1:N_clean)', all_eigenvalues_sorted, ...
        'VariableNames', {'Eigenvalue_Index', 'Algebraic_Eigenvalue'});
    csv_filename = fullfile(export_dir, sprintf('Eig_%s.csv', clean_name));
    writetable(detail_table, csv_filename);

    fprintf('Done (N: %d | Idx 1: %+.4e | Idx 319: %+.4e | Peak Max: %+.4e)\n', ...
        N, lam_index1, lam_index319, lam_max);
end

%% 3. Master Summary Export
SummaryTable = table(testcase_names, matrix_sizes, min_eigs_index1, min_eigs_idx319, max_eigs, cond_numbers_2, ...
    'VariableNames', {'TestCase', 'Matrix_Dimension', 'Eigenvalue_Index_1', 'Eigenvalue_Index_319_Elastic', 'Peak_Max_Eigenvalue', 'Condition_Number_Elastic'});
writetable(SummaryTable, output_master_excel, 'Sheet', 'Summary_Metrics');

%% 4. Plot Full Dataset Semi-Log Growth Curves
x_vec = 1:num_cases;
figure('Name', 'Full Spectrum Stability & Growth Study', 'Color', 'w', 'Position', [100 100 1000 750]);

tick_step = max(1, floor(num_cases / 10)); 
idx_ticks = 1:tick_step:num_cases;

% Subplot 1: Spectral Envelope Comparison
subplot(2, 1, 1);
semilogy(x_vec, max_eigs, '-o', 'LineWidth', 1.8, 'MarkerSize', 4, 'DisplayName', '|\lambda_{max}| (Peak Magnitude)');
hold on;
semilogy(x_vec, abs(min_eigs_idx319), '-s', 'LineWidth', 1.8, 'MarkerSize', 4, 'DisplayName', '|\lambda_{elastic}| (Index 319)');
semilogy(x_vec, abs(min_eigs_index1), '--x', 'LineWidth', 1.2, 'MarkerSize', 4, 'DisplayName', '|\lambda_{residual}| (Index 1)');
hold off;
grid on;
ylabel('Eigenvalue Magnitude (Log Scale)');
title('Eigenvalue Spectrum Evolution Across Parameter Sweep');
legend('Location', 'best');
xticks(idx_ticks);                  
xticklabels(testcase_names(idx_ticks)); 
xtickangle(45);

% Subplot 2: 2-Norm Elastic Condition Number
subplot(2, 1, 2);
semilogy(x_vec, cond_numbers_2, '-^r', 'LineWidth', 1.8, 'MarkerSize', 4, 'DisplayName', '\kappa_2(K_{elastic})');
hold on;
plot([1, num_cases], [1e16, 1e16], '--k', 'LineWidth', 1.5, 'DisplayName', 'Double Precision Limit (10^{16})');
hold off;
grid on;
ylabel('\kappa_2 = |\lambda_{max}| / |\lambda_{319}| (Log Scale)');
xlabel('Test Case Index');
title('Macro-Elastic Conditioning Progression');
legend('Location', 'best');
xticks(idx_ticks);
xticklabels(testcase_names(idx_ticks));
xtickangle(45);

%% =========================================================================
% Fixed-Field NASTRAN DMIG .PCH Parser Function
% =========================================================================
function K = parse_nastran_pch_fixed_field(filename)
    fid = fopen(filename, 'r');
    if fid == -1, error('Cannot open file: %s', filename); end
    
    capacity = 50000;
    row_keys = zeros(capacity, 1); 
    col_keys = zeros(capacity, 1); 
    vals     = zeros(capacity, 1);
    count = 0; 
    current_col_node = 0; 
    current_col_dof = 0;

    while ~feof(fid)
        line = fgetl(fid);
        if ~ischar(line) || isempty(line), continue; end
        
        % Pad lines to guarantee minimum field length for fixed-width slicing
        if length(line) < 72
            line = [line, repmat(' ', 1, 72 - length(line))]; 
        end
        if line(1) == '$', continue; end

        % Column Header Card: DMIG*
        if startsWith(line, 'DMIG*')
            col_node_str = strtrim(line(25:40));
            col_dof_str  = strtrim(line(41:56));
            if ~isempty(col_node_str) && ~isempty(col_dof_str)
                current_col_node = str2double(col_node_str);
                current_col_dof  = str2double(col_dof_str);
            end
            continue;
        end

        % Data Row Card: *
        if line(1) == '*'
            row_node_str = strtrim(line(9:24));
            row_dof_str  = strtrim(line(25:40));
            val_str      = strtrim(line(41:72));
            
            % Convert NASTRAN 'D' exponent syntax to standard MATLAB 'E'
            val_str = strrep(val_str, 'D', 'E');
            
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
                end
                % Encoding formula prevents key collisions: (Node * 100 + DOF)
                row_keys(count) = row_node * 100 + row_dof;
                col_keys(count) = current_col_node * 100 + current_col_dof;
                vals(count)     = val;
            end
        end
    end
    fclose(fid);

    row_keys = row_keys(1:count); 
    col_keys = col_keys(1:count); 
    vals     = vals(1:count);
    
    all_keys = [col_keys; row_keys];
    unique_keys = unique(all_keys);
    N_true = length(unique_keys);
    
    if N_true == 0
        error('Extracted 0 valid matrix entries.'); 
    end
    
    [~, row_indices] = ismember(row_keys, unique_keys);
    [~, col_indices] = ismember(col_keys, unique_keys);
    
    K = sparse(row_indices, col_indices, vals, N_true, N_true);
end