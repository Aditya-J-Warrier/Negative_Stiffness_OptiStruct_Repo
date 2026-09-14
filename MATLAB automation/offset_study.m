% =========================================================================
% OptiStruct Shell Offset Calibration Study: Analytical vs. FEA Verification
% Geometrical and Analytical Calculations based on Parallel Axis Theorem
% =========================================================================
clear; clc;

fprintf('=================================================================\n');
fprintf('       OPTISTRUCT SHELL OFFSET STUDY CALIBRATION RESULTS        \n');
fprintf('=================================================================\n\n');

%% 1. Input Parameters (SI Units: meters, Newtons)
b = 0.1;          % Beam Width = 100 mm
h_solid = 0.1;    % Solid Core Height = 100 mm
t = 0.005;        % Shell Thickness = 5 mm

% Base Solid Core Area Moment of Inertia
I_solid = (b * h_solid^3) / 12;

%% 2. Simulation Data Collected from OptiStruct Runs (mm)
u_sim_plus  = 1.135;   % +Offset / SURFACE, BOTTOM
u_sim_zero  = 1.162;   % 0 Offset / REAL, 0.0
u_sim_minus = 1.188;   % -Offset / SURFACE, TOP

%% 3. Analytical Moment of Inertia Calculations (Parallel Axis Theorem)
% Case A: +Offset / BOTTOM (Material Flushed Outward) -> d = 52.5 mm
d_plus = (h_solid / 2) + (t / 2);
I_shell_plus = 2 * ((b * t^3)/12 + (b * t) * d_plus^2);
I_total_plus = I_solid + I_shell_plus;

% Case B: 0 Offset (Midsurface on Nodes) -> d = 50.0 mm
d_zero = h_solid / 2;
I_shell_zero = 2 * ((b * t^3)/12 + (b * t) * d_zero^2);
I_total_zero = I_solid + I_shell_zero;

% Case C: -Offset / TOP (Material Flushed Inward) -> d = 47.5 mm
d_minus = (h_solid / 2) - (t / 2);
I_shell_minus = 2 * ((b * t^3)/12 + (b * t) * d_minus^2);
I_total_minus = I_solid + I_shell_minus;

%% 4. Calculate Analytical Displacements via Inverse Stiffness Scaling
% Using the 0-offset simulation data point as our scaling anchor baseline 
% since displacement (u) is inversely proportional to Area Moment of Inertia (I).
scaling_constant = u_sim_zero * I_total_zero; 

u_pred_plus  = scaling_constant / I_total_plus;
u_pred_zero  = scaling_constant / I_total_zero;
u_pred_minus = scaling_constant / I_total_minus;

%% 5. Calculate Percentage Deviations
error_plus  = abs(u_sim_plus  - u_pred_plus)  / u_pred_plus  * 100;
error_zero  = abs(u_sim_zero  - u_pred_zero)  / u_pred_zero  * 100;
error_minus = abs(u_sim_minus - u_pred_minus) / u_pred_minus * 100;

%% 6. Format and Print the Calibration Table
fprintf('%-24s | %-13s | %-10s | %-10s | %-9s\n', ...
    'Offset Setting', 'Total I (m^4)', 'FEA (mm)', 'Analyt (mm)', 'Dev (%)');
fprintf('%s\n', repmat('-', 1, 72));

fprintf('%-24s | %-13.4e | %-10.3f | %-10.3f | %-9.2f\n', ...
    '+Offset / SURFACE,BOTTOM', I_total_plus, u_sim_plus, u_pred_plus, error_plus);

fprintf('%-24s | %-13.4e | %-10.3f | %-10.3f | %-9.2f\n', ...
    '0 offset / REAL,0.0', I_total_zero, u_sim_zero, u_pred_zero, error_zero);

fprintf('%-24s | %-13.4e | %-10.3f | %-10.3f | %-9.2f\n', ...
    '-Offset / SURFACE,TOP', I_total_minus, u_sim_minus, u_pred_minus, error_minus);

fprintf('%s\n', repmat('-', 1, 72));