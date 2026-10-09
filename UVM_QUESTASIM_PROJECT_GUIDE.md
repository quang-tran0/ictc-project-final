# Building a Reusable UVM Project Structure with QuestaSim

This guide explains how to create a UVM verification project from an empty
directory. The APB and AHB-Lite VIPs in this repository are the working
references for the package layout, compilation order, UVM reporting, and
regression flow.

The examples below use `proto` as a placeholder protocol name. Replace it with
the real protocol or IP name, such as `uart`, `apb`, `spi`, or `i2c`.

## 1. The organizing principle

Keep reusable protocol behavior separate from project-specific verification
behavior:

```text
DUT RTL
  |
  v
protocol interface <-> reusable protocol VIP
                            |
                            v
                 project sequences and environment
                            |
                            v
                    tests and regression
```

The directory boundaries enforce this separation:

- `rtl/` contains the design under test or the RTL file list supplied by the
  designer.
- `proto_vip/` contains reusable protocol-level verification components.
- `sequences/` contains reusable traffic and scenario generation.
- `tb/` contains the project-specific environment, scoreboard, coverage, and
  top-level testbench module.
- `testcases/` contains tests that configure and control complete scenarios.
- `sim/` contains compilation file lists, environment setup, the Makefile,
  regression configuration, and generated simulation output.

A useful rule applied here is: put one UVM class in one `.sv` file, then use
one package wrapper per layer to include those files in a deliberate
dependency order.

## 2. Target directory tree

Create this source tree for a new project:

```text
my_project/
├── .gitignore
├── README.md
├── docs/                              # Optional specifications and VPlan
├── rtl/
│   ├── proto_dut.sv                   # Or RTL supplied by the designer
│   └── ...
├── proto_vip/
│   ├── proto_if.sv
│   ├── proto_transaction.sv
│   ├── proto_configuration.sv
│   ├── proto_sequencer.sv
│   ├── proto_driver.sv
│   ├── proto_monitor.sv
│   ├── proto_agent.sv
│   ├── proto_pkg.sv
│   └── proto_vip.f
├── sequences/
│   ├── proto_smoke_sequence.sv
│   ├── proto_random_sequence.sv
│   ├── ...
│   └── seq_pkg.sv
├── tb/
│   ├── proto_scoreboard.sv
│   ├── proto_environment.sv
│   ├── proto_expected_error_catcher.sv # Add only when needed
│   ├── env_pkg.sv
│   └── testbench.sv
├── testcases/
│   ├── proto_base_test.sv
│   ├── proto_smoke_test.sv
│   └── test_pkg.sv
└── sim/
    ├── Makefile
    ├── project_env.bash
    ├── compile.f
    ├── rtl.f
    ├── tb.f
    ├── regress.cfg
    └── regress.pl
```

Do not create or copy these generated paths into a new project:

```text
sim/work/
sim/log/
sim/modelsim.ini
sim/transcript
sim/vsim.wlf
sim/*.log
sim/*.ucdb
sim/run.log
```

They are created by QuestaSim or by the Makefile. Diagrams and other supporting
material are not required parts of the UVM build hierarchy.

## 3. Create the empty structure

From the parent directory of the new project:

```bash
mkdir -p my_project/{rtl,proto_vip,sequences,tb,testcases,sim,docs}
cd my_project

touch README.md .gitignore
touch rtl/proto_dut.sv
touch proto_vip/{proto_if.sv,proto_transaction.sv,proto_configuration.sv}
touch proto_vip/{proto_sequencer.sv,proto_driver.sv,proto_monitor.sv}
touch proto_vip/{proto_agent.sv,proto_pkg.sv,proto_vip.f}
touch sequences/{proto_smoke_sequence.sv,proto_random_sequence.sv,seq_pkg.sv}
touch tb/{proto_scoreboard.sv,proto_environment.sv,env_pkg.sv,testbench.sv}
touch testcases/{proto_base_test.sv,proto_smoke_test.sv,test_pkg.sv}
touch sim/{Makefile,project_env.bash,compile.f,rtl.f,tb.f,regress.cfg,regress.pl}
chmod +x sim/project_env.bash sim/regress.pl
```

Create only the files the first working test needs. Add specialized sequences,
callbacks, coverage collectors, virtual sequencers, and tests when the
verification plan requires them.

## 4. `rtl/`: design sources

### Purpose

`rtl/` is owned by the design side. The verification build should consume RTL,
not mix testbench code into it.

This repository keeps each bus DUT separate from its verification code:

```text
apb/rtl/apb_slave.sv
ahb_lite/rtl/ahb_lite_slave.sv
```

In a real project, the designer may provide many RTL files and their own file
list. If so, keep that file list and reference it from `sim/rtl.f` instead of
duplicating the source order.

### What to create

- Put synthesizable `.sv` or `.v` files here.
- Identify the exact DUT top module name and ports.
- Put packages and lower-level modules before modules that instantiate them.
- Keep generated netlists, libraries, and vendor sources in separate file
  lists if they require different compiler options.

### `sim/rtl.f`

For one RTL file:

```text
../rtl/proto_dut.sv
```

For multiple files:

```text
../rtl/proto_types_pkg.sv
../rtl/proto_fifo.sv
../rtl/proto_core.sv
../rtl/proto_dut.sv
```

