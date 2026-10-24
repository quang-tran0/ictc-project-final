class uart_tx_sequence extends uvm_sequence;
    `uvm_object_utils(uart_tx_sequence)
    ahb_sequencer bus_sequencer;
    byte unsigned bytes_to_send[$];

    function new(string name = "uart_tx_sequence");
        super.new(name);
    endfunction

    task body();
        uart_ahb_sequence bus;
        bus = uart_ahb_sequence::type_id::create("tx_writes");
        foreach (bytes_to_send[i]) bus.add(1, 'h018, bytes_to_send[i]);
        bus.start(bus_sequencer, this);
    endtask
endclass
