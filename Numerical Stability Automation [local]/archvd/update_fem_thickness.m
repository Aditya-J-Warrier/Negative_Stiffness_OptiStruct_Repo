%% AUTOMATED SUPERELEMENT FACTORY (PHASE 1 - Dynamic Path Resolution)

clc; clear; close all;

template_filename = 'plusfiveshellonly_DMIG.fem'; 
base_old_thickness = 0.0025;             
thickness_sweep = [0.0050, 0.0040, 0.0030, 0.0025, 0.0020]; 

% Dynamically find optistruct.bat using PowerShell
fprintf('Locating OptiStruct solver on system...\n');
ps_command = 'powershell -Command "(Get-ChildItem -Path ''C:\Program Files\Altair\2022'' -Filter ''optistruct.bat'' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)"';
[~, solver_path] = system(ps_command);
solver_path = strtrim(solver_path); % Clean up trailing newlines

if isempty(solver_path)
    error('Could not locate optistruct.bat automatically under C:\Program Files\Altair\2022!');
else
    fprintf('Found solver at: %s\n\n', solver_path);
end

fprintf('==================================================\n');
fprintf('STARTING AUTOMATED SUPERELEMENT GENERATION\n');
fprintf('==================================================\n\n');

for idx = 1:length(thickness_sweep)
    t_current = thickness_sweep(idx);
    fprintf('--- Processing Thickness: %.4f mm ---\n', t_current);
    
    case_label = sprintf('shell_t_%.4f', t_current);
    current_fem  = [case_label, '.fem'];
    
    % Update Thickness
    update_shell_thickness(template_filename, current_fem, base_old_thickness, t_current);
    
    % Run OptiStruct using the dynamically found path
    cmd_str = sprintf('"%s" "%s"', solver_path, current_fem);
    fprintf('Executing: %s\n', cmd_str);
    
    [status, cmd_output] = system(cmd_str);
    
    if status ~= 0
        fprintf('Error: OptiStruct failed for thickness %.4f\n', t_current);
        disp(cmd_output);
        continue;
    else
        fprintf('Successfully solved for thickness %.4f\n', t_current);
    end
    fprintf('\n');
end

fprintf('==================================================\n');
fprintf('All Superelement Cases Generated Successfully!\n');
fprintf('==================================================\n');

%% Helper Function
function update_shell_thickness(template_file, output_file, old_val, new_val)
    fid_in = fopen(template_file, 'r');
    if fid_in == -1, error('Cannot open: %s', template_file); end
    file_text = textscan(fid_in, '%s', 'Delimiter', '\n', 'HeaderLines', 0);
    lines = file_text{1};
    fclose(fid_in);
    
    fid_out = fopen(output_file, 'w');
    if fid_out == -1, error('Cannot create: %s', output_file); end
    
    replaced = false;
    for i = 1:length(lines)
        line = lines{i};
        if contains(line, 'PSHELL') && contains(line, num2str(old_val))
            line = strrep(line, num2str(old_val), sprintf('%.4f', new_val));
            replaced = true;
        end
        fprintf(fid_out, '%s\n', line);
    end
    fclose(fid_out);
    
    if ~replaced
        warning('Thickness value %.4f not found in template %s!', old_val, template_file);
    end
end