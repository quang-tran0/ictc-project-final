// Used only by VIP self-tests on an isolated synthetic interface.
// DUT compliance tests never install this catcher.
class uart_expected_error_catcher extends uvm_report_catcher;
    int tx_caught, rx_caught;
    bit catch_incomplete_errors;
    bit catch_format_errors;
    int tx_parity, rx_parity, tx_stop, rx_stop;
    function new(string name="uart_expected_error_catcher"); super.new(name); endfunction
    function action_e catch();
        if(get_severity()==UVM_ERROR) begin
            if(catch_incomplete_errors && get_id()=="UART_TX_INCOMPLETE") begin tx_caught++; set_severity(UVM_INFO); end
            if(catch_incomplete_errors && get_id()=="UART_RX_INCOMPLETE") begin rx_caught++; set_severity(UVM_INFO); end
            if(catch_format_errors) begin
                case(get_id())
                    "TX_PARITY": begin tx_parity++; set_severity(UVM_INFO); end
                    "RX_PARITY": begin rx_parity++; set_severity(UVM_INFO); end
                    "TX_STOP": begin tx_stop++; set_severity(UVM_INFO); end
                    "RX_STOP": begin rx_stop++; set_severity(UVM_INFO); end
                endcase
            end
        end
        return THROW;
    endfunction
endclass
