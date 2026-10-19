# Linux: check the open-source tools and set UVM_HOME for this shell.
#   source scripts/env_linux.sh
# Install (Debian/Ubuntu):  sudo apt install verilator g++ make python3 git z3
# slang (optional, for `make check`): https://github.com/MikePopoloski/slang/releases
# UVM: `make fetch-uvm` clones Accellera UVM 2020.3.1 into ~/uvm-core
_uvm="${UVM_HOME:-$HOME/uvm-core}"
if [ -f "$_uvm/src/uvm_pkg.sv" ]; then
  export UVM_HOME="$_uvm"
fi
for t in verilator slang z3 g++ make python3 git; do
  if command -v "$t" >/dev/null 2>&1; then printf '%-10s %s\n' "$t" "$(command -v $t)"; else printf '%-10s missing\n' "$t"; fi
done
echo "UVM_HOME   ${UVM_HOME:-not set (run: make fetch-uvm)}"
echo "Next: make doctor"
unset _uvm
