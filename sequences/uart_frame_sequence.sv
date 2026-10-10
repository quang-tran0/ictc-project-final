class uart_frame_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_frame_sequence)
    bit [7:0] data;
    bit bad_parity;
    function new(string name="uart_frame_sequence"); super.new(name); endfunction
    task body();
        uart_transaction item = uart_transaction::type_id::create("item");
        start_item(item);
        item.data = data; item.inject_parity_error = bad_parity;
        finish_item(item);
    endtask
endclass
