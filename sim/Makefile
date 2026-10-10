SHELL := /bin/bash
.DEFAULT_GOAL := all
TB_NAME ?= tb
TESTNAME ?= uart_smoke_test
VERBOSITY ?= UVM_LOW
RUNARG ?=
SEED ?= 1
COV ?= OFF
PROJECT_ROOT := $(abspath ..)
UART_IP_VERIF_PATH ?= $(PROJECT_ROOT)
AHB_VIP_ROOT ?= $(PROJECT_ROOT)/vip/ahb_vip
UART_VIP_ROOT ?= $(PROJECT_ROOT)/vip/uart_vip
QUESTA_BIN := $(patsubst %/,%,$(dir $(shell command -v vlog)))
QUESTA_HOME ?= $(abspath $(QUESTA_BIN)/..)
DPI_GCC := $(shell command -v gcc)
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
export UART_IP_VERIF_PATH AHB_VIP_ROOT UART_VIP_ROOT UVM_HOME
ifeq ($(COV),ON)
CMP_COV_OPT = -coveropt 3 +cover=bcestf
SIM_COV_OPT = -coverage
SAVE_COV_CMD = coverage save -codeAll -cvg -onexit log/$(TESTNAME)_$(SEED).ucdb;
endif
ifeq ($(SEED),random)
override SEED := $(shell date +%s)
endif
.PHONY: all build run vlib wave cov_merge cov_report clean help
all: build
	$(MAKE) run
build: vlib
	$(QUESTA_BIN)/vlog $(CMP_COV_OPT) -timescale 1ns/1ps -mfcu -suppress 2181 \
	  +acc=rb -L $(QUESTA_HOME)/uvm-1.2 +incdir+$(UVM_HOME)/src \
	  +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR -f compile.f
vlib:
	mkdir -p log
	@test -d work || $(QUESTA_BIN)/vlib work
	$(QUESTA_BIN)/vmap work work
run:
	@mkdir -p log
	@rm -f log/$(TESTNAME)_$(SEED).log log/$(TESTNAME)_$(SEED).ucdb
	@set +e; $(QUESTA_BIN)/vsim -c $(TB_NAME) -sv_seed $(SEED) $(SIM_COV_OPT) \
	  -L $(QUESTA_HOME)/uvm-1.2 -dpicpppath $(DPI_GCC) -voptargs=+acc -assertdebug \
	  -wlf log/$(TESTNAME)_$(SEED).wlf -l log/$(TESTNAME)_$(SEED).log \
	  -do 'onerror {quit -code 2}; $(SAVE_COV_CMD) log -r /tb/*; run -all; quit -f;' \
	  +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) $(RUNARG); \
	  result=$$?; ln -sf log/$(TESTNAME)_$(SEED).log run.log; \
	  test $$result -eq 0 && python3 check_log.py log/$(TESTNAME)_$(SEED).log
wave:
	$(QUESTA_BIN)/vsim -i -view log/$(TESTNAME)_$(SEED).wlf &
cov_merge:
	$(QUESTA_BIN)/vcover merge UART_MERGE.ucdb log/uart_*.ucdb
cov_report:
	$(QUESTA_BIN)/vcover report -details -cvg -output coverage.txt UART_MERGE.ucdb
clean:
	rm -rf work log vsim.dbg
	rm -f modelsim.ini transcript run.log *.wlf *.ucdb coverage.txt regress.rpt regress.json
help:
	@echo 'make all TESTNAME=uart_smoke_test SEED=1 COV=ON'
	@echo 'make run TESTNAME=<class> SEED=<seed>; ./regress.pl; make cov_merge cov_report'
