import os
import subprocess
import glob

template_file = "plusfiveshellonly_scaled.fem"
solver_path = r"C:\Program Files\Altair\2022\hwsolvers\optistruct\bin\win64\optistruct.exe"

if not os.path.exists(solver_path):
    found = glob.glob(r"C:\Program Files\Altair\2022\**\optistruct.exe", recursive=True)
    if found:
        solver_path = found[0]
    else:
        raise FileNotFoundError("Could not locate OptiStruct executable!")

# Sweep from 100.1 mm to 110.0 mm
sweep_steps = [i / 10.0 for i in range(1001, 1101)]

with open(template_file, "r") as f:
    template_lines = f.readlines()

for t in sweep_steps:
    # Calculate shell thickness in mm
    shell_t = (t - 100.0) / 2.0
    # Format to exactly 8 characters wide
    t_str = f"{shell_t:<8.4f}"[:8]
    
    output_fem = f"shell_t_{t:.1f}.fem"
    new_lines = []

    for line in template_lines:
        if line.startswith("PSHELL"):
            prefix = line[:24]   # Fields 1, 2, 3
            rest = line[32:]     # Field 5 onwards
            line = f"{prefix}{t_str}{rest}"
        new_lines.append(line)

    with open(output_fem, "w") as f:
        f.writelines(new_lines)

    print(f"\nGenerated: {output_fem} | PSHELL T = {t_str.strip()} mm")
    subprocess.run([solver_path, output_fem], check=True)
    print(f"Finished solving for {t:.1f} mm")

print("\n========================================")
print("All cases processed successfully!")
print("========================================")