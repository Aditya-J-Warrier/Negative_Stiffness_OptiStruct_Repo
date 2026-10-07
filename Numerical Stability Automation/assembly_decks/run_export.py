import os
import glob
import shutil
import subprocess

# --- Configuration ---
baseline_template = "pluszerocomp_scaled.fem"
assembly_dir = "."
export_dir = "exported_matrices"
os.makedirs(export_dir, exist_ok=True)

# Locate optistruct.bat
search_pattern = r"C:\Program Files\Altair\2022\**\optistruct.bat"
matches = glob.glob(search_pattern, recursive=True)
if not matches:
    print("[-] Error: optistruct.bat not found in 'C:\\Program Files\\Altair\\2022\\'")
    exit(1)

solver_path = matches[0]
print(f"[+] Found OptiStruct launcher: {solver_path}")

# Read baseline template
with open(baseline_template, 'r') as f:
    template_lines = f.readlines()

# Gather input .pch files and ignore previously exported master decks
all_pch = glob.glob("shell_t_*.pch") + glob.glob("*_AX.pch")
pch_files = sorted(list(set([p for p in all_pch if not p.startswith("master_beam_")])))

print(f"[+] Generating {len(pch_files)} master deck(s)...\n")

for pch_file in pch_files:
    pch_name = os.path.basename(pch_file)
    base = os.path.splitext(pch_name)[0].lower()
    is_neg = "_negative" in base
    clean = base.replace("_negative", "")
    
    try:
        raw_val = float(clean.split("shell_t_")[1].split("_")[0])
    except (IndexError, ValueError):
        print(f"[-] Skipping {pch_name}: does not match 'shell_t_<val>' pattern.")
        continue

    delta = (raw_val - 100.0) if raw_val >= 100.0 else raw_val
    target_T = (100.0 - delta) if is_neg else (100.0 + delta)
    
    half_h = target_T / 2.0
    top_zoffs = -half_h
    bot_zoffs = +half_h

    deck_name = f"master_beam_T_{target_T:.1f}.fem"
    lines = []
    skip_continuation = False

    for line in template_lines:
        # Drop continuation line trailing PSHELL (+ ... BOTTOM)
        if skip_continuation and line.strip().startswith("+"):
            skip_continuation = False
            continue
        skip_continuation = False

        # 1. Update INCLUDE statement to point to current .pch file
        if line.strip().startswith("INCLUDE"):
            lines.append(f"INCLUDE '{pch_name}'\n")
            continue

        # 2. Update PSHELL cards (replaces '+' at col 73-80 with numeric offset and flags next line to drop)
        if line.startswith("PSHELL"):
            pid = line[8:16].strip()
            if pid == "2":
                line = line[:72].ljust(72) + f"{top_zoffs:8.4f}"[:8] + "\n"
                skip_continuation = True
            elif pid == "3":
                line = line[:72].ljust(72) + f"{bot_zoffs:8.4f}"[:8] + "\n"
                skip_continuation = True

        lines.append(line)

    with open(deck_name, 'w') as f:
        f.writelines(lines)

# --- Run OptiStruct Solver & Collect Results ---
master_decks = sorted(glob.glob("master_beam_T_*.fem"))
print(f"[+] Solving {len(master_decks)} master decks...\n")

for deck in master_decks:
    print(f"[+] Solving: {deck} ...")
    try:
        subprocess.run(f'"{solver_path}" "{deck}"', cwd=assembly_dir, check=True, shell=True)
        
        base_name = os.path.splitext(deck)[0]
        pch_options = [f"{base_name}_AX.pch", f"{base_name}.pch"]
        exported_file = next((f for f in pch_options if os.path.exists(f) and f != deck), None)
        
        if exported_file:
            shutil.copy2(exported_file, os.path.join(export_dir, exported_file))
            print(f"    -> Exported matrix: {exported_file}")
        else:
            print(f"    [-] Matrix output not found for {deck}.")
            
    except subprocess.CalledProcessError as e:
        print(f"    [-] Solver error on {deck}: {e}")

print(f"\n========================================")
print(f"[+] Complete! All exported files are inside '{export_dir}/'.")
print(f"========================================")