import os
import glob
import shutil
import subprocess

# --- Configuration ---
baseline_template = "pluszerocomp_scaled.fem"
assembly_dir = "."  # Running inside assembly_decks
export_dir = "exported_matrices"
os.makedirs(export_dir, exist_ok=True)

# Locate optistruct.bat dynamically
search_pattern = r"C:\Program Files\Altair\2022\**\optistruct.bat"
matches = glob.glob(search_pattern, recursive=True)
if not matches:
    print("[-] Error: optistruct.bat not found in 'C:\\Program Files\\Altair\\2022\\'")
    exit(1)

solver_path = matches[0]
print(f"[+] Found OptiStruct launcher: {solver_path}")

# --- Step 1: Read and Sanitize Baseline Template ---
with open(baseline_template, 'r') as f:
    template_lines = f.readlines()

clean_template = []
skip_dmig = False
# --- ADDED: Track and drop trailing continuation lines ---
skip_next_continuation = False 
# ---------------------------------------------------------

for line in template_lines:
    stripped = line.strip()
    upper = stripped.upper()

    # --- ADDED: Drop the explicit bottom/top continuation row ---
    if skip_next_continuation and stripped.startswith("+"):
        skip_next_continuation = False
        continue
    # Reset flag if the next line wasn't a continuation card for some reason
    skip_next_continuation = False 
    # ---------------------------------------------------------

    # Strip existing INCLUDE or EIGRL cards
    if upper.startswith("INCLUDE") or "EIGRL" in upper:
        continue
        
    # Strip existing DMIG matrix blocks
    if "DMIG" in upper and "KAAX" in upper:
        skip_dmig = True
        continue
    if skip_dmig:
        if upper.startswith("DMIG") or stripped.startswith("*") or stripped.startswith("$") or not stripped:
            continue
        else:
            skip_dmig = False

    # --- ADDED: Catch PSHELL cards to trigger the drop on the next loop ---
    if upper.startswith("PSHELL"):
        skip_next_continuation = True
    # ---------------------------------------------------------

    clean_template.append(line)


# --- Step 2: Generate Master Decks ---
pch_files = sorted(glob.glob("*.pch"))
print(f"[+] Generating {len(pch_files)} master deck(s) for raw matrix export...\n")

for pch_file in pch_files:
    pch_name = os.path.basename(pch_file)
    base = os.path.splitext(pch_name)[0].lower()
    is_neg = "_negative" in base
    clean = base.replace("_negative", "")
    
    raw_val = float(clean.split("shell_t_")[1].split("_")[0])
    delta = (raw_val - 100.0) if raw_val >= 100.0 else raw_val
    target_T = (100.0 - delta) if is_neg else (100.0 + delta)
    
    half_h = target_T / 2.0
    top_zoffs = -half_h
    bot_zoffs = +half_h

    deck_name = f"master_beam_T_{target_T:.1f}.fem"
    lines = []
    include_injected = False

    for line in clean_template:
        # Update PSHELL ZOFFS
        if line.startswith("PSHELL"):
            pid = line[8:16].strip()
            if pid == "2":
                line = line.rstrip('\r\n').ljust(72)[:72] + f"{top_zoffs:8.4f}"[:8] + "\n"
            elif pid == "3":
                line = line.rstrip('\r\n').ljust(72)[:72] + f"{bot_zoffs:8.4f}"[:8] + "\n"

        lines.append(line)

        # Inject INCLUDE and DMIG export parameter right after BEGIN BULK
        if not include_injected and line.strip() == "BEGIN BULK":
            lines.append(f"$$\nINCLUDE '{pch_name}'\n$$\n")
            lines.append("PARAM,EXTOUT,DMIGPCH\n")
            include_injected = True

    with open(deck_name, 'w') as f:
        f.writelines(lines)

# --- Step 3: Run OptiStruct & Collect PCH Files ---
master_decks = sorted(glob.glob("master_beam_T_*.fem"))
print(f"[+] Solving {len(master_decks)} master decks...\n")

for deck in master_decks:
    print(f"[+] Solving: {deck} ...")
    try:
        subprocess.run(f'"{solver_path}" "{deck}"', cwd=assembly_dir, check=True, shell=True)
        
        base_name = os.path.splitext(deck)[0]
        pch_matrix = f"{base_name}_AX.pch"
        
        if os.path.exists(pch_matrix):
            shutil.copy2(pch_matrix, os.path.join(export_dir, pch_matrix))
            print(f"    -> Successfully exported stiffness matrix: {pch_matrix}")
        else:
            print(f"    [-] Matrix file '{pch_matrix}' was not generated.")
            
    except subprocess.CalledProcessError as e:
        print(f"    [-] Solver failed for {deck}: {e}")

print(f"\n========================================")
print(f"[+] Complete! Zip '{export_dir}/' and move it to your local machine.")
print(f"========================================")