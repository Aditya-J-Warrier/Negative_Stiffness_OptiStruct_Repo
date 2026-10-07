import sys
import os
import glob

def invert_sign_in_string(val_str):
    """
    Inverts the sign of a NASTRAN DMIG numeric string directly in text form.
    Preserves exact character count and column alignment by swapping 
    the sign character with a leading space.
    """
    clean_str = val_str.strip().replace('D', 'E').replace('d', 'e')
    try:
        val = float(clean_str)
        if val == 0.0:
            return val_str  # Keep zero unchanged
    except ValueError:
        return val_str

    # Scan for the sign or first digit
    for i, char in enumerate(val_str):
        if char == '-':
            # Negative -> Swap '-' with space ' '
            return val_str[:i] + ' ' + val_str[i+1:]
        elif char.isdigit():
            # Positive -> Swap preceding space ' ' with '-'
            if i > 0 and val_str[i-1] == ' ':
                return val_str[:i-1] + '-' + val_str[i:]
            break

    return val_str

def invert_pch_matrix(input_path):
    if not os.path.exists(input_path):
        print(f"[-] Error: File '{input_path}' not found.")
        return False

    base, ext = os.path.splitext(input_path)
    output_path = f"{base}_negative{ext}"
    
    print(f"[+] Processing stiffness matrix: {input_path}")
    inverted_lines = []
    changes_count = 0

    with open(input_path, 'r') as f:
        for line in f:
            # Pass comments and DMIG header lines untouched
            if line.startswith('$') or line.startswith('DMIG'):
                inverted_lines.append(line)
                continue
            
            # Continuation lines carrying matrix terms start with '*'
            if line.startswith('*'):
                if len(line) >= 41:
                    prefix = line[:40]     # Preserve Cols 1-40 (Grid and Component IDs)
                    value_field = line[40:] # Target Cols 41+ (Matrix Value)
                    
                    # Direct string character replacement
                    new_value_field = invert_sign_in_string(value_field)
                    
                    if new_value_field != value_field:
                        changes_count += 1
                        
                    inverted_lines.append(f"{prefix}{new_value_field}")
                    continue
                
            inverted_lines.append(line)

    with open(output_path, 'w') as f:
        f.writelines(inverted_lines)
        
    print(f"    -> Inverted {changes_count} matrix values cleanly.")
    print(f"    -> Saved negative DMIG to: {output_path}\n")
    return True

def process_batch(pattern="*_AX.pch"):
    pch_files = sorted(glob.glob(pattern))
    
    if not pch_files:
        print(f"[-] No punch files matching '{pattern}' found.")
        return
        
    print(f"[+] Found {len(pch_files)} PCH file(s). Starting batch inversion...\n")
    success_count = 0
    for pch_file in pch_files:
        if invert_pch_matrix(pch_file):
            success_count += 1
            
    print("========================================")
    print(f"[+] Batch inversion finished. {success_count}/{len(pch_files)} files converted successfully.")
    print("========================================")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg.endswith(".fem"):
            base_name = os.path.splitext(arg)[0]
            target_pch = f"{base_name}_AX.pch"
            invert_pch_matrix(target_pch)
        elif arg.endswith(".pch"):
            invert_pch_matrix(arg)
        else:
            process_batch(arg)
    else:
        process_batch("*_AX.pch")