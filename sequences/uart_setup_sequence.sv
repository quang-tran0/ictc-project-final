class uart_setup_sequence extends uvm_sequence;
    `uvm_object_utils(uart_setup_sequence)
    uart_environment env;
    uart_configuration cfg;
    int width = 8, stops = 1, osm = 16, divisor = 54;
    uart_parity_e parity = UART_PARITY_NONE;
    bit baud_enable = 1;

    function new(string name = "uart_setup_sequence");
        super.new(name);
    endfunction

    task write_reg(uvm_reg r, bit [31:0] data);
        uvm_status_e status;
        r.write(status, data, UVM_FRONTDOOR, env.regmodel.default_map, this);
        if (status != UVM_IS_OK)
            `uvm_error("UART_SETUP", $sformatf("Configuration write failed:%s", r.get_name()))
    endtask

    task body();
        bit [31:0] control;
        if (!(width inside {[5:8]}) || !(stops inside {[1:2]}) ||
            !(osm inside {13, 16}) || !(divisor inside {[1:65535]}))
            `uvm_fatal("UART_SETUP", "Illegal UART configuration")
        cfg.monitor_enable = 0;
        cfg.data_width = width;
        cfg.num_of_stop_bit = stops;
        cfg.parity_mode = parity;
        cfg.oversampling = osm;
        cfg.programmed_period = real'(divisor) * osm * 10ns;
        cfg.baud_rate = int'(1s / cfg.programmed_period);
        control = (width - 5)
                | ((stops - 1) << 2)
                | ((parity != UART_PARITY_NONE) << 3)
                | ((parity == UART_PARITY_EVEN) << 4)
                | (int'(baud_enable) << 5);

        write_reg(env.regmodel.MDR, osm == 13);
        write_reg(env.regmodel.DLL, divisor & 'hff);
        write_reg(env.regmodel.DLH, (divisor >> 8) & 'hff);
        write_reg(env.regmodel.LCR, control & ~32'h20);
        write_reg(env.regmodel.LCR, control);
        cfg.monitor_enable = 1;
    endtask
endclass
