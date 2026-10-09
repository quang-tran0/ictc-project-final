interface ahb_if;
    logic HCLK;
    logic HRESETn;

    logic [9:0] HADDR;
    logic [2:0] HBURST;
    
    logic HMASTLOCK;
    logic [3:0] HPROT;
    
    logic [2:0] HSIZE;
    logic [1:0] HTRANS;
    logic HSEL;

    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic HWRITE;
    
    logic HREADYOUT;
    logic HRESP;
endinterface