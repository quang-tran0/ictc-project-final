`ifndef UART_CONFIGURATION__SV
`define UART_CONFIGURATION__SV

class uart_configuration extends uvm_object;
    `uvm_object_utils(uart_configuration)

    typedef enum bit [1:0] {
        UART_PARITY_NONE,
        UART_PARITY_EVEN,
        UART_PARITY_ODD
    } uart_parity_e;

    rand uart_parity_e parity;
    rand int unsigned data_width;
    rand int unsigned num_of_stop_bits;
    rand int unsigned baud_rate;

    uvm_active_passive_enum is_active;
    virtual uart_if vif;

    constraint c_data_width {
        if (parity == UART_PARITY_NONE) {
            data_width inside {[5:9]};
        } else {
            data_width inside {[5:8]};
        }
    }
    constraint c_num_of_stop_bits { num_of_stop_bits inside {[1:2]};}
    constraint c_baud_rate { baud_rate > 0;}

    `uvm_object_utils_begin(uart_configuration)
        `uvm_field_enum(uart_parity_e, parity, UVM_ALL_ON)
        `uvm_field_int(data_width, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(num_of_stop_bits, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(baud_rate, UVM_ALL_ON | UVM_DEC)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="uart_configuration");
        super.new(name);
    endfunction

    function bit is_valid();
        return (parity inside {
                UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD
            }) &&
            (data_width inside {[5:9]}) &&
            ((data_width != 9) || (parity == UART_PARITY_NONE)) &&
            (num_of_stop_bits inside {[1:2]}) &&
            (baud_rate > 0);
    endfunction
endclass

`endif