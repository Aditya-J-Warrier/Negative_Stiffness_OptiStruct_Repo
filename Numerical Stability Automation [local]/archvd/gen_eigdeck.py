import os
import glob
import shutil

baseline_template = "pluszerocomp_scaled.fem"
output_dir = "assembly_decks"
os.makedirs(output_dir, exist_ok=True)

with open(baseline_template, 'r') as f:
    template_lines = f.readlines()

# Sanitize baseline template
clean_template = []
skip_dmig = False
for line in template_lines:
    stripped = line.strip()
    upper = stripped.upper()
    if upper.startswith("INCLUDE"):
        continue
    if "DMIG" in upper and "KAAX" in upper:
        skip_dmig = True
        continue
    if skip_dmig:
        if upper.startswith("DMIG") or stripped.startswith("*") or stripped.startswith("$") or not stripped:
            continue
        else:
            skip_dmig = False
    clean_template.append(line)

pch_files = sorted(glob.glob("*.pch"))

for pch_file in pch_files:
    pch_name = os.path.basename(pch_file)
    shutil.copy2(pch_file, os.path.join(output_dir, pch_name))
    
    # Extract target beam height
    base = os.path.splitext(pch_name)[0].lower()
    is_neg = "_negative" in base
    clean = base.replace("_negative", "")
    raw_val = float(clean.split("shell_t_")[1].split("_")[0])
    delta = (raw_val - 100.0) if raw_val >= 100.0 else raw_val
    target_T = (100.0 - delta) if is_neg else (100.0 + delta)
    
    half_h = target_T / 2.0
    top_zoffs = -half_h
    bot_zoffs = +half_h

    deck_path = os.path.join(output_dir, f"master_beam_T_{target_T:.1f}.fem")
    
    lines = []
    case_control_injected = False
    include_injected = False

    for line in clean_template:
        # 1. Update PSHELL Offsets
        if line.startswith("PSHELL"):
            pid = line[8:16].strip()
            if pid == "2":
                line = line.rstrip('\r\n').ljust(72)[:72] + f"{top_zoffs:8.4f}"[:8] + "\n"
            elif pid == "3":
                line = line.rstrip('\r\n').ljust(72)[:72] + f"{bot_zoffs:8.4f}"[:8] + "\n"

        # 2. Inject Eigenvalue Case Control
        if not case_control_injected and line.strip().startswith("SUBCASE"):
            lines.append("SUBCASE 100\n  LABEL Eigenvalue_Analysis\n  METHOD = 10\n  SPC = 1\n")
            case_control_injected = True

        lines.append(line)

        # 3. Inject EIGRL Card and PCH INCLUDE after BEGIN BULK
        if not include_injected and line.strip() == "BEGIN BULK":
            lines.append(f"$$\nINCLUDE '{pch_name}'\n$$\n")
            lines.append("EIGRL   10      0.0                             10      MASS\n")
            include_injected = True

    with open(deck_path, 'w') as f:
        f.writelines(lines)
    print(f"[+] Created Deck: {os.path.basename(deck_path)}")