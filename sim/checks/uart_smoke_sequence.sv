class uart_smoke_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_smoke_sequence)
    uart_transaction items[$];

    function new(string name = "uart_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        foreach (items[i]) begin
            start_item(items[i]);
            finish_item(items[i]);
        end
    endtask
endclass
