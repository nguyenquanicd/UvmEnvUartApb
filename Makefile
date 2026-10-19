# Verification tasks of the UART-APB UVM environment.
# Works with GNU make on Windows (MSYS2 / Git Bash) and on Linux. All logic is in scripts/uartvip.py.
#
#   make help                       list the targets and options
#   make doctor                     tools found on this machine
#   make check                      type-check the whole UVM testbench with the official UVM (no simulator)
#   make build                      compile the testbench (open-source Verilator by default)
#   make run TEST=baudrate_9600     one test
#   make regress                    every test; TESTS=a,b SEEDS=1,2 JOBS=4
#
# Choose the commands for your machine:
#   PLATFORM=auto|windows|linux     tool names, search paths, executable suffix (default: detected)
#   SIM=verilator|questa            open-source simulator (default) or Questa
#   PY=<python command>             default python3 (on Windows: the one of OSS CAD Suite when present)

PLATFORM ?= auto
SIM      ?= verilator

ifeq ($(PLATFORM),auto)
  ifeq ($(OS),Windows_NT)
    PLATFORM_R := windows
  else
    PLATFORM_R := linux
  endif
else
  PLATFORM_R := $(PLATFORM)
endif

ifeq ($(PLATFORM_R),windows)
  OSS_CAD_HOME ?= C:/Tools/oss-cad-suite
  ifneq ($(wildcard $(OSS_CAD_HOME)/lib/python3.exe),)
    PY ?= $(OSS_CAD_HOME)/lib/python3.exe
  endif
endif
PY ?= python3

TEST        ?= trialPat
TESTS       ?= all
SEED        ?= 1
SEEDS       ?= 1
JOBS        ?= 4
TIMEOUT_NS  ?= 100000000
WALL_TIMEOUT ?= 1800
COV         ?= 0
WAVE        ?= 0
UVM_HOME    ?=

OPTS := --platform $(PLATFORM_R) --sim $(SIM) --jobs $(JOBS) --timeout-ns $(TIMEOUT_NS) --wall-timeout $(WALL_TIMEOUT)
ifneq ($(UVM_HOME),)
  OPTS += --uvm-home $(UVM_HOME)
endif
ifeq ($(COV),1)
  OPTS += --cov
endif
ifeq ($(WAVE),1)
  OPTS += --wave
endif

RUN := $(PY) scripts/uartvip.py

.PHONY: help doctor lint check gen build run regress cov fetch-uvm clean all

help:
	@echo "Targets:  doctor lint check gen build run regress cov fetch-uvm clean all"
	@echo "Options:  PLATFORM=auto|windows|linux  SIM=verilator|questa  PY=python3"
	@echo "          TEST=<pattern>  SEED=<n>  TESTS=all|a,b  SEEDS=1,2  JOBS=<n>"
	@echo "          COV=1  WAVE=1  UVM_HOME=<dir>  TIMEOUT_NS=<ns>  WALL_TIMEOUT=<s>"
	@echo "Examples: make check"
	@echo "          make build run TEST=baudrate_9600"
	@echo "          make regress SEEDS=1,2,3 JOBS=8"
	@echo "          make regress PLATFORM=linux SIM=questa"

doctor:
	$(RUN) doctor $(OPTS)

lint:
	$(RUN) lint $(OPTS)

check:
	$(RUN) check $(OPTS)

gen:
	$(RUN) gen $(OPTS)

build:
	$(RUN) build $(OPTS)

run:
	$(RUN) run $(OPTS) --test $(TEST) --seed $(SEED)

regress:
	$(RUN) regress $(OPTS) --tests $(TESTS) --seeds $(SEEDS)

cov:
	$(RUN) cov $(OPTS)

fetch-uvm:
	$(RUN) fetch-uvm $(OPTS)

clean:
	$(RUN) clean $(OPTS)

# lint, type-check, build, then run every test
all: lint check build regress
