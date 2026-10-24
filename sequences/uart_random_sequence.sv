class uart_random_sequence extends uvm_sequence;
    `uvm_object_utils(uart_random_sequence)

    uart_configuration cfg;
    uart_sequencer serial_sequencer;
    ahb_sequencer bus_sequencer;
    bit receive = 1;
    int unsigned width = 8;

    rand int unsigned frame_count;
    rand bit [7:0] payloads[];
    rand int unsigned gap_bits[];
    rand int unsigned start_delay_ps;

    constraint legal_traffic_c {
        width inside {[5:8]};
        frame_count inside {[2:8]};
        payloads.size() == frame_count;
        gap_bits.size() == frame_count;
        start_delay_ps inside {[0:9999]};
        foreach (payloads[i]) {
            payloads[i] < (1 << width);
            gap_bits[i] inside {[0:2]};
        }
    }

    constraint parity_values_c {
        (^payloads[0]) == 0;
        (^payloads[1]) == 1;
    }

    function new(string name = "uart_random_sequence");
        super.new(name);
    endfunction

    task body();
        uart_rx_sequence rx;
        uart_tx_sequence tx;

        if (cfg == null || width != cfg.data_width ||
            !(frame_count inside {[2:8]}) ||
            payloads.size() != frame_count || gap_bits.size() != frame_count ||
            (receive && serial_sequencer == null) ||
            (!receive && bus_sequencer == null))
            `uvm_fatal("RAND_CFG", "Random traffic must be configured and randomized before start")

        `uvm_info("RAND_TRAFFIC",
            $sformatf("RX=%b width=%0d count=%0d delay_ps=%0d payloads=%p gaps=%p",
                      receive, width, frame_count, start_delay_ps, payloads, gap_bits), UVM_LOW)

        #(start_delay_ps * 1ps);
        foreach (payloads[i]) begin
            if (receive) begin
                rx = uart_rx_sequence::type_id::create("random_rx_frame");
                rx.cfg = cfg;
                rx.bytes_to_send.push_back(payloads[i]);
                rx.start(serial_sequencer, this);
            end else begin
                tx = uart_tx_sequence::type_id::create("random_tx_frame");
                tx.bus_sequencer = bus_sequencer;
                tx.bytes_to_send.push_back(payloads[i]);
                tx.start(null, this);
            end
            #(gap_bits[i] * cfg.bit_period());
        end
    endtask
endclass