Every path is interpreted from `sim/`, because all build commands are run
there. The order is compilation order, not an alphabetical inventory.

## 5. `proto_vip/`: reusable protocol VIP

### Purpose

This directory owns behavior that can be reused with any DUT implementing the
same protocol. The `apb_vip/` and `ahb_lite_vip/` directories contain an
interface, transaction, configuration, sequencer, driver, monitor, agent,
package wrapper, and VIP file list.

The standard dependency direction is:

```text
proto_transaction ─┐
proto_configuration ├─> driver/monitor/sequencer ─> proto_agent
proto_if ───────────┘
```

### `proto_if.sv`

The interface holds DUT pins and, for synchronous protocols, clocking blocks
and modports. It is a static SystemVerilog construct, so compile it outside the
class package.

Minimal pattern:

```systemverilog
`timescale 1ns/1ps

interface proto_if(input logic clk);
  logic reset_n;
  logic valid;
  logic ready;
  logic [31:0] data;

  clocking driver_cb @(posedge clk);
    output valid, data;
    input ready;
  endclocking

  clocking monitor_cb @(posedge clk);
    input reset_n, valid, ready, data;
  endclocking
endinterface
```

The APB and AHB-Lite interfaces use clocking blocks so drivers and monitors
sample their synchronous handshakes consistently.

### `proto_transaction.sv`

The transaction is the protocol-level data model. It should extend
`uvm_sequence_item`, contain randomized fields and constraints, register with
the factory, and implement any comparison, packing, or display behavior needed
by the scoreboard and logs.

```systemverilog
class proto_transaction extends uvm_sequence_item;
  rand bit [31:0] data;

  `uvm_object_utils_begin(proto_transaction)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "proto_transaction");
    super.new(name);
  endfunction
endclass
```

Protocol fields belong here; project scenarios do not. For example, address,
direction, and data belong to a bus transaction, while "run 50 transfers"
belongs in a sequence or test.

### `proto_configuration.sv`

The configuration object centralizes parameters used by the agent, driver, and
monitor. It normally stores the virtual interface, active/passive mode, timing,
and protocol options.

```systemverilog
class proto_configuration extends uvm_object;
  virtual proto_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils_begin(proto_configuration)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "proto_configuration");
    super.new(name);
  endfunction

  function bit is_valid();
    return vif != null;
  endfunction
endclass
```

Validate configuration at the agent boundary and issue `uvm_fatal` for an
unusable configuration. This fails early, before a null interface causes a
difficult runtime error.

### `proto_sequencer.sv`

The sequencer arbitrates transactions generated by sequences:

