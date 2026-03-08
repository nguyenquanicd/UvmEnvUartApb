# Script auto-install GNU make (and vim) on Windows
# Run with Administrator privileges

Write-Host "Starting environment check..." -ForegroundColor Cyan

function Ensure-MakePath {
    # look for make.exe in typical locations and add to PATH if found
    $paths = @(
        'C:\Program Files (x86)\GnuWin32\bin',
        'C:\Program Files\GnuWin32\bin',
        'C:\msys64\usr\bin',
        'C:\msys64\mingw64\bin',
        'C:\msys64\mingw32\bin'
    )
    foreach ($p in $paths) {
        $exe = Join-Path $p 'make.exe'
        if (Test-Path $exe) {
            if (-not (Get-Command make -ErrorAction SilentlyContinue)) {
                Write-Host "make.exe found at $p but not on PATH, adding..." -ForegroundColor Cyan
                $current = [Environment]::GetEnvironmentVariable('Path', 'User')
                if ($current -notlike "*${p}*") {
                    [Environment]::SetEnvironmentVariable('Path', "$current;$p", 'User')
                    Write-Host "Updated user PATH; restart shell to use make." -ForegroundColor Green
                }
            }
            return $true
        }
    }
    return $false
}

# ensure we add any existing make.exe to PATH before attempting installs
Ensure-MakePath | Out-Null

# if make already available, note it but continue to vim installation
if (Get-Command make -ErrorAction SilentlyContinue) {
    Write-Host "make already available." -ForegroundColor Green
    # do not exit; we still want to check vim
}

# try winget first
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "winget detected; attempting install via winget..." -ForegroundColor Cyan
    # prefer GnuWin32.Make package
    try {
        winget install --id GnuWin32.Make -e --silent | Out-Null
    } catch {}
    if (Get-Command make -ErrorAction SilentlyContinue) {
        Write-Host "make installed via winget." -ForegroundColor Green
        Ensure-MakePath | Out-Null
        # continue to vim check later
    }
    Write-Host "winget install didn't provide make; searching other packages..." -ForegroundColor Yellow
    # fallback generic search
    $cands = winget search --id --name make | ForEach-Object { $_.Split()[0] } | Select-Object -Unique
    foreach ($pkg in $cands) {
        try {
            winget install --id $pkg -e --silent | Out-Null
        } catch {}
        if (Get-Command make -ErrorAction SilentlyContinue) {
            Write-Host "make installed via winget package $pkg." -ForegroundColor Green
            Ensure-MakePath | Out-Null
            # continue to vim check later
        }
    }
    Write-Host "winget could not install make; continuing." -ForegroundColor Yellow
}

# still no make, try chocolatey
$chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"
if (-not (Get-Command choco -ErrorAction SilentlyContinue) -and -not (Test-Path $chocoPath)) {
    Write-Host "Chocolatey not found; attempting install..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    # enable TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    try {
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {}
}
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not available; cannot install via choco." -ForegroundColor Red
} else {
    Write-Host "Installing make via Chocolatey..." -ForegroundColor Cyan
    choco install make -y | Out-Null
}

if (Get-Command make -ErrorAction SilentlyContinue) {
    Write-Host "make installed successfully." -ForegroundColor Green
    Ensure-MakePath | Out-Null
} else {
    Write-Host "make still not found; please install manually or check logs." -ForegroundColor Red
}

Write-Host "Done. Restart terminal if PATH changed." -ForegroundColor Magenta

function Ensure-VimPath {
    # look for common vim installations and add to PATH if found
    $vimLocations = @(
        'C:\Program Files\Git\usr\bin',
        'C:\Program Files\Vim\vim92',
        'C:\Program Files (x86)\Vim\vim92'
    )
    foreach ($p in $vimLocations) {
        $exe = Join-Path $p 'vim.exe'
        if (Test-Path $exe) {
            if (-not (Get-Command vim -ErrorAction SilentlyContinue)) {
                Write-Host "vim.exe found at $p but not on PATH, adding..." -ForegroundColor Cyan
                $current = [Environment]::GetEnvironmentVariable('Path', 'User')
                if ($current -notlike "*${p}*") {
                    [Environment]::SetEnvironmentVariable('Path', "$current;$p", 'User')
                    Write-Host "Updated user PATH; restart shell to use vim." -ForegroundColor Green
                }
            }
            return $true
        }
    }
    return $false
}

# check vim presence and offer install/fix path
if (-not (Get-Command vim -ErrorAction SilentlyContinue)) {
    # first try adding known locations to PATH
    Ensure-VimPath | Out-Null
    if (-not (Get-Command vim -ErrorAction SilentlyContinue)) {
        Write-Host "vim not found on PATH." -ForegroundColor Yellow
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing vim via winget..." -ForegroundColor Cyan
            try { winget install --id vim.vim -e --silent --accept-package-agreements --accept-source-agreements | Out-Null } catch {}
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Installing vim via Chocolatey..." -ForegroundColor Cyan
            choco install vim -y | Out-Null
        } else {
            Write-Host "Winget/choco not available; please install vim manually." -ForegroundColor Red
        }
        if (Get-Command vim -ErrorAction SilentlyContinue) {
            Write-Host "vim installed successfully." -ForegroundColor Green
        }
    }
}
