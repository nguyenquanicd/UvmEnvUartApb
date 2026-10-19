# Windows (PowerShell): put the open-source tools on PATH for this session.
#   . .\scripts\env_windows.ps1
# Tools expected (change the variables below or set the environment variables first):
#   OSS CAD Suite  - Verilator, slang, z3, Python      https://github.com/YosysHQ/oss-cad-suite-build
#   MSYS2 (ucrt64) - make, g++                          pacman -S make mingw-w64-ucrt-x86_64-gcc
#   UVM            - Accellera UVM 2020.3.1             make fetch-uvm
$ossCad = if ($env:OSS_CAD_HOME) { $env:OSS_CAD_HOME } else { "C:\Tools\oss-cad-suite" }
$msys2  = if ($env:MSYS2_HOME)   { $env:MSYS2_HOME }   else { "C:\msys64" }
$uvm    = if ($env:UVM_HOME)     { $env:UVM_HOME }     else { "C:\Tools\uvm-core" }

foreach ($d in @("$ossCad\bin", "$ossCad\lib", "$msys2\ucrt64\bin", "$msys2\usr\bin")) {
    if (Test-Path $d) { $env:PATH = "$d;$env:PATH" }
}
if (Test-Path "$ossCad\share\verilator") { $env:VERILATOR_ROOT = "$ossCad\share\verilator" }
if (Test-Path "$uvm\src\uvm_pkg.sv")     { $env:UVM_HOME = $uvm }

Write-Host "OSS CAD Suite: $ossCad"
Write-Host "MSYS2:         $msys2"
Write-Host "UVM_HOME:      $env:UVM_HOME"
Write-Host "Next: make doctor"