```systemverilog
class proto_sequencer extends uvm_sequencer #(proto_transaction);
  `uvm_component_utils(proto_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
```

Keep it this small until the protocol genuinely needs extra state or layering.

### `proto_driver.sv`

The driver converts transactions into pin-level activity. Its minimum
responsibilities are:

1. Get `proto_configuration` from `uvm_config_db` in `build_phase`.
2. Cache and validate the virtual interface.
3. Initialize driven signals to a legal idle state.
4. Repeatedly call `get_next_item`, drive one complete transaction, then call
   `item_done`.
5. Optionally publish the accepted request through an analysis port for
   end-to-end checking.

```systemverilog
class proto_driver extends uvm_driver #(proto_transaction);
  `uvm_component_utils(proto_driver)

  proto_configuration cfg;
  virtual proto_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(proto_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("PROTO_CFG", "Driver configuration was not supplied")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("PROTO_VIF", "Driver virtual interface is null")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      // Drive one complete protocol transfer here.
      seq_item_port.item_done();
    end
  endtask
endclass
```

Do not call `item_done` before all pins for the item have been driven. Do not
put test-specific delays or packet counts in the driver.

### `proto_monitor.sv`

The monitor observes pins without driving them, reconstructs transactions,
checks protocol rules, samples functional coverage, and publishes observed
transactions through `uvm_analysis_port`.

```systemverilog
class proto_monitor extends uvm_monitor;
  `uvm_component_utils(proto_monitor)

  proto_configuration cfg;
  virtual proto_if vif;
  uvm_analysis_port #(proto_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(proto_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("PROTO_CFG", "Monitor configuration was not supplied")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      proto_transaction item;
      // Wait for a transfer and sample every field here.
      item = proto_transaction::type_id::create("item");
      analysis_port.write(item);
    end
  endtask
endclass
```

Allocate or clone a fresh transaction before publishing it. Reusing one object
and modifying it after `write()` can corrupt items already stored by
subscribers.

### `proto_agent.sv`

The agent is the reusable container:

- Always create the monitor.
- Create the driver and sequencer only when `cfg.is_active == UVM_ACTIVE`.
- Connect `driver.seq_item_port` to `sequencer.seq_item_export`.
- Forward monitor and optional driver analysis ports to the environment.

This active/passive split lets the same VIP drive a DUT or only observe an
existing bus.

### `proto_pkg.sv`

The package imports UVM and includes VIP classes in dependency order:

```systemverilog
`ifndef GUARD_PROTO_PKG__SV
`define GUARD_PROTO_PKG__SV

package proto_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "proto_transaction.sv"
  `include "proto_configuration.sv"
  `include "proto_driver.sv"
  `include "proto_monitor.sv"
  `include "proto_sequencer.sv"
  `include "proto_agent.sv"
endpackage : proto_pkg

`endif
```

The agent must appear after the driver, monitor, and sequencer because it
references their types. The interface is deliberately absent from the package.

An optional `proto_define.sv` may hold compile-time width macros and shared
definitions. Add it only if consumers must override a constant with a compiler
option such as `+define+PROTO_ADDR_WIDTH=32`. Prefer configuration-object
fields for values that may change during a simulation.

### `proto_vip.f`

This is the VIP's root compilation list:

```text
+incdir+${PROTO_VIP_ROOT}
${PROTO_VIP_ROOT}/proto_if.sv
${PROTO_VIP_ROOT}/proto_pkg.sv
```

The order is mandatory: the interface is compiled before the package because
the configuration, driver, and monitor use `virtual proto_if`. `+incdir+`
allows `proto_pkg.sv` to find class files included by basename.

## 6. `sequences/`: stimulus scenarios

### Purpose

A sequence controls a VIP sequencer and creates protocol transactions. A test
controls the complete verification scenario and may start several sequences on
several agents.

Keep these two levels distinct:

- Sequence: "generate legal random protocol transfers."
- Test: "configure two endpoints, run sequences concurrently, wait for the
  scoreboard, and decide pass/fail."

### Sequence pattern

```systemverilog
class proto_random_sequence extends uvm_sequence #(proto_transaction);
  `uvm_object_utils(proto_random_sequence)

  int unsigned num_items = 10;

  function new(string name = "proto_random_sequence");
    super.new(name);
  endfunction

  task body();
    repeat (num_items) begin
      proto_transaction item;
      item = proto_transaction::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_fatal("PROTO_RANDOMIZE", "Transaction randomization failed")
      finish_item(item);
    end
  endtask
endclass
```

Use explicit sequences for corner cases and error injection. Keep default
traffic legal; otherwise random tests can become dominated by invalid input.

### `seq_pkg.sv`

```systemverilog
`ifndef GUARD_PROTO_SEQ_PKG__SV
`define GUARD_PROTO_SEQ_PKG__SV

package seq_pkg;
  import uvm_pkg::*;
  import proto_pkg::*;
  `include "uvm_macros.svh"

  `include "proto_smoke_sequence.sv"
  `include "proto_random_sequence.sv"
endpackage : seq_pkg

`endif
```

Whenever a sequence file is added, include it here after any class it extends
or helper type it uses.

## 7. `tb/`: project-specific environment

### `proto_scoreboard.sv`

The scoreboard receives expected and observed transactions and makes the test
self-checking. Its responsibilities normally include:

- Subscribe to driver/reference-model and monitor analysis ports.
- Clone incoming objects before queueing them.
- Compare the correct streams in order, or match by transaction ID for an
  out-of-order protocol.
- Report mismatches with `uvm_error`.
- Detect unexpected actual items and missing expected items.
- Check that meaningful work occurred; a test that compared zero items should
  not silently pass.
- Print a compact summary in `report_phase`.

The APB and AHB-Lite scoreboards use one observed stream and predict the four
DUT registers from completed writes before checking completed reads.

### `proto_environment.sv`

The environment creates agents, scoreboard, coverage collectors, and reference
models, then connects their analysis ports:

```systemverilog
class proto_env extends uvm_env;
  `uvm_component_utils(proto_env)

  proto_agent agent;
  proto_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = proto_agent::type_id::create("agent", this);
    scoreboard = proto_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor_ap.connect(scoreboard.actual_imp);
  endfunction
endclass
```

Set each agent's configuration from the test before creating the environment.
UVM `build_phase` proceeds top-down, so the child can retrieve the value when
its own build phase runs.

### `proto_expected_error_catcher.sv`

For tests that deliberately provoke an error, use `uvm_report_catcher`
narrowly. Match a stable report ID, record how many messages were caught, and
demote only the expected severity:

```systemverilog
class proto_expected_error_catcher extends uvm_report_catcher;
  string expected_ids[$];
  int unsigned caught_count;

  function new(string name = "proto_expected_error_catcher");
    super.new(name);
  endfunction

  function void add_id(string id);
    expected_ids.push_back(id);
  endfunction

  virtual function action_e catch();
    if (get_severity() == UVM_ERROR) begin
      foreach (expected_ids[index]) begin
        if (get_id() == expected_ids[index]) begin
          caught_count++;
          set_severity(UVM_INFO);
          return THROW;
        end
      end
    end
    return THROW;
  endfunction
endclass
```

Register it before the expected error occurs:

```systemverilog
error_catcher = new("error_catcher");
error_catcher.add_id("EXPECTED_PROTOCOL_ERROR");
uvm_report_cb::add(null, error_catcher);
```

Passing `null` applies the catcher globally. A component handle limits it to
that component. Never demote every `UVM_ERROR`: doing so can hide a real DUT or
testbench defect. The test must also verify `caught_count`; otherwise it can
pass even when the expected error never occurred.

### `env_pkg.sv`

```systemverilog
`ifndef GUARD_PROTO_ENV_PKG__SV
`define GUARD_PROTO_ENV_PKG__SV

package env_pkg;
  import uvm_pkg::*;
  import proto_pkg::*;
  `include "uvm_macros.svh"

  `include "proto_expected_error_catcher.sv"
  `include "proto_scoreboard.sv"
  `include "proto_environment.sv"
endpackage : env_pkg

`endif
```

If no test expects an error yet, omit the catcher file and its include.

### `testbench.sv`

The top-level module is the bridge between static HDL and the UVM class world:

1. Import UVM, the VIP package, and the test package.
2. Instantiate clocks, resets, interfaces, and the DUT.
3. Put virtual interfaces into `uvm_config_db` using field names the base test
   expects.
4. Call `run_test()` without hard-coding a test name; the Makefile supplies
   `+UVM_TESTNAME`.

```systemverilog
module testbench;
  import uvm_pkg::*;
  import proto_pkg::*;
  import test_pkg::*;

  logic clk = 1'b0;
  always #5ns clk = ~clk;

  proto_if proto_vif(clk);

  proto_dut dut (
    .clk     (clk),
    .reset_n (proto_vif.reset_n),
    .valid   (proto_vif.valid),
    .ready   (proto_vif.ready),
    .data    (proto_vif.data)
  );

  initial begin
    uvm_config_db #(virtual proto_if)::set(
      uvm_root::get(), "uvm_test_top", "vif", proto_vif
    );
    run_test();
  end
endmodule
```

The configuration path, field name, and type must match the base test's `get`
call exactly.

## 8. `testcases/`: complete test scenarios

### `proto_base_test.sv`

The base test should perform common setup once:

- Create configuration objects.
- Retrieve virtual interfaces placed by `testbench.sv`.
- Apply default legal configuration.
- Set agent configurations into `uvm_config_db`.
- Create the environment.
- Read common plusargs such as `NUM_ITEMS`.
- Provide shared wait and count-check helpers.
- Determine pass/fail from UVM severity counts and scoreboard status.

The ordering inside `build_phase` matters:

```systemverilog
cfg = proto_configuration::type_id::create("cfg");

if (!uvm_config_db #(virtual proto_if)::get(this, "", "vif", cfg.vif))
  `uvm_fatal("PROTO_VIF", "vif was not supplied by testbench")

configure();
uvm_config_db #(proto_configuration)::set(this, "env.agent", "cfg", cfg);
env = proto_env::type_id::create("env", this);
```

Use objections around time-consuming stimulus:

```systemverilog
task run_phase(uvm_phase phase);
  proto_smoke_sequence sequence;

  phase.raise_objection(this);
  sequence = proto_smoke_sequence::type_id::create("sequence");
  sequence.start(env.agent.sequencer);
  // Wait until the monitor and scoreboard have consumed the final transfer.
  phase.drop_objection(this);
endtask
```

Use UVM reporting rather than `$display` for verification messages:

- `uvm_info` is for informative messages and is filtered by verbosity.
- `uvm_warning` reports a warning and is not filtered by verbosity.
- `uvm_error` reports and globally counts an error.
- `uvm_fatal` reports an unrecoverable error and terminates the simulation.

The Makefile expects an explicit pass marker. A typical base-test contract is:

```systemverilog
function void report_phase(uvm_phase phase);
  uvm_report_server server;

  super.report_phase(phase);
  server = uvm_report_server::get_server();
  if ((server.get_severity_count(UVM_ERROR) == 0) &&
      (server.get_severity_count(UVM_FATAL) == 0) &&
      (env.scoreboard.compared_count > 0))
    `uvm_info("TEST_STATUS", "TEST PASSED", UVM_NONE)
  else
    `uvm_error("TEST_STATUS", "TEST FAILED")
endfunction
```

`UVM_NONE` ensures the pass marker is printed regardless of
`+UVM_VERBOSITY`. Print exactly one final status and do not print `TEST PASSED`
until every check has completed.

### Derived tests

Each test file should contain one factory-registered class. A derived test
should change only what distinguishes its scenario:

```systemverilog
class proto_smoke_test extends proto_base_test;
  `uvm_component_utils(proto_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure();
    super.configure();
    // Override only the configuration required by this test.
  endfunction
endclass
```

Useful test categories in the APB and AHB-Lite projects are:

- Basic register reads and writes.
- Directed handshake and wait-state checks.
- Random legal read/write transfers.
- Back-to-back transfers.
- Analysis-port, scoreboard, and end-of-test accounting tests.
- Functional coverage closure tests.

### `test_pkg.sv`

```systemverilog
`ifndef GUARD_PROTO_TEST_PKG__SV
`define GUARD_PROTO_TEST_PKG__SV

package test_pkg;
  import uvm_pkg::*;
  import proto_pkg::*;
  import seq_pkg::*;
  import env_pkg::*;
  `include "uvm_macros.svh"

  `include "proto_base_test.sv"
  `include "proto_smoke_test.sv"
endpackage : test_pkg

`endif
```

Base classes must be included before derived classes. A class registered with
the factory but omitted from `test_pkg.sv` cannot be selected through
`+UVM_TESTNAME`.

## 9. `sim/`: compile, run, debug, and regress

Run all commands from this directory, or use `make -C sim ...` from the project
root. The relative file-list paths and the current `project_env.bash` assume
that `sim/` is the working directory.

### 9.1 Compilation hierarchy

The current project uses three file-list levels:

```text
compile.f
├── rtl.f
│   └── RTL sources
└── tb.f
    ├── proto_vip.f
    │   ├── proto_if.sv
    │   └── proto_pkg.sv
    ├── env_pkg.sv
    ├── seq_pkg.sv
    ├── test_pkg.sv
    └── testbench.sv
```

`compile.f` should remain small:

```text
-f rtl.f
-f tb.f
```

`tb.f` supplies include directories and compiles layers in dependency order:

```text
+incdir+${PROTO_VERIF_ROOT}/sequences
+incdir+${PROTO_VERIF_ROOT}/testcases
+incdir+${PROTO_VERIF_ROOT}/tb

// Reusable VIP: interface first, then package.
-f ${PROTO_VIP_ROOT}/proto_vip.f

// Project-specific packages and top-level module.
${PROTO_VERIF_ROOT}/tb/env_pkg.sv
${PROTO_VERIF_ROOT}/sequences/seq_pkg.sv
${PROTO_VERIF_ROOT}/testcases/test_pkg.sv
${PROTO_VERIF_ROOT}/tb/testbench.sv
```

This creates the complete dependency chain:

```text
uvm_pkg -> proto_if -> proto_pkg -> env_pkg/seq_pkg -> test_pkg -> testbench
```

Do not list both an included class file and its package wrapper in a file list.
That compiles the same class in two scopes and usually causes duplicate or
unresolved type errors.

### 9.2 `project_env.bash`

The current projects place QuestaSim commands on `PATH`; the Makefile discovers
`QUESTA_HOME` and its bundled UVM 1.2 automatically. `project_env.bash` exports
the same paths for interactive use.

A reusable environment file is:

```bash
#!/usr/bin/env bash

# Replace this with the setup command required by the licensed installation.
# setup_dva

export UVM_HOME=/path/to/questasim/verilog_src/uvm-1.2
export PROTO_VERIF_ROOT=./..
export PROTO_VIP_ROOT="$PROTO_VERIF_ROOT/proto_vip"
```

Use it from `sim/`:

```bash
cd sim
source ./project_env.bash
```

Because `source` changes the current shell, verify the exported values before
building:

```bash
command -v vlog
command -v vsim
printf '%s\n' "$UVM_HOME" "$PROTO_VERIF_ROOT" "$PROTO_VIP_ROOT"
```

If you want the environment script to work from any directory, derive the
project path from the script location instead of using `./..`:

```bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PROTO_VERIF_ROOT="$(cd -- "$script_dir/.." && pwd)"
export PROTO_VIP_ROOT="$PROTO_VERIF_ROOT/proto_vip"
unset script_dir
```

### 9.3 Reusable QuestaSim Makefile

The following template preserves the behavior of the APB and AHB-Lite
Makefiles. Replace `PROTO` and `proto` in the exported path names and coverage
glob.
Recipe lines under targets must begin with a real tab, not spaces.

```make
TB_NAME   ?= testbench
TESTNAME  ?= proto_base_test
VERBOSITY ?= UVM_HIGH
RUNARG    ?=
SEED      ?= 1
COV       ?= OFF

PROJECT_ROOT    := $(abspath ..)
PROTO_VERIF_ROOT ?= $(PROJECT_ROOT)
PROTO_VIP_ROOT   ?= $(PROTO_VERIF_ROOT)/proto_vip
QUESTA_HOME      ?= $(abspath $(dir $(shell command -v vlog))/..)
UVM_HOME         ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
DPI_GCC          := $(shell command -v gcc 2>/dev/null)
DPI_GCC_OPT      := $(if $(DPI_GCC),-dpicpppath $(DPI_GCC))

export PROTO_VERIF_ROOT PROTO_VIP_ROOT UVM_HOME

ifeq ($(COV),ON)
  CMP_COV_OPT  = -coveropt 3 +cover=bcestf
  SIM_COV_OPT  = -coverage -coveranalysis
  SAVE_COV_CMD = coverage save -codeAll -cvg -onexit $(TESTNAME)_$(SEED).ucdb;
endif

ifeq ($(strip $(SEED)),random)
  SEED = $(shell /bin/date +%s)
endif

VLOG = vlog $(CMP_COV_OPT) \
       -timescale "1ns/1ps" \
       -mfcu \
       -suppress 2181 \
       +acc=rb \
       -L $(QUESTA_HOME)/uvm-1.2 \
       +incdir+$(UVM_HOME)/src

VSIM = vsim \
       -sv_seed $(SEED) $(SIM_COV_OPT) \
       -L $(QUESTA_HOME)/uvm-1.2 \
       $(DPI_GCC_OPT) \
       -voptargs=+acc \
       -assertdebug \
       -c $(TB_NAME) \
       -do "$(SAVE_COV_CMD) log -r /*; run -all; quit -f;" \
       -l $(TESTNAME)_$(SEED).log

.PHONY: all build run vlib wave cov_gui cov_merge clean help

all: build run

build: vlib
	$(VLOG) -f compile.f \
	  +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

run:
	$(VSIM) +UVM_TESTNAME=$(TESTNAME) \
	  +UVM_VERBOSITY=$(VERBOSITY) \
	  $(RUNARG)
	mv $(TESTNAME)_$(SEED).log ./log
	cp -f vsim.wlf log/$(TESTNAME)_$(SEED).wlf
	ln -sf ./log/$(TESTNAME)_$(SEED).log run.log
	grep -q "TEST PASSED" ./log/$(TESTNAME)_$(SEED).log

vlib:
	mkdir -p log
	vlib work
	vmap work work

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &

cov_gui:
	vsim -i -viewcov $(TESTNAME)_$(SEED).ucdb &

cov_merge:
	vcover merge PROTO_MERGE.ucdb proto_*.ucdb

clean:
	rm -rf work log
	rm -f modelsim.ini transcript run.log
	rm -f *.log *.trace *.wlf *.ucdb
	rm -rf vsim.dbg tmp_report

help:
	@echo "make build                         Compile RTL and testbench"
	@echo "make run TESTNAME=<class> SEED=1  Run one compiled test"
	@echo "make all TESTNAME=<class>         Compile and run"
	@echo "make wave                          Open the latest waveform"
	@echo "make cov_merge                     Merge coverage databases"
	@echo "make clean                         Remove generated output"
```

The template archives the log before checking the pass marker, so a failed test
log remains available to the regression report.

Do not run `make -j`: `all: build run` expresses two prerequisites, and a
parallel Make may start simulation before compilation finishes.

### 9.4 Makefile variables

| Variable | Meaning | Typical override |
|---|---|---|
| `TB_NAME` | Elaborated HDL top module | Usually remains `testbench` |
| `TESTNAME` | UVM test class passed through `+UVM_TESTNAME` | `TESTNAME=proto_smoke_test` |
| `VERBOSITY` | Global UVM info threshold | `UVM_LOW`, `UVM_MEDIUM`, `UVM_HIGH`, or `UVM_FULL` |
| `RUNARG` | Extra simulator plusargs consumed by testbench code | `RUNARG=+NUM_ITEMS=100` |
| `SEED` | SystemVerilog random seed | Integer or `random` |
| `COV` | Enables compile and simulation coverage options | Exactly `ON` or `OFF` |
| `PROJECT_ROOT` | Absolute parent of `sim/` | Normally automatic |
| `PROTO_VERIF_ROOT` | Verification project root exported to `.f` files | Site or CI path override |
| `PROTO_VIP_ROOT` | Reusable VIP directory exported to `.f` files | External VIP path override |
| `QUESTA_HOME` | QuestaSim installation root | Override when auto-discovery is wrong |
| `UVM_HOME` | UVM source tree containing `src/uvm_macros.svh` | Override for a different installation |

`?=` assigns a default only when the variable has not already been set by the
environment or command line. `:=` evaluates immediately; it is appropriate for
discovered absolute paths and tool locations.

Examples:

```bash
make build
make run TESTNAME=proto_smoke_test SEED=1234
make run TESTNAME=proto_random_test SEED=random RUNARG=+NUM_ITEMS=100
make all TESTNAME=proto_smoke_test VERBOSITY=UVM_LOW
```

Quote `RUNARG` when it contains spaces:

```bash
make run TESTNAME=proto_random_test \
  RUNARG="+NUM_ITEMS=100 +TIMEOUT_US=5000"
```

### 9.5 What the compile command does

`make build` first performs library setup:

```text
mkdir -p log
vlib work
vmap work work
```

- `vlib work` creates the physical Questa library directory.
- `vmap work work` maps the logical library name `work` to it and may create or
  update `modelsim.ini`.

It then invokes `vlog`:

| Option | Purpose |
|---|---|
| `-f compile.f` | Reads the top-level ordered source list |
| `-timescale "1ns/1ps"` | Supplies a default time unit and precision to files that omit one |
| `-mfcu` | Treats the supplied sources as one multi-file compilation unit |
| `-suppress 2181` | Suppresses a specific Questa warning used by this project; review before carrying it to another project |
| `+acc=rb` | Preserves requested signal/object accessibility for debug |
| `-L .../uvm-1.2` | Makes the precompiled Questa UVM library available |
| `+incdir+.../uvm-1.2/src` | Makes UVM headers, especially `uvm_macros.svh`, discoverable |
| `+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR` | Enables the UVM constructor consistency check used by this project |

With `COV=ON`, the Makefile also adds:

```text
-coveropt 3 +cover=bcestf
```

This instruments block/branch, condition, expression, statement, toggle, and
FSM code coverage. Compile with coverage enabled before running with coverage;
simulation flags cannot recover coverage instrumentation omitted at compile
time.

The APB and AHB-Lite projects use `1ns/1ps`. Use the time scale appropriate for
the new DUT, and prefer explicit `timeunit`/`timeprecision` declarations in
important modules and interfaces.

### 9.6 What the simulation command does

`make run` invokes `vsim` with the already-compiled `work` library:

| Option | Purpose |
|---|---|
| `-sv_seed $(SEED)` | Makes randomized behavior reproducible |
| `-L .../uvm-1.2` | Resolves the precompiled UVM library during elaboration |
| `-dpicpppath <gcc>` | Selects the available compiler for DPI support when `gcc` is found |
| `-voptargs=+acc` | Keeps useful design visibility through elaboration optimization |
| `-assertdebug` | Retains assertion debug information |
| `-c $(TB_NAME)` | Runs the top module in command-line mode |
| `+UVM_TESTNAME=...` | Selects a factory-registered test class |
| `+UVM_VERBOSITY=...` | Sets the global `uvm_info` verbosity threshold |
| `$(RUNARG)` | Passes project-specific plusargs unchanged |
| `-l test_seed.log` | Writes the Questa transcript to a deterministic log name |

The `-do` script performs these actions in order:

```text
coverage save ...;   # Only when COV=ON
log -r /*;           # Record all hierarchy recursively in vsim.wlf
run -all;            # Run until objections drop or simulation terminates
quit -f;             # Exit command-line Questa without an interactive prompt
```

After simulation, the Makefile:

1. Moves the text log into `sim/log/`.
2. Copies the latest `vsim.wlf` to a test-and-seed-specific waveform file.
3. Updates `run.log` as a symlink to the latest archived log.
4. Uses `grep -q "TEST PASSED"` as the shell-level pass/fail gate.

Because `make run` does not depend on `build`, a regression can compile once
and run many tests quickly. The tradeoff is that a manual `make run` requires a
successful `make build` first.

### 9.7 Debugging waveforms

Open the most recent `sim/vsim.wlf`:

```bash
make wave
```

The template target opens an interactive Questa window and adds signals
directly below the top module. For an archived waveform, open it explicitly:

```bash
vsim -i -view log/proto_smoke_test_1234.wlf
```

Use the seed embedded in the filename to reproduce the failure:

```bash
make run TESTNAME=proto_smoke_test SEED=1234
```

### 9.8 Coverage

Build and run with coverage consistently:

```bash
make clean
make build COV=ON
make run COV=ON TESTNAME=proto_smoke_test SEED=1
make cov_gui COV=ON TESTNAME=proto_smoke_test SEED=1
```

`coverage save -codeAll -cvg -onexit` stores code coverage and covergroup data
in `proto_smoke_test_1.ucdb`. Merge multiple runs with:

```bash
make cov_merge
vsim -i -viewcov PROTO_MERGE.ucdb
```

Change the project-specific filename glob in `cov_merge`; the APB and AHB-Lite
Makefiles use protocol-specific `.ucdb` names.

### 9.9 Cleaning

`make clean` removes compiled libraries, logs, waveforms, coverage databases,
transcripts, and Questa-generated mapping files. Keep all hand-written source
and configuration outside the patterns removed by this target. In particular,
do not hand-maintain `sim/modelsim.ini` unless you also remove it from the
clean rule and `.gitignore`.

## 10. Regression flow

The current `regress.pl` is largely protocol-independent and can be reused. It:

1. Parses `regress.cfg`.
2. Runs one `make build`, with coverage derived from `cov = on/off`.
3. Generates a random six-digit seed for every requested run.
4. Calls `make run TESTNAME=... SEED=... RUNARG=...` for every entry.
5. Stops a run after the configured process timeout.
6. Scans logs for the fail keyword first, then the pass keyword.
7. Writes `regress.rpt` and returns nonzero if any test is failed or unknown.
8. Regenerates the report from archived logs when invoked with `-r`.

Minimal `regress.cfg`:

```text
cov = on
pass_key_word = "TEST PASSED"
fail_key_word = "TEST FAILED"
timeout_seconds = 120

tc_list {
  proto_smoke_test, run_times=1, run_opts= ;
  proto_random_test, run_times=5, run_opts=+NUM_ITEMS=100 ;
}
```

Each test line must contain exactly three comma-separated fields. Keep
`run_opts` free of commas because this simple parser expects that field to end
at the semicolon.

Run it from `sim/`:

```bash
./regress.pl
./regress.pl -f smoke.cfg
./regress.pl -r
```

- No option runs the configured regression and creates a report.
- `-f` selects another configuration file.
- `-r` regenerates the report from existing files in `sim/log/`.

Keep the pass/fail strings identical in the base test, Makefile, and regression
configuration. A missing marker is reported as `UNKNOWN`, which is correct for
a crashed, timed-out, or incompletely implemented test.

## 11. Root files and version control

### `.gitignore`

Use at least:

```gitignore
.DS_Store
.venv/

sim/work/
sim/log/
sim/modelsim.ini
sim/transcript
sim/run.log
sim/*.log
sim/*.trace
sim/*.wlf
sim/*.ucdb
sim/vsim.dbg
sim/tmp_report/
```

Commit source file lists, the Makefile, `project_env.bash`, `regress.cfg`, and
`regress.pl`. Do not commit compilation libraries, waveforms, logs, or coverage
databases unless a specific review process requires an artifact.

### `README.md`

Document only the project-specific facts a new user needs:

- What the DUT and VIP implement.
- Supported protocol modes and known limitations.
- Tool and license prerequisites.
- The shortest build and smoke-test commands.
- How to start a regression and merge coverage.
- Where the specification and verification plan live.

## 12. Recommended implementation order

Build vertically so every stage can be compiled before more complexity is
added:

1. Create the directory tree, `.gitignore`, and empty file lists.
2. Add the DUT and make `rtl.f` compile it.
3. Implement `proto_if.sv`.
4. Implement transaction and configuration classes.
5. Add sequencer, driver, monitor, and agent.
6. Create `proto_pkg.sv` and `proto_vip.f`; verify VIP compilation order.
7. Add one smoke sequence and `seq_pkg.sv`.
8. Add a minimal scoreboard, environment, and `env_pkg.sv`.
9. Add the base test, one smoke test, and `test_pkg.sv`.
10. Instantiate the interface and DUT in `testbench.sv` and publish the virtual
    interface.
11. Complete `rtl.f`, `tb.f`, and `compile.f`.
12. Configure `project_env.bash` and the Makefile.
13. Run one deterministic seed and inspect the log and waveform.
14. Add directed protocol checks and functional coverage from the VPlan.
15. Add regression entries only after each individual test passes.

Use this first checkpoint:

```bash
cd sim
make clean
make build
make run TESTNAME=proto_smoke_test SEED=1 VERBOSITY=UVM_HIGH
```

Then inspect:

```bash
readlink run.log
grep -E "UVM_(WARNING|ERROR|FATAL)|TEST (PASSED|FAILED)" run.log
make wave
```

## 13. Adding a new source file later

Use the smallest correct update:

- New VIP class: create it under `proto_vip/`, then include it in
  `proto_pkg.sv` at the correct dependency position.
- New sequence: create it under `sequences/`, then include it in `seq_pkg.sv`.
- New environment component: create it under `tb/`, then include it in
  `env_pkg.sv` before the environment if the environment instantiates it.
- New test: create it under `testcases/`, include it in `test_pkg.sv` after its
  base class, then add its class name to `regress.cfg`.
- New standalone interface/module/package: add it to the relevant `.f` file in
  dependency order instead of including it inside a class package.

If a class is visible only because of `-mfcu`, fix its package import or include
order rather than relying on accidental compilation-unit visibility.

## 14. Common failures

### `vlog: command not found`

QuestaSim is not on `PATH`, or the site setup script was not sourced. Run the
license/tool setup and verify `command -v vlog` and `command -v vsim`.

### Cannot find `uvm_macros.svh`

`UVM_HOME` does not point to a UVM tree containing `src/uvm_macros.svh`, or the
Makefile omitted `+incdir+$(UVM_HOME)/src`.

### Package or class is undefined

Check the complete order:

```text
interface -> VIP package -> environment/sequence packages -> test package -> top
```

Also check the class's position inside its package wrapper.

### `UVM_TESTNAME` test not found

The class name may differ from `TESTNAME`, the class may lack
`uvm_component_utils`, or its file may not be included in `test_pkg.sv`.

### Virtual interface is null or missing

Compare all four values: interface type, config-db field name, set path, and
get path. Set the interface in the top module before `run_test()`.

### Simulation never ends

A test may have raised an objection without dropping it, a driver may be stuck
waiting for a handshake, or the test may not have a timeout. Add a project-level
timeout and inspect objection traces before force-quitting a normal test.

### Make reports failure although simulation looked correct

Check for the exact `TEST PASSED` marker. The Makefile uses a case-sensitive
literal search. Ensure the marker uses `UVM_NONE` and is printed after all
scoreboard checks.

### Regression reports `Unknown`

The expected archived log may be absent, the simulator may have crashed, or
the log may contain neither configured keyword. Inspect the raw simulator exit
status and both `sim/` and `sim/log/`.

### Coverage database is empty or incomplete

Clean and rebuild with `COV=ON`, then also run with `COV=ON`. Confirm that the
test actually samples covergroups and that the `coverage save` command appears
in the expanded `vsim` command.

### Waveform has missing signals

Confirm `+acc` is present at compile/elaboration and that `log -r /*` ran before
`run -all`. More visibility increases simulation cost, so narrow the logged
hierarchy after debug is stable.

## 15. Final project checklist

- [ ] Every UVM class has one source file.
- [ ] Every layer has one package wrapper with dependency-ordered includes.
- [ ] The protocol interface is compiled outside the VIP package and before it.
- [ ] `rtl.f`, `tb.f`, and `compile.f` contain ordered sources, not generated
      files.
- [ ] Config objects reach every agent, driver, and monitor through
      `uvm_config_db`.
- [ ] ACTIVE agents contain a driver and sequencer; PASSIVE agents contain only
      the monitor.
- [ ] Monitor transactions are published through analysis ports.
- [ ] The scoreboard detects mismatch, missing, unexpected, and zero-traffic
      cases.
- [ ] Tests use objections and finish only after monitors have consumed the last
      transfer.
- [ ] UVM errors determine status, and exactly one final pass/fail marker is
      printed.
- [ ] Expected-error catchers whitelist stable IDs and verify the caught count.
- [ ] A deterministic smoke seed passes before random regression is enabled.
- [ ] Coverage is enabled at both compile and run time.
- [ ] Generated QuestaSim output is ignored by version control.

Following this structure makes each protocol VIP reusable, each project
environment understandable, and the QuestaSim command line reproducible from a
single `sim/` directory.
