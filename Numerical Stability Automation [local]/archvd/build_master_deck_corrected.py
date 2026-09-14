import os
import glob
import shutil

# --- Configuration ---
baseline_template = "pluszerocomp_scaled.fem"  # Baseline beam deck with dummy PSHELLs
output_dir = "assembly_decks"
pch_pattern = "*.pch"  # Matches all .pch superelement files in current directory

os.makedirs(output_dir, exist_ok=True)

if not os.path.exists(baseline_template):
    print(f"[-] Error: Base template '{baseline_template}' not found.")
    exit(1)

with open(baseline_template, 'r') as f:
    template_lines = f.readlines()

pch_files = sorted(glob.glob(pch_pattern))
if not pch_files:
    print(f"[-] No .pch files found matching pattern '{pch_pattern}'.")
    exit(1)

print(f"[+] Found {len(pch_files)} PCH file(s). Sanitizing template and generating master decks...\n")

# --- Step 1: Create a clean base template buffer ---
clean_template_lines = []
skip_dmig = False

for line in template_lines:
    stripped = line.strip()
    upper = stripped.upper()

    # 1. Strip out ALL existing INCLUDE cards unconditionally
    if upper.startswith("INCLUDE"):
        continue

    # 2. Detect start of any existing DMIG KAAX matrix header
    if "DMIG" in upper and "KAAX" in upper:
        skip_dmig = True
        continue

    # 3. Skip all matrix continuation rows while in a DMIG block
    if skip_dmig:
        if upper.startswith("DMIG") or stripped.startswith("*") or stripped.startswith("$") or not stripped:
            continue
        else:
            skip_dmig = False  # Reached next card (PSHELL, GRID, LOAD, etc.)

    clean_template_lines.append(line)

# --- Helper Functions ---
def parse_pch_info(pch_filename):
    """
    Extracts true target beam height (T_phys) and polarity from .pch filename.
    Handles both 'shell_t_100.1' and 'shell_t_0.1' naming formats.
    """
    base = os.path.splitext(pch_filename)[0]
    is_negative = "_negative" in base.lower()
    clean_base = base.lower().replace("_negative", "")
    
    raw_val = 100.0
    if "shell_t_" in clean_base:
        try:
            val_part = clean_base.split("shell_t_")[1].split("_")[0]
            raw_val = float(val_part)
        except ValueError:
            raw_val = 100.0

    # Determine thickness delta relative to 100.0 mm baseline
    delta_T = (raw_val - 100.0) if raw_val >= 100.0 else raw_val

    # Compute physical target beam height
    if is_negative:
        target_beam_T = 100.0 - delta_T
    else:
        target_beam_T = 100.0 + delta_T

    return target_beam_T, is_negative

def modify_pshell_zoffs(line, target_pid, zoffset):
    """Updates Field 10 (ZOFFS) of an OptiStruct 8-column PSHELL card for a specified PID."""
    if line.startswith("PSHELL"):
        pid_str = line[8:16].strip()
        if pid_str == str(target_pid):
            line_padded = line.rstrip('\r\n').ljust(72)
            field10 = f"{zoffset:8.4f}"[:8]
            return line_padded[:72] + field10 + "\n"
    return line

# --- Step 2: Generate Self-Contained Master Decks ---
count = 0
for pch_file in pch_files:
    pch_filename = os.path.basename(pch_file)
    dest_pch_path = os.path.join(output_dir, pch_filename)
    
    # Copy PCH file directly into assembly_decks folder for clean local execution
    shutil.copy2(pch_file, dest_pch_path)
    
    target_beam_T, is_negative = parse_pch_info(pch_filename)
    
    # --- FIXED OFFSET LOGIC ---
    # Shift distance relative to the baseline surface (modeled at 50.0mm half-height)
    surface_delta = (target_beam_T / 2.0) - 50.0
    
    # Top shell shifts outwards (+Z), Bottom shell shifts outwards (-Z)
    top_offset = +surface_delta  
    bot_offset = -surface_delta  
    # ---------------------------

    deck_name = f"master_beam_T_{target_beam_T:.1f}.fem"
    deck_path = os.path.join(output_dir, deck_name)
    
    assembly_lines = []
    include_injected = False
    
    for line in clean_template_lines:
        # Modify PSHELL ZOFFS for PID 2 (top_shell) and PID 3 (bottom_shell)
        line = modify_pshell_zoffs(line, 2, top_offset)
        line = modify_pshell_zoffs(line, 3, bot_offset)
        
        assembly_lines.append(line)
        
        # Inject EXACTLY ONE INCLUDE card right after BEGIN BULK
        if not include_injected and line.strip() == "BEGIN BULK":
            assembly_lines.append(f"$$\nINCLUDE '{pch_filename}'\n$$\n")
            include_injected = True
            
    with open(deck_path, 'w') as f:
        f.writelines(assembly_lines)
        
    print(f"  [+] Created: {deck_name:<25} | Beam T = {target_beam_T:5.1f} mm | Top ZOFFS = {top_offset:+7.4f} | Bot ZOFFS = {bot_offset:+7.4f}")
    count += 1

print(f"\n========================================")
print(f"[+] Successfully generated {count} self-contained decks in '{output_dir}/'")
print(f"========================================")
