class uart_environment extends uvm_env;
    `uvm_component_utils(uart_environment)

    ahb_agent ahb;
    uart_agent uart;
    uart_irq_monitor irq;
    uart_scoreboard scoreboard;
    uart_reg_block regmodel;
    uart_reg_adapter adapter;
    uvm_reg_predictor #(ahb_transaction) predictor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ahb = ahb_agent::type_id::create("ahb", this);
        uart = uart_agent::type_id::create("uart", this);
        irq = uart_irq_monitor::type_id::create("irq", this);
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);

        regmodel = uart_reg_block::type_id::create("regmodel");
        regmodel.build();
        regmodel.reset();

        adapter = uart_reg_adapter::type_id::create("adapter");
        predictor = uvm_reg_predictor#(ahb_transaction)::type_id::create("predictor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        ahb.monitor_ap.connect(scoreboard.ahb_imp);
        ahb.monitor_ap.connect(predictor.bus_in);
        uart.driver_ap.connect(scoreboard.stimulus_imp);
        uart.monitor_ap.connect(scoreboard.uart_imp);

        regmodel.default_map.set_sequencer(ahb.sequencer, adapter);
        regmodel.default_map.set_auto_predict(0);
        regmodel.default_map.set_check_on_read(0);

        predictor.map = regmodel.default_map;
        predictor.adapter = adapter;
    endfunction

    task run_phase(uvm_phase phase);
        // UART keeps its original two-pin interface; reset follows the bus.
        forever begin
            uart.cfg.reset_n = ahb.cfg.vif.HRESETn;
            @(ahb.cfg.vif.HRESETn);
        end
    endtask
endclass
