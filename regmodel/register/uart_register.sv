class uart_register extends uvm_reg;
    `uvm_object_utils(uart_register)
    uvm_reg_field fields[$];
    function new(string name="uart_register"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    function void make_field(string name, int width, int lsb, string access_kind,
                            bit [31:0] reset_value=0, bit volatile_field=0, bit has_reset=1);
        uvm_reg_field f = uvm_reg_field::type_id::create(name);
        f.configure(this,width,lsb,access_kind,volatile_field,reset_value,has_reset,0,0);
        fields.push_back(f);
    endfunction
    function void build(int offset);
        case(offset)
            'h00: make_field("OSM_SEL",1,0,"RW");
            'h04: make_field("DLL",8,0,"RW");
            'h08: make_field("DLH",8,0,"RW");
            'h0c: begin
                make_field("WLS",2,0,"RW",3); make_field("STB",1,2,"RW");
                make_field("PEN",1,3,"RW"); make_field("EPS",1,4,"RW"); make_field("BGE",1,5,"RW");
            end
            'h10: begin
                make_field("EN_TX_FULL",1,0,"RW"); make_field("EN_TX_EMPTY",1,1,"RW");
                make_field("EN_RX_FULL",1,2,"RW"); make_field("EN_RX_EMPTY",1,3,"RW");
                make_field("EN_PARITY_ERROR",1,4,"RW");
            end
            'h14: begin
                make_field("TX_FULL",1,0,"RO",0,1); make_field("TX_EMPTY",1,1,"RO",1,1);
                make_field("RX_FULL",1,2,"RO",0,1); make_field("RX_EMPTY",1,3,"RO",1,1);
                make_field("PARITY_ERROR",1,4,"W1C",0,1);
            end
            'h18: make_field("TX_DATA",8,0,"WO",0,1);
            'h1c: make_field("RX_DATA",8,0,"RO",0,1,0);
        endcase
    endfunction
endclass
