## -------------------------------------------------------------
# This file created by Huy Nguyen
# Updated date: 01/09/2024
# Example run string: make TESTNAME={name_of_testcase} {optional}
#		     make run TESTNAME=ahb_base_test 
## -------------------------------------------------------------
#
TB_NAME   ?=tb  
TESTNAME  ?=uart_base_test
VERBOSITY ?=UVM_HIGH
RUNARG    ?=
SEED      ?=1
COV       ?=OFF

#==============================
ifeq ($(COV),ON)
  CMP_COV_OPT   = -coveropt 3 +cover=bcestf 
  SIM1_COV_OPT  = -coverage -coveranalysis  
  SIM2_COV_OPT  = coverage save -codeAll -cvg -onexit $(TESTNAME)_$(SEED).ucdb;
endif

ifeq ($(strip $(SEED)),random)
  SEED = $(shell /bin/date +%s)
endif

##==============================================================
VLOG =  vlog ${CMP_COV_OPT} \
        -timescale "1us/1ns" \
        +define+UVM_NO_DPI \
        -mfcu \
        -suppress 2181 \
        +acc=rmb \
        +incdir+$(UVM_HOME)/src \
        $(UVM_HOME)/src/uvm.sv
		
VSIM =  vsim \
        -sv_seed ${SEED} ${SIM1_COV_OPT}\
        -voptargs=+acc \
        -assertdebug \
        -c ${TB_NAME}\
        -do "${SIM2_COV_OPT} log -r /*;run -all;" \
        -l $(TESTNAME)_$(SEED).log	
##==============================================================

all: build run

# Independent RAL check. Keep its library separate from the existing DUT build.
RAL_WORK ?= log/ral_self_check/work
RAL_FILELIST ?= ral.f
RAL_VSIM_ARGS ?=
.PHONY: ral-build ral-check
ral-build:
	mkdir -p log/ral_self_check
	test -d $(RAL_WORK) || vlib $(RAL_WORK)
	$(filter-out +acc=rmb,$(VLOG)) -work $(RAL_WORK) -f $(RAL_FILELIST) \
	  +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR -l log/ral_self_check/build.log

ral-check: ral-build
	vsim $(RAL_VSIM_ARGS) -c -lib $(RAL_WORK) uart_ral_self_check -onfinish exit \
	  -do "run -all; quit -f -code 0" \
	  -l log/ral_self_check/run.log
	grep -q 'RAL STRUCTURAL CHECK PASSED' log/ral_self_check/run.log

build: 	vlib
	$(VLOG)  -f compile.f \
  	+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR 
		
run:
	$(VSIM) +UVM_TESTNAME=$(TESTNAME) \
          +UVM_VERBOSITY=$(VERBOSITY) \
	        ${RUNARG} 
	mv ${TESTNAME}_$(SEED).log ./log
	cp -rf vsim.wlf log/$(TESTNAME)_$(SEED).wlf
	ln -sf ./log/${TESTNAME}_$(SEED).log run.log

vlib:
	mkdir -p log
	vlib work
	vmap work work

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &

cov_gui:
	vsim -i -viewcov $(TESTNAME)_$(SEED).ucdb &

cov_merge:
	vcover merge IP_MERGE.ucdb *.ucdb

clean: 
	rm -rf work
	rm -rf log
	rm -rf *.ini
	rm -rf *.log
	rm -rf *.trace
	rm -rf *.wlf
	rm -rf transcript
	rm -rf *.ucdb
	rm -rf vsim.dbg
	rm -rf tmp_report

help:
	@echo ""
	@echo "****************************************"
	@echo "** make build: compile the design and testbench"
	@echo "** make run  : run simulation"
	@echo "** make all  : compile and run simulation"
	@echo "** make ral-check: compile and run the standalone RAL structural check"
	@echo "** make wave : open waveform"
	@echo "** make clean: clean all compiled data"
	@echo "****************************************"
	@echo ""
