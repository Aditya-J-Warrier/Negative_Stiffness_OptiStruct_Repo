# --- Configuration ---
$templateFile = "plusfiveshellonly_scaled.fem"  

# Sweep total beam height from 100.1 mm to 110.0 mm in 0.1 mm steps
$thicknessSweep = foreach ($i in (1001..1100)) { $i / 10.0 }

# Find OptiStruct solver
Write-Host "Locating OptiStruct solver..." -ForegroundColor Cyan
$solver = Get-ChildItem -Path "C:\Program Files\Altair\2022" -Filter "optistruct.bat" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if (-not $solver) {
    Write-Host "Error: Could not find optistruct.bat!" -ForegroundColor Red
    exit
}
Write-Host "Found solver: $solver" -ForegroundColor Green

foreach ($t in $thicknessSweep) {
    # Direct mm thickness calculation for top/bottom shell layers
    $shellT = ($t - 100.0) / 2.0
    
    # Format to strictly fit 8-character fixed field (e.g., "0.0500  ")
    $replacementVal = $shellT.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture).PadRight(8).Substring(0, 8)
    
    $outputFem = "shell_t_$t.fem"
    
    Write-Host "`n----------------------------------------" -ForegroundColor Yellow
    Write-Host "Beam Height: ${t}mm | Shell Thickness: $replacementVal mm" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow

    $lines = Get-Content $templateFile
    $newLines = @()

    foreach ($line in $lines) {
        if ($line.StartsWith("PSHELL")) {
            # Preserve Cols 1-24 (Field 1: PSHELL, Field 2: PID, Field 3: MID)
            $prefix = $line.Substring(0, 24)
            # Preserve Cols 33+ (Field 5 onwards)
            $rest = $line.Substring(32)
            
            # Reconstruct PSHELL card with updated Field 4 (Cols 25-32)
            $line = "${prefix}${replacementVal}${rest}"
        }
        $newLines += $line
    }

    Set-Content -Path $outputFem -Value $newLines
    Write-Host "Generated: $outputFem" -ForegroundColor Green

    # Run OptiStruct in batch mode
    Write-Host "Running OptiStruct..." -ForegroundColor Cyan
    & $solver $outputFem
    
    Write-Host "Finished solving for ${t}mm" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "All cases processed successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan