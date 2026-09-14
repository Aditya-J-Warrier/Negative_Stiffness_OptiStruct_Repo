%% Timoshenko Cantilever Beam - Direct Analytical Solution
clear; clc;

% 0. Numerical result (From CalculiX)
w_num = 2.915e-3;

% 1. Parameters (As per your setup)
L = 2.0;        % Length (m)
b = 0.10;        % Width (m)
t = 0.08;        % Thickness/Height (m)
E = 2.1e11;     % Young's Modulus (Pa)
nu = 0.3;       % Poisson's Ratio
P = 1000;       % Load (N)

% 2. Derived Properties
I = (b * t^3) / 12;
A = b * t;
G = E / (2 * (1 + nu));
kappa = 5/6;    % Shear correction factor for rectangular section

% 3. The Analytical Solution Components
% Bending component (Euler-Bernoulli)
w_bending = (P * L^3) / (3 * E * I);

% Shear component (The Timoshenko addition)
w_shear = (P * L) / (kappa * G * A);

% Total Displacement
w_total = 2.935e-03;

fprintf('--- Reference Results ---\n');
fprintf('Bending Displacement: %e m\n', w_bending);
fprintf('Shear Displacement:   %e m\n', w_shear);
fprintf('Total Analytical:     %e m\n', w_total);
fprintf('Numerical Result:     %e m\n', w_num);
fprintf('Numerical Error:      %.2f%%\n', abs(w_total - w_num)/w_total * 100);