class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) analysis_port;

    covergroup uart_cg with function sample(
        int unsigned data_width,
        uart_parity_e parity_mode,
        int unsigned num_of_stop_bit,
        int unsigned baud_rate,
        uart_direction_e direction,
        bit [7:0] data,
        bit parity_error,
        bit stop_error
    );
        option.per_instance = 1;
        cp_data_width: coverpoint data_width {
            bins width_5 = {5}; bins width_6 = {6};
            bins width_7 = {7}; bins width_8 = {8};
        }
        cp_parity: coverpoint parity_mode;
        cp_stop_bits: coverpoint num_of_stop_bit { bins one = {1}; bins two = {2};}
        cp_baud: coverpoint baud_rate {
            bins b9600 = {9600}; bins b19200 = {19200};
            bins b57600 = {57600}; bins b115200 = {115200};
            bins other = default;
        }
        cp_direction: coverpoint direction;
        cp_data: coverpoint data {
            bins zero = {8'h00}; bins ones = {8'hff};
            bins alternating_55 = {8'h55}; bins alternating_aa = {8'haa};
            bins other = default;
        }
        cp_parity_error: coverpoint parity_error;
        cp_stop_error: coverpoint stop_error;
        frame_format: cross cp_data_width, cp_parity, cp_stop_bits;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        uart_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_CFG", $sformatf("No configuration for %s", get_full_name()))
        vif = cfg.vif;
        if (vif == null)
            `uvm_fatal("UART_VIF", $sformatf("No virtual interface for %s", get_full_name()))
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_line(UART_TX);
            monitor_line(UART_RX);
        join
    endtask

    function logic line_value(uart_direction_e direction);
        return direction == UART_TX ? vif.tx : vif.rx;
    endfunction

    task wait_for_start(uart_direction_e direction);
        if (direction == UART_TX) @(negedge vif.tx);
        else @(negedge vif.rx);
    endtask

    task monitor_line(uart_direction_e direction);
        uart_transaction item;
        bit parity_bit;
        realtime period;

        forever begin
        wait_for_start(direction);
        period = cfg.bit_period();
        #(period / 2.0);
        if (line_value(direction) !== 1'b0)
            continue;

        item = uart_transaction::type_id::create("item");
        item.direction = direction;
        item.data = '0;

        for (int unsigned bit_index = 0; bit_index < cfg.data_width; bit_index++) begin
            #(period);
            item.data[bit_index] = line_value(direction);
        end

        item.inject_parity_error = 1'b0;
        if (cfg.parity_mode != UART_PARITY_NONE) begin
            #(period);
            parity_bit = ^item.data;
            if (cfg.parity_mode == UART_PARITY_ODD)
            parity_bit = ~parity_bit;
            item.inject_parity_error = line_value(direction) !== parity_bit;
        end

        item.inject_stop_error = 1'b0;
        for (int unsigned stop_index = 0;
            stop_index < cfg.num_of_stop_bit;
            stop_index++) begin

            #(period);
            if (line_value(direction) !== 1'b1) item.inject_stop_error = 1'b1;
        end

        if (item.inject_parity_error)
            `uvm_warning("UART_PARITY", $sformatf("Parity error observed on %s", direction.name()))
        if (item.inject_stop_error)
            `uvm_warning("UART_STOP", $sformatf("Stop-bit error observed on %s", direction.name()))

        uart_cg.sample(
            cfg.data_width, 
            cfg.parity_mode, 
            cfg.num_of_stop_bit,
            cfg.baud_rate, direction, 
            item.data,
            item.inject_parity_error, 
            item.inject_stop_error
        );
        analysis_port.write(item);
        end
    endtask
endclass
