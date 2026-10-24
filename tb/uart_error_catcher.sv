// Only for deliberate checker self-tests. Register on the exact reporting
// component, during the injection window, and always call check_count().
// Ordinary DUT tests must leave UART_FRAME/UART_TIMING errors untouched.
class uart_error_catcher extends uvm_report_catcher;
    string expected_id;
    int unsigned expected_count, caught_count;
    uvm_report_object expected_reporter;

    function new(string name = "uart_error_catcher");
        super.new(name);
    endfunction

    virtual function action_e catch();
        if (get_severity() == UVM_ERROR && get_client() == expected_reporter &&
            get_id() == expected_id && caught_count < expected_count) begin
            caught_count++;
            set_severity(UVM_INFO);
            set_verbosity(UVM_NONE);
        end
        // Keep the original message visible. Unexpected and excess errors
        // retain their severity and make the enclosing test fail.
        return THROW;
    endfunction

    function void check_count();
        if (caught_count != expected_count)
            `uvm_error("UART_CATCH_COUNT", $sformatf("%s: expected %0d errors, observed %0d",
            expected_id, expected_count, caught_count))
    endfunction
endclass
