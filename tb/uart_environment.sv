class uart_environment extends uvm_env;
    `uvm_component_utils(uart_environment)
    ahb_agent ahb;
    uart_agent uart;
    uart_scoreboard scoreboard;
    uart_coverage coverage;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb = ahb_agent::type_id::create("ahb", this);
        uart = uart_agent::type_id::create("uart", this);
        coverage = uart_coverage::type_id::create("coverage", this);
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ahb.monitor.analysis_port.connect(coverage.ahb_imp);
        uart.monitor.analysis_port.connect(coverage.uart_imp);
        ahb.monitor.analysis_port.connect(scoreboard.ahb_imp);
        uart.monitor.analysis_port.connect(scoreboard.uart_imp);
    endfunction
endclass
