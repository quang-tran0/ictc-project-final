class uart_coverage extends uvm_component;
    `uvm_component_utils(uart_coverage)
    uvm_analysis_imp_ahb #(ahb_transaction,uart_coverage) ahb_imp;
    uvm_analysis_imp_uart #(uart_transaction,uart_coverage) uart_imp;
    covergroup bus_cg with function sample(int addr, bit write_enable, bit resp, int burst);
        option.per_instance=1;
        address: coverpoint addr {bins regs[]={[0:7]}; bins reserved={8};}
        direction: coverpoint write_enable;
        response: coverpoint resp;
        burst_type: coverpoint burst {bins single={0}; bins incr={1};}
        register_access: cross address,direction;
    endgroup
    covergroup frame_cg with function sample(int direction,int width,int parity,int stops,bit osm,int data,int divisor,bit bad_parity);
        option.per_instance=1;
        dir: coverpoint direction {bins tx={0}; bins rx={1};}
        bits: coverpoint width {bins widths[]={[5:8]};}
        par: coverpoint parity {bins modes[]={[0:2]};}
        stop: coverpoint stops {bins one={1}; bins two={2};}
        mode: coverpoint osm;
        payload: coverpoint data {bins values[]={[0:255]};}
        div_value: coverpoint divisor {
            bins min={1}; bins two={2}; bins low_boundary={255}; bins high_boundary={256};
            bins both_bytes={257}; bins max={65535}; bins ordinary=default;
        }
        parity_error: coverpoint bad_parity;
        formats: cross dir,bits,par,stop,mode;
    endgroup
    covergroup status_cg with function sample(bit [4:0] fsr);
        option.per_instance=1;
        tx_full: coverpoint fsr[0]; tx_empty: coverpoint fsr[1];
        rx_full: coverpoint fsr[2]; rx_empty: coverpoint fsr[3];
        parity_error: coverpoint fsr[4];
    endgroup
    covergroup irq_cg with function sample(bit [4:0] ier,bit irq);
        option.per_instance=1;
        enable_mask: coverpoint ier {bins masks[]={[0:31]};}
        level: coverpoint irq;
    endgroup
    function new(string name,uvm_component parent);
        super.new(name,parent);
        ahb_imp=new("ahb_imp",this); uart_imp=new("uart_imp",this);
        bus_cg=new; frame_cg=new; status_cg=new; irq_cg=new;
    endfunction
    function void write_ahb(ahb_transaction t);
        bus_cg.sample(t.addr<'h20 ? t.addr/4 : 8,t.kind==ahb_transaction::WRITE,t.resp,t.burst);
        if(t.addr=='h14 && t.kind==ahb_transaction::READ && !$isunknown(t.rdata)) status_cg.sample(t.rdata[4:0]);
    endfunction
    function void write_uart(uart_transaction t);
        frame_cg.sample(t.direction,t.data_width,t.parity_mode,t.stop_bits,t.osm_sel,t.data,t.divisor,t.parity_error);
    endfunction
    function void report_phase(uvm_phase phase);
        `uvm_info("COVERAGE",$sformatf("bus=%0.2f frame=%0.2f status=%0.2f irq=%0.2f",bus_cg.get_inst_coverage(),frame_cg.get_inst_coverage(),status_cg.get_inst_coverage(),irq_cg.get_inst_coverage()),UVM_NONE)
    endfunction
endclass
