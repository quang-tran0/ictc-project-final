`ifndef UART_RAL_EXPECTED_ERROR__SV
`define UART_RAL_EXPECTED_ERROR__SV

// Used only around explicit negative adapter/comparison checks.
class uart_ral_expected_error extends uvm_report_catcher;
    `uvm_object_utils(uart_ral_expected_error)

    string expected_id;
    int unsigned count;

    function new(string name = "uart_ral_expected_error");
        super.new(name);
    endfunction

    virtual function action_e catch();
        if (get_severity() == UVM_ERROR && get_id() == expected_id) begin
            count++;
            return CAUGHT;
        end
        return THROW;
    endfunction
endclass

`endif
