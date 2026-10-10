class uart_register_access_test extends uart_base_test;
    `uvm_component_utils(uart_register_access_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        bit [31:0] value;
        for (int index=0; index<5; index++) begin
            for (int b=0; b<32; b++) begin
                value=1<<b;
                // Give BGE a legal divisor before exercising it.
                if (index==3) begin write_reg(4,4); write_reg(8,0); end
                write_reg(index*4,value); check_reg(index*4,value & env.scoreboard.mask(index));
                write_reg(index*4,0); check_reg(index*4,0);
            end
        end
        repeat (100) begin
            int index;
            index=$urandom_range(0,4); value=$urandom;
            if(index==3) value &= 'h1f;
            write_reg(index*4,value); check_reg(index*4,value & env.scoreboard.mask(index));
        end
        write_reg('h14,'hffffffff); check_reg('h14,'ha);
        write_reg('h1c,'h55); check_reg('h14,'ha);
        check_reg('h18,0);
    endtask
endclass
