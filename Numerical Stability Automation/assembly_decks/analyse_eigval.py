import os
import glob
import csv

assembly_dir = "assembly_decks"
results_csv = "eigenvalue_stability_results.csv"
out_files = sorted(glob.glob(os.path.join(assembly_dir, "master_beam_T_*.out")))

results = []

for out_file in out_files:
    deck_name = os.path.basename(out_file)
    try:
        t_val = float(deck_name.split("master_beam_T_")[1].replace(".out", ""))
    except ValueError:
        continue

    eigenvalues = []
    with open(out_file, 'r') as f:
        reading_table = False
        for line in f:
            if "Eigenvalue Extraction Summary" in line or "EIGENVALUE ANALYSIS SUMMARY" in line.upper():
                reading_table = True
                continue
            if reading_table:
                parts = line.split()
                # Parse numeric rows [Mode_No, Eigenvalue, Frequency, ...]
                if len(parts) >= 3 and parts[0].isdigit():
                    try:
                        eig_val = float(parts[1])
                        eigenvalues.append(eig_val)
                    except ValueError:
                        continue
                elif len(parts) == 0 and len(eigenvalues) > 0:
                    reading_table = False

    if eigenvalues:
        l_min = min(eigenvalues)
        l_max = max(eigenvalues)
        kappa = l_max / l_min if l_min != 0 else float('inf')

        results.append({
            "Beam_T_mm": t_val,
            "Lambda_Min": l_min,
            "Lambda_Max": l_max,
            "Condition_Number_Kappa": kappa
        })
        print(f"T = {t_val:5.1f} mm | λ_min = {l_min:.4e} | λ_max = {l_max:.4e} | κ = {kappa:.4e}")

results.sort(key=lambda x: x["Beam_T_mm"])

with open(results_csv, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["Beam_T_mm", "Lambda_Min", "Lambda_Max", "Condition_Number_Kappa"])
    writer.writeheader()
    writer.writerows(results)

print(f"\n[+] Saved stability metrics to '{results_csv}'")