#!/usr/bin/env python3
"""Verification tasks of the UART-APB UVM environment on Windows and Linux.

One backend for every task; the Makefile and the command line call it.

  doctor      show the platform, the tools found, and the UVM source in use
  lint        lint the DUT and the checkers (Verilator, then slang)
  check       type-check the whole UVM testbench with the official UVM (slang), no simulator needed
  gen         generate build/gen/tests.svh: one uvm_test per directory of pat/ (no file is copied)
  build       compile the testbench into one executable (Verilator, or Questa)
  run         run one test:        run --test baudrate_9600 --seed 3
  regress     run many tests:      regress --tests all --seeds 1,2 --jobs 4
  cov         merge and report coverage (build with --cov)
  fetch-uvm   clone the pinned Accellera UVM 2020.3.1 (Apache-2.0)
  clean       remove build/

Options that choose commands
  --platform auto|windows|linux   tool names, search paths, executable suffix, temp directory
  --sim verilator|questa          open-source default, or the commercial Questa flow

A test result comes from the line printed by cTest: "** TEST PASSED **" / "** TEST FAILED **".
A run with no such line, a simulator error, or a wall-clock timeout is a failure.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
UVM_TAG = "2020.3.1"
UVM_REPO = "https://github.com/accellera-official/uvm-core.git"
DUT_FILES = ["dut/uart_apb_if.v", "dut/uart_receiver.v", "dut/uart_transmitter.v", "dut/uart_top.v", "dut/dut_top.v"]
CHECKER_FILES = ["checker/apb_protocol_checker.sv", "checker/apb_protocol_checker_top.sv",
                 "checker/uart_protocol_checker.sv", "checker/uart_protocol_checker_top.sv"]
TB_FILES = ["uvm_comp/ifDut.sv", "sim/testTop.sv"]
DEFINES = ["UVM_NO_DPI", "UVM_CMDLINE_NO_DPI", "UVM_REGEX_NO_DPI", "INTERRUPT_COM"]


# ----------------------------------------------------------------------------
# platform and tools
# ----------------------------------------------------------------------------

class Platform:
    """Everything that differs between Windows and Linux."""

    def __init__(self, name: str):
        self.name = "windows" if (name == "auto" and os.name == "nt") else ("linux" if name == "auto" else name)
        self.win = self.name == "windows"
        self.exe = ".exe" if self.win else ""
        home = Path.home()
        if self.win:
            oss = Path(os.environ.get("OSS_CAD_HOME", "C:/Tools/oss-cad-suite"))
            msys = [Path(p) for p in [os.environ.get("MSYS2_HOME", ""), "C:/msys64", str(home / "Tools/msys64")] if p]
            # The compiler's own runtime DLLs (ucrt64) must come before the ones shipped with OSS CAD Suite,
            # otherwise a built simulator fails to start (exit code 0xC0000139).
            self.extra_path = [m / "ucrt64/bin" for m in msys] + [oss / "bin", oss / "lib"] + [m / "usr/bin" for m in msys]
            share = oss / "share" / "verilator"
            self.verilator_root = str(share) if share.is_dir() else None
            self.verilator_names = ["verilator_bin.exe"]       # the perl launcher needs Pod::Usage on Windows
            self.coverage_names = ["verilator_coverage_bin.exe", "verilator_coverage.exe"]
            self.uvm_candidates = ["C:/Tools/uvm-core", str(home / "uvm-core")]
            self.questa_dirs = [os.environ.get("QUESTA_HOME", ""), "C:/questasim64_10.2c/win64"]
        else:
            self.extra_path = []
            self.verilator_root = os.environ.get("VERILATOR_ROOT")
            self.verilator_names = ["verilator"]
            self.coverage_names = ["verilator_coverage"]
            self.uvm_candidates = [str(home / "uvm-core"), "/opt/uvm-core", "/usr/local/uvm-core"]
            self.questa_dirs = [os.environ.get("QUESTA_HOME", "")]

    def env(self) -> dict:
        """Environment for the tools. Computed once: run_one calls it from several threads."""
        if getattr(self, "_env", None) is None:
            e = dict(os.environ)
            tmp = BUILD / "tmp"
            tmp.mkdir(parents=True, exist_ok=True)
            dirs = [str(p) for p in self.extra_path if os.path.isdir(str(p))]
            e["PATH"] = os.pathsep.join(dirs + [e.get("PATH", "")])
            e["TEMP"] = e["TMP"] = e["TMPDIR"] = str(tmp)      # the compiler needs a writable temp directory
            if self.verilator_root and "VERILATOR_ROOT" not in os.environ:
                e["VERILATOR_ROOT"] = self.verilator_root
            e.setdefault("VERILATOR_SOLVER", "z3 --in")
            self._env = e
        return dict(self._env)

    @staticmethod
    def env_for(tool: str, env: dict) -> dict:
        """Environment for one prebuilt tool: its own directory first, so it loads its own DLLs (slang vs MSYS2)."""
        e = dict(env)
        d = os.path.dirname(tool)
        e["PATH"] = os.pathsep.join([d, os.path.join(os.path.dirname(d), "lib"), e.get("PATH", "")])
        return e

    def which(self, names, env=None) -> str | None:
        path = (env or self.env())["PATH"]
        for n in names if isinstance(names, list) else [names]:
            found = shutil.which(n, path=path)
            if found:
                return found
        return None


def run_cmd(cmd: list[str], env: dict, cwd: Path | None = None, log: Path | None = None, timeout: int | None = None) -> tuple[int, str]:
    """Run a command, return (exit code, combined output). Output also goes to `log`."""
    t0 = time.time()
    # The output goes straight to the log file, so a run that is killed on timeout still leaves its log.
    raw = (log if log else BUILD / "tmp" / f"cmd_{os.getpid()}_{int(t0 * 1000) % 100000}.out")
    raw.parent.mkdir(parents=True, exist_ok=True)
    rc = 0
    note = ""
    with open(raw, "w", encoding="utf-8", errors="replace") as fh:
        fh.write(f"# {' '.join(cmd)}\n# cwd {cwd}\n")
        fh.flush()
        try:
            rc = subprocess.run(cmd, cwd=cwd, env=env, stdout=fh, stderr=subprocess.STDOUT, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            rc, note = 124, f"\n[uartvip] WALL-CLOCK TIMEOUT after {timeout}s\n"
        except FileNotFoundError as exc:
            rc, note = 127, f"[uartvip] cannot run {cmd[0]}: {exc}\n"
        fh.write(f"{note}\n# seconds {time.time() - t0:.1f}  exit {rc}\n")
    out = raw.read_text(encoding="utf-8", errors="replace")
    if not log:
        raw.unlink(missing_ok=True)
    return rc, out


def posix(p: Path | str) -> str:
    return str(p).replace("\\", "/")


def resolve_uvm(plat: Platform, arg: str | None) -> Path | None:
    """Return the UVM src directory (the one that holds uvm_pkg.sv) or None."""
    cands = [arg, os.environ.get("UVM_SRC"), os.environ.get("UVM_HOME"), os.environ.get("VLSIT_UVM_HOME")] + plat.uvm_candidates
    for c in cands:
        if not c:
            continue
        for sub in ("", "src"):
            d = Path(c) / sub
            if (d / "uvm_pkg.sv").is_file():
                return d
    return None


def gxx_major(env: dict) -> int:
    gxx = shutil.which("g++", path=env["PATH"])
    if not gxx:
        return 0
    try:
        return int(subprocess.run([gxx, "-dumpversion"], capture_output=True, text=True, env=env).stdout.split(".")[0])
    except Exception:
        return 0


# ----------------------------------------------------------------------------
# tests
# ----------------------------------------------------------------------------

def pattern_dirs(include_skipped: bool = False) -> list[Path]:
    """Pattern directories. A directory with a file named SKIP is left out (the file says why)."""
    return sorted(d for d in (ROOT / "pat").iterdir()
                  if (d / "cVSequence.sv").is_file() and (include_skipped or not (d / "SKIP").exists()))


def ident(name: str) -> str:
    return re.sub(r"\W", "_", name)


def test_names() -> list[str]:
    return [f"test_{ident(d.name)}" for d in pattern_dirs()]


def cmd_gen(_a, _p) -> int:
    """Create build/gen/tests.svh. Each pattern keeps its own file; only a renamed copy is generated."""
    gen = BUILD / "gen"
    gen.mkdir(parents=True, exist_ok=True)
    inc, cls = [], []
    for d in pattern_dirs():
        i = ident(d.name)
        src = (d / "cVSequence.sv").read_text(encoding="utf-8", errors="replace")
        # The pattern becomes a subclass of the default cVSequence, as the factory override requires
        hdr = re.compile(r"class\s+cVSequence\s+extends\s+uvm_sequence\s*#\(\s*cApbTransaction\s*\)\s*;")
        if not hdr.search(src):
            raise SystemExit(f"gen: pat/{d.name}/cVSequence.sv: the class header was not recognised")
        body = hdr.sub("class @@HDR@@;", src)
        # A pattern that ends with $stop would stop the simulator with an error; end the sequence instead
        # (generated copy only; the source of the pattern is not touched)
        body = re.sub(r"^(?![ \t]*//)([^\n]*?)\$stop\s*;", r"\1return;", body, flags=re.M)
        body = re.sub(r"\bcVSequence\b", f"cVSeq_{i}", body).replace("@@HDR@@", f"cVSeq_{i} extends cVSequence")
        (gen / f"pat_{i}.svh").write_text(body, encoding="utf-8", newline="\n")
        inc.append(f'`include "pat_{i}.svh"')
        cls.append(f"""
  // Test of pattern pat/{d.name}
  class test_{i} extends cTest;
    `uvm_component_utils(test_{i})
    function new (string name = "test_{i}", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      // Replace the default test pattern before cTest creates it
      cVSequence::type_id::set_type_override(cVSeq_{i}::get_type());
      super.build_phase(phase);
    endfunction
  endclass""")
    (gen / "tests.svh").write_text("// Generated by scripts/uartvip.py gen. Do not edit.\n" + "\n".join(inc) + "\n" + "\n".join(cls) + "\n",
                                   encoding="utf-8", newline="\n")
    print(f"gen: {len(inc)} tests in {posix(gen / 'tests.svh')}")
    return 0


# ----------------------------------------------------------------------------
# lint and check
# ----------------------------------------------------------------------------

def cmd_doctor(a, plat: Platform) -> int:
    env = plat.env()
    print(f"platform   {plat.name}  (python {sys.version.split()[0]})")
    rows = [("verilator", plat.verilator_names), ("verilator cov", plat.coverage_names), ("slang", ["slang", "slang.exe"]),
            ("z3", ["z3"]), ("make", ["make"]), ("g++", ["g++"]), ("git", ["git"]), ("vsim (Questa)", ["vsim", "vsim.exe"])]
    for label, names in rows:
        p = plat.which(names, env)
        print(f"{label:14s} {p or 'missing'}")
    gm = gxx_major(env)
    if gm >= 16:
        print(f"note       g++ {gm}: -Os breaks the Verilator runtime link; the build uses -O1")
    uvm = resolve_uvm(plat, a.uvm_home)
    ver = ""
    if uvm:
        m = re.search(r'UVM_VERSION_STRING\s*=\s*"([^"]+)"', (uvm / "base/uvm_version.svh").read_text(errors="replace")) if (uvm / "base/uvm_version.svh").is_file() else None
        ver = m.group(1) if m else ""
    print(f"{'uvm src':14s} {uvm or 'missing (make fetch-uvm)'} {ver}")
    skipped = [d.name for d in pattern_dirs(True) if (d / "SKIP").exists()]
    print(f"{'patterns':14s} {len(pattern_dirs())} tests" + (f", {len(skipped)} skipped (see SKIP): {', '.join(skipped)}" if skipped else ""))
    return 0


def cmd_lint(a, plat: Platform) -> int:
    env = plat.env()
    files = [posix(ROOT / f) for f in DUT_FILES + CHECKER_FILES]
    incs = [f"+incdir+{posix(ROOT / 'sim')}"]
    vl = plat.which(plat.verilator_names, env)
    slang = plat.which(["slang", "slang.exe"], env)
    if not vl and not slang:
        print("lint: NOT_RUN (no verilator and no slang found; run: doctor)")
        return 2
    bad = 0
    if vl:
        cmd = [vl, "--lint-only", "-Wall", "-Wno-DECLFILENAME", "-Wno-UNUSEDSIGNAL", "-Wno-UNUSEDPARAM", "-Wno-PINCONNECTEMPTY",
               "-Wno-fatal", "--timescale", "1ns/1ns", "-DINTERRUPT_COM", *incs, "--top-module", "dut_top", *files]
        rc, out = run_cmd(cmd, env, ROOT, BUILD / "logs" / "lint_verilator.log")
        errs, warns = len(re.findall(r"%Error", out)), len(re.findall(r"%Warning", out))
        kinds = sorted(set(re.findall(r"%Warning-(\w+)", out)))
        print(f"lint verilator: {errs} error(s), {warns} warning(s) {' '.join(kinds)}  log: build/logs/lint_verilator.log")
        if rc != 0 and not errs:
            print(f"lint verilator: tool failed, exit {rc}")
            errs = 1
        bad += errs + (warns if a.strict else 0)
    if slang:
        cmd = [slang, "-I", posix(ROOT / "sim"), "-DINTERRUPT_COM", "--timescale", "1ns/1ns", *files[:len(DUT_FILES)], "--top", "dut_top"]
        rc, out = run_cmd(cmd, plat.env_for(slang, env), ROOT, BUILD / "logs" / "lint_slang.log")
        n_err = len(re.findall(r"\berror:", out))
        if rc != 0 and not n_err:
            print(f"lint slang:     tool failed, exit {rc}")
            n_err = 1
        print(f"lint slang:     {n_err} error(s)  log: build/logs/lint_slang.log")
        bad += n_err
    return 1 if bad else 0


def tb_args(plat: Platform, uvm: Path, gen: bool = True) -> tuple[list[str], list[str]]:
    """(include/define options, source files) of the full testbench, as plain paths."""
    opts = [f"+incdir+{posix(ROOT / 'sim')}", f"+incdir+{posix(uvm)}"]
    if gen:
        opts.append(f"+incdir+{posix(BUILD / 'gen')}")
    opts += [f"-D{d}" for d in DEFINES]
    if gen:
        opts.append("-DPATTERN_LIBRARY")
    files = [posix(ROOT / f) for f in DUT_FILES + CHECKER_FILES + TB_FILES]
    return opts, files


def cmd_check(a, plat: Platform) -> int:
    env = plat.env()
    slang = plat.which(["slang", "slang.exe"], env)
    uvm = resolve_uvm(plat, a.uvm_home)
    if not slang or not uvm:
        print(f"check: NOT_RUN ({'slang missing' if not slang else 'UVM source missing, run: fetch-uvm'})")
        return 2
    cmd_gen(a, plat)
    opts, files = tb_args(plat, uvm)
    sl = []
    for o in opts:
        sl.append(f"-I{o[8:]}" if o.startswith("+incdir+") else o)
    cmd = [slang, *sl, "--timescale", "1ns/1ns", "--allow-use-before-declare", *files, "--top", "testTop"]
    rc, out = run_cmd(cmd, plat.env_for(slang, env), ROOT, BUILD / "logs" / "check_slang.log")
    mine = [ln for ln in out.splitlines() if re.search(r"\b(error|warning):", ln) and str(uvm).replace("\\", "/") not in ln.replace("\\", "/")]
    ok = rc == 0 and "Build succeeded" in out and not [ln for ln in mine if "error:" in ln]
    print(f"check slang+UVM: {'PASS' if ok else 'FAIL'}  ({len([m for m in mine if 'error:' in m])} error(s) in the testbench)  log: build/logs/check_slang.log")
    for ln in mine[:8]:
        print("   ", ln[:170])
    return 0 if ok else 1


# ----------------------------------------------------------------------------
# build and run
# ----------------------------------------------------------------------------

def exe_path(a, plat: Platform) -> Path:
    return BUILD / a.sim / ("obj" if a.sim == "verilator" else "work") / (f"VtestTop{plat.exe}" if a.sim == "verilator" else "")


def cmd_build(a, plat: Platform) -> int:
    env = plat.env()
    uvm = resolve_uvm(plat, a.uvm_home)
    if not uvm:
        print("build: UVM source not found; run: fetch-uvm  (or set UVM_HOME / UVM_SRC)")
        return 2
    cmd_gen(a, plat)
    opts, files = tb_args(plat, uvm)
    log = BUILD / "logs" / f"build_{a.sim}.log"
    t0 = time.time()
    if a.sim == "verilator":
        vl = plat.which(plat.verilator_names, env)
        if not vl:
            print("build: verilator not found (run: doctor)")
            return 2
        obj = BUILD / "verilator" / "obj"
        if obj.exists():
            shutil.rmtree(obj, ignore_errors=True)
        obj.parent.mkdir(parents=True, exist_ok=True)   # Verilator creates one directory level only
        cmd = [vl, "--binary", "--timing", "-j", str(a.jobs), "--timescale", "1ns/1ns",
               "-Wno-fatal", "-Wno-lint", "-Wno-style", "-Wno-WIDTH", "-Wno-CASEINCOMPLETE", "-Wno-IMPLICIT",
               "--Mdir", posix(obj), "--top-module", "testTop"]
        if gxx_major(env) >= 16:
            cmd += ["-CFLAGS", "-O1"]            # gcc 16 with -Os fails to link the Verilator runtime
        if a.cov:
            cmd += ["--coverage"]
        if a.wave:
            cmd += ["--trace", "-DWAVE"]
        cmd += opts + [posix(uvm / "uvm_pkg.sv")] + files   # Verilator wants the package first
    else:
        vlog = plat.which(["vlog", "vlog.exe"] , env)
        if not vlog:
            for d in plat.questa_dirs:
                if d and (Path(d) / f"vlog{plat.exe}").is_file():
                    env["PATH"] = d + os.pathsep + env["PATH"]
                    vlog = str(Path(d) / f"vlog{plat.exe}")
        if not vlog:
            print("build: vlog (Questa) not found; set QUESTA_HOME or PATH")
            return 2
        work = BUILD / "questa" / "work"
        run_cmd([str(Path(vlog).with_name("vlib" + plat.exe)), posix(work)], env, ROOT)
        cmd = [vlog, "-sv", "-work", posix(work), "-timescale", "1ns/1ns", "-l", posix(log),
               *[o.replace("-D", "+define+", 1) if o.startswith("-D") else o for o in opts],
               *(["+cover=bcestf"] if a.cov else []), *files]
    print(f"build [{a.sim}/{plat.name}] ... (a Verilator build of the UVM testbench takes a few minutes)")
    rc, out = run_cmd(cmd, env, ROOT, log)
    ok = rc == 0 and (a.sim != "verilator" or exe_path(a, plat).is_file())
    print(f"build: {'PASS' if ok else 'FAIL'} in {time.time() - t0:.0f}s  log: {posix(log.relative_to(ROOT))}")
    if not ok:
        for ln in [x for x in out.splitlines() if re.search(r"%Error|\berror\b|undefined reference", x)][:6]:
            print("   ", ln[:200])
    return 0 if ok else 1


def parse_result(text: str, rc: int, wall: bool) -> dict:
    res = {"status": "FAIL", "reason": ""}
    passed = "** TEST PASSED **" in text
    failed = re.search(r"\*\* TEST FAILED \*\*(.*)", text)
    m_err = re.search(r"UVM_ERROR\s*:\s*(\d+)", text)
    res["uvm_errors"] = int(m_err.group(1)) if m_err else None
    sim_err = re.search(r"%Error[^\n]*", text)
    if wall:
        res["reason"] = "wall-clock timeout"
    elif sim_err:
        res["reason"] = sim_err.group(0)[:120]
    elif failed:
        res["reason"] = "test failed" + failed.group(1).strip()
    elif not passed and rc not in (0, 124):
        hint = " (a runtime DLL does not match the compiler, check PATH order)" if rc in (3221225785, 3221225781) else ""
        fatal = re.search(r"UVM_FATAL .*", text)
        res["reason"] = (fatal.group(0)[:110] if fatal else f"exit code {rc:#x}{hint}")
    elif not passed:
        fatal = re.search(r"UVM_FATAL .*", text)
        res["reason"] = fatal.group(0)[:110] if fatal else "no result line"
    elif rc != 0:
        res["reason"] = f"exit code {rc}"
    elif res["uvm_errors"]:
        res["reason"] = f"{res['uvm_errors']} UVM_ERROR"
    else:
        res["status"] = "PASS"
    res["compares_ok"] = int(m.group(1)) if (m := re.search(r"(\d+) passed, \d+ failed", text)) else None
    return res


def run_one(a, plat: Platform, test: str, seed: int) -> dict:
    env = plat.env()
    name = test if test.startswith("test_") else f"test_{ident(test)}"
    logs = BUILD / "logs"
    log = logs / f"{name}.s{seed}.log"
    t0 = time.time()
    if a.sim == "verilator":
        exe = exe_path(a, plat)
        if not exe.is_file():
            return {"test": name, "seed": seed, "status": "FAIL", "reason": "not built (run: build)", "wall": 0}
        cmd = [str(exe), f"+UVM_TESTNAME={name}", f"+UVM_VERBOSITY={a.verbosity}", f"+verilator+seed+{seed}",
               "+verilator+rand+reset+2", f"+TIMEOUT_NS={a.timeout_ns}", "+UVM_NO_RELNOTES"]
        if a.cov:
            (BUILD / "cov").mkdir(parents=True, exist_ok=True)
            cmd.append(f"+verilator+coverage+file+{posix(BUILD / 'cov' / (name + f'.s{seed}.dat'))}")
        cwd = BUILD / "verilator"
    else:
        vsim = plat.which(["vsim", "vsim.exe"], env)
        if not vsim:
            for d in plat.questa_dirs:
                if d and (Path(d) / f"vsim{plat.exe}").is_file():
                    vsim = str(Path(d) / f"vsim{plat.exe}")
        if not vsim:
            return {"test": name, "seed": seed, "status": "FAIL", "reason": "vsim not found", "wall": 0}
        work = BUILD / "questa" / "work"
        do = "run -all; quit -f" if not a.cov else f"coverage save -onexit {posix(BUILD / 'cov' / (name + f'.s{seed}.ucdb'))}; run -all; quit -f"
        (BUILD / "cov").mkdir(parents=True, exist_ok=True)
        cmd = [vsim, "-c", "-novopt", "-work", posix(work), "work.testTop", f"+UVM_TESTNAME={name}", f"+UVM_VERBOSITY={a.verbosity}",
               f"+TIMEOUT_NS={a.timeout_ns}", "-sv_seed", str(seed), *(["-coverage"] if a.cov else []), "-do", do]
        cwd = BUILD / "questa"
    cwd.mkdir(parents=True, exist_ok=True)
    rc, out = run_cmd(cmd, env, cwd, log, timeout=a.wall_timeout)
    res = parse_result(out, rc, rc == 124)
    res.update({"test": name, "seed": seed, "wall": round(time.time() - t0, 1), "log": posix(log.relative_to(ROOT))})
    return res


def cmd_run(a, plat: Platform) -> int:
    r = run_one(a, plat, a.test, a.seed)
    print(f"{r['status']:4s} {r['test']} seed={r['seed']} {r['wall']}s {r.get('reason', '')}  log: {r.get('log', '')}")
    return 0 if r["status"] == "PASS" else 1


def cmd_regress(a, plat: Platform) -> int:
    names = test_names() if a.tests == "all" else [t.strip() for t in a.tests.split(",") if t.strip()]
    seeds = [int(s) for s in a.seeds.split(",")]
    jobs = [(t, s) for t in names for s in seeds]
    print(f"regress: {len(jobs)} run(s), {a.jobs} in parallel, simulator {a.sim}")
    results = []
    with cf.ThreadPoolExecutor(max_workers=a.jobs) as ex:
        futs = {ex.submit(run_one, a, plat, t, s): (t, s) for t, s in jobs}
        for f in cf.as_completed(futs):
            r = f.result()
            results.append(r)
            print(f"  {r['status']:4s} {r['test']:55s} seed={r['seed']} {r['wall']:>6}s {r.get('reason', '')}", flush=True)
    results.sort(key=lambda r: (r["test"], r["seed"]))
    npass = sum(r["status"] == "PASS" for r in results)
    BUILD.mkdir(parents=True, exist_ok=True)
    (BUILD / "regress_summary.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    lines = ["| Test | Seed | Result | Wall s | Compares OK | Reason |", "|---|---:|---|---:|---:|---|"]
    lines += [f"| {r['test']} | {r['seed']} | {r['status']} | {r['wall']} | {r.get('compares_ok', '')} | {r.get('reason', '')} |" for r in results]
    lines += ["", f"{npass} of {len(results)} run(s) passed."]
    (BUILD / "regress_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"regress: {npass} of {len(results)} passed; summary in build/regress_summary.md")
    return 0 if npass == len(results) else 1


def cmd_cov(a, plat: Platform) -> int:
    env = plat.env()
    cov = BUILD / "cov"
    if a.sim == "verilator":
        tool = plat.which(plat.coverage_names, env)
        dats = sorted(glob.glob(str(cov / "*.dat")))
        if not tool or not dats:
            print("cov: NOT_RUN (needs verilator_coverage and .dat files; build and run with --cov)")
            return 2
        merged = cov / "merged.dat"
        run_cmd([tool, "--write", posix(merged), *map(posix, dats)], env, ROOT)
        rc, out = run_cmd([tool, "--annotate", posix(cov / "annotate"), "--annotate-min", "1", posix(merged)], env, ROOT, BUILD / "logs" / "cov.log")
        print(f"cov: merged {len(dats)} run(s); annotated source in build/cov/annotate; summary:")
        print("   " + "\n   ".join(out.strip().splitlines()[:6]))
        return 0 if rc == 0 else 1
    vcover = plat.which(["vcover", "vcover.exe"], env)
    ucdbs = sorted(glob.glob(str(cov / "*.ucdb")))
    if not vcover or not ucdbs:
        print("cov: NOT_RUN (needs vcover and .ucdb files)")
        return 2
    run_cmd([vcover, "merge", posix(cov / "merged.ucdb"), *map(posix, ucdbs)], env, ROOT)
    rc, _ = run_cmd([vcover, "report", "-html", "-htmldir", posix(cov / "html"), "-code", "bcestf", "-cvg", posix(cov / "merged.ucdb")], env, ROOT)
    print("cov: report in build/cov/html")
    return rc


def cmd_fetch_uvm(a, plat: Platform) -> int:
    dest = Path(a.uvm_home or plat.uvm_candidates[0])
    if dest.exists():
        print(f"fetch-uvm: {dest} exists; it is not overwritten")
        return 1
    git = plat.which(["git"], plat.env())
    if not git:
        print("fetch-uvm: git not found")
        return 2
    rc, out = run_cmd([git, "clone", "--depth", "1", "--branch", UVM_TAG, UVM_REPO, str(dest)], plat.env())
    print(f"fetch-uvm: {'installed ' + UVM_TAG + ' at ' + str(dest) if rc == 0 else 'FAILED'}")
    if rc != 0:
        print(out[-400:])
    return rc


def cmd_clean(_a, _p) -> int:
    shutil.rmtree(BUILD, ignore_errors=True)
    print("clean: build/ removed")
    return 0


COMMANDS = {"doctor": cmd_doctor, "lint": cmd_lint, "check": cmd_check, "gen": cmd_gen, "build": cmd_build, "run": cmd_run,
            "regress": cmd_regress, "cov": cmd_cov, "fetch-uvm": cmd_fetch_uvm, "clean": cmd_clean}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=list(COMMANDS))
    ap.add_argument("--platform", default=os.environ.get("PLATFORM", "auto"), choices=["auto", "windows", "linux"])
    ap.add_argument("--sim", default=os.environ.get("SIM", "verilator"), choices=["verilator", "questa"])
    ap.add_argument("--uvm-home", default=None)
    ap.add_argument("--test", default="trialPat")
    ap.add_argument("--tests", default="all", help="'all' or a comma list of pattern names")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--seeds", default="1", help="comma list for regress")
    ap.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 2) // 2))
    ap.add_argument("--timeout-ns", type=int, default=100_000_000, help="simulated time limit of a test (+TIMEOUT_NS)")
    ap.add_argument("--wall-timeout", type=int, default=1800, help="wall-clock limit of one run in seconds")
    ap.add_argument("--verbosity", default="UVM_LOW")
    ap.add_argument("--cov", action="store_true")
    ap.add_argument("--wave", action="store_true", help="Verilator: write build/verilator/wave.vcd")
    ap.add_argument("--strict", action="store_true", help="lint: warnings fail")
    a = ap.parse_args()
    plat = Platform(a.platform)
    return COMMANDS[a.command](a, plat)


if __name__ == "__main__":
    sys.exit(main())
