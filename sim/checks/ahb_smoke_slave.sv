// Test-only handshake model. This is never part of rtl.f or the project DUT.
module ahb_smoke_slave(ahb_if bus);
    timeunit 1ns;
    timeprecision 1ps;
    logic pending;
    logic [9:0] address;
    logic write_access;
    int waits;
    logic [31:0] memory[8];
    logic [31:0] held_write_data;
    bit stalled;
    logic [24:0] held_control;
    logic previous_error;
    int completed_count, wait_count, consecutive_count;
    bit previous_completion;

    assign bus.HREADYOUT = !pending || waits == 0;
    // Two-cycle ERROR: first HRESP=1/HREADYOUT=0, then HRESP=1/HREADYOUT=1.
    assign bus.HRESP = pending && address >= 'h20 && waits <= 1;
    assign bus.HRDATA = address >= 'h20 ? 32'hffff_ffff : memory[address[4:2]];

    always @(posedge bus.HCLK or negedge bus.HRESETn) begin
        if (!bus.HRESETn) begin
            pending <= 0;
            address <= 0;
            write_access <= 0;
            waits <= 0;
            stalled <= 0;
            completed_count <= 0;
            wait_count <= 0;
            consecutive_count <= 0;
            previous_completion <= 0;
            foreach (memory[i]) memory[i] <= 0;
        end else begin
            if (pending && stalled) begin
                if (write_access && bus.HWDATA !== held_write_data)
                    $fatal(1, "HWDATA changed before stalled transfer completed");
                if (!previous_error && held_control !==
                    {bus.HSEL, bus.HTRANS, bus.HADDR, bus.HWRITE, bus.HSIZE,
                     bus.HBURST, bus.HPROT, bus.HMASTLOCK})
                    $fatal(1, "Address/control changed during wait state");
            end
            if (pending && !bus.HREADYOUT) begin
                waits <= waits - 1;
                wait_count <= wait_count + 1;
                held_write_data <= bus.HWDATA;
                held_control <= {bus.HSEL, bus.HTRANS, bus.HADDR, bus.HWRITE, bus.HSIZE,
                                 bus.HBURST, bus.HPROT, bus.HMASTLOCK};
                previous_error <= bus.HRESP;
                stalled <= 1;
            end else begin
                stalled <= 0;
                if (pending) begin
                    completed_count <= completed_count + 1;
                    if (previous_completion) consecutive_count <= consecutive_count + 1;
                    if (write_access && address < 'h20)
                        memory[address[4:2]] <= bus.HWDATA;
                end
                previous_completion <= pending;
                pending <= bus.HSEL && bus.HTRANS[1];
                if (bus.HSEL && bus.HTRANS[1]) begin
                    address <= bus.HADDR;
                    write_access <= bus.HWRITE;
                    if (bus.HSIZE != 3'b010 || bus.HADDR[1:0] != 0 ||
                        !(bus.HBURST inside {3'b000, 3'b001}))
                        $fatal(1, "Illegal smoke bus request");
                    waits <= bus.HADDR >= 'h20 ? 2 : bus.HADDR == 'h8 ? 3 : 0;
                end
            end
        end
    end
endmodule
