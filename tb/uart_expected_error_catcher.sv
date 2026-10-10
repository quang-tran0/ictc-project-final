// Used only by the monitor self-test on an isolated synthetic interface.
// DUT compliance tests never install this catcher.
class uart_expected_error_catcher extends uvm_report_catcher;
    int tx_caught, rx_caught;
    function new(string name="uart_expected_error_catcher"); super.new(name); endfunction
    function action_e catch();
        if(get_severity()==UVM_ERROR) begin
            if(get_id()=="UART_TX_INCOMPLETE") begin tx_caught++; set_severity(UVM_INFO); end
            if(get_id()=="UART_RX_INCOMPLETE") begin rx_caught++; set_severity(UVM_INFO); end
        end
        return THROW;
    endfunction
endclass
