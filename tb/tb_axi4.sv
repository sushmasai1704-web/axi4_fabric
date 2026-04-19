`timescale 1ns/1ps
module tb_axi4;
    parameter DW = 32, AW = 32, IW = 4;

    logic clk, rst_n;
    // AXI signals
    logic [IW-1:0]  awid, bid, arid, rid;
    logic [AW-1:0]  awaddr, araddr;
    logic [7:0]     awlen, arlen;
    logic           awvalid, awready, wvalid, wready;
    logic [DW-1:0]  wdata, rdata;
    logic           wlast, rlast, bvalid, bready;
    logic [1:0]     bresp, rresp;
    logic           arvalid, arready, rvalid, rready;
    // User signals
    logic           start_write, start_read, done;
    logic [AW-1:0]  addr_in;
    logic [DW-1:0]  data_in, data_out;

    // Clock
    always #5 clk = ~clk;

    // DUT instantiation
    axi4_master #(DW,AW,IW) u_master (
        .clk(clk), .rst_n(rst_n),
        .awid(awid), .awaddr(awaddr), .awlen(awlen),
        .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wlast(wlast),
        .wvalid(wvalid), .wready(wready),
        .bid(bid), .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .arid(arid), .araddr(araddr), .arlen(arlen),
        .arvalid(arvalid), .arready(arready),
        .rid(rid), .rdata(rdata), .rlast(rlast),
        .rresp(rresp), .rvalid(rvalid), .rready(rready),
        .start_write(start_write), .start_read(start_read),
        .addr_in(addr_in), .data_in(data_in),
        .data_out(data_out), .done(done)
    );

    axi4_slave #(DW,AW,IW) u_slave (
        .clk(clk), .rst_n(rst_n),
        .awid(awid), .awaddr(awaddr), .awlen(awlen),
        .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wlast(wlast),
        .wvalid(wvalid), .wready(wready),
        .bid(bid), .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .arid(arid), .araddr(araddr), .arlen(arlen),
        .arvalid(arvalid), .arready(arready),
        .rid(rid), .rdata(rdata), .rlast(rlast),
        .rresp(rresp), .rvalid(rvalid), .rready(rready)
    );

    // VCD dump
    initial begin
        $dumpfile("sim/axi4.vcd");
        $dumpvars(0, tb_axi4);
    end

    // Test sequence
    task write_txn(input [AW-1:0] addr, input [DW-1:0] data);
        @(posedge clk);
        addr_in = addr; data_in = data;
        start_write = 1;
        @(posedge clk); start_write = 0;
        wait(done); @(posedge clk);
        $display("[WRITE] addr=0x%08h data=0x%08h -- OK", addr, data);
    endtask

    task read_txn(input [AW-1:0] addr);
        @(posedge clk);
        addr_in = addr;
        start_read = 1;
        @(posedge clk); start_read = 0;
        wait(done); @(posedge clk);
        $display("[READ]  addr=0x%08h data=0x%08h -- OK", addr, data_out);
    endtask

    initial begin
        clk=0; rst_n=0; start_write=0; start_read=0;
        addr_in=0; data_in=0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // Test 1: Write then read back
        write_txn(32'h00000010, 32'hDEADBEEF);
        read_txn (32'h00000010);

        // Test 2: Multiple addresses
        write_txn(32'h00000020, 32'hCAFEBABE);
        write_txn(32'h00000030, 32'h12345678);
        read_txn (32'h00000020);
        read_txn (32'h00000030);

        // Check readback correctness
        read_txn(32'h00000010);
        if (data_out === 32'hDEADBEEF)
            $display("PASS: Readback matches written data");
        else
            $display("FAIL: Expected 0xDEADBEEF got 0x%08h", data_out);

        repeat(5) @(posedge clk);
        $display("\nAll AXI4 transactions complete!");
        $finish;
    end
endmodule
