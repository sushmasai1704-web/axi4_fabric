`timescale 1ns/1ns
module tb_axi4;
    parameter DW = 32, AW = 32, IW = 4;

    reg  clk, rst_n;
    wire [IW-1:0]  awid, bid, arid, rid;
    wire [AW-1:0]  awaddr, araddr;
    wire [7:0]     awlen, arlen;
    wire           awvalid, awready, wvalid, wready;
    wire [DW-1:0]  wdata, rdata;
    wire           wlast, rlast, bvalid, bready;
    wire [1:0]     bresp, rresp;
    wire           arvalid, arready, rvalid, rready;
    reg            start_write, start_read;
    reg  [AW-1:0]  addr_in;
    reg  [DW-1:0]  data_in;
    wire [DW-1:0]  data_out;
    wire           done;

    always #5 clk = ~clk;

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

    initial begin
        $dumpfile("sim/axi4.vcd");
        $dumpvars(0, tb_axi4);
    end

    task write_txn;
        input [AW-1:0] addr;
        input [DW-1:0] data;
        begin
            @(posedge clk);
            addr_in = addr; data_in = data;
            start_write = 1;
            @(posedge clk); start_write = 0;
            wait(done); @(posedge clk);
            $display("[WRITE] addr=0x%08h data=0x%08h  OK", addr, data);
        end
    endtask

    task read_txn;
        input [AW-1:0] addr;
        begin
            @(posedge clk);
            addr_in = addr;
            start_read = 1;
            @(posedge clk); start_read = 0;
            wait(done); @(posedge clk);
            $display("[READ]  addr=0x%08h data=0x%08h", addr, data_out);
        end
    endtask

    initial begin
        clk=0; rst_n=0; start_write=0; start_read=0;
        addr_in=0; data_in=0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        write_txn(32'h00000010, 32'hDEADBEEF);
        read_txn (32'h00000010);
        write_txn(32'h00000020, 32'hCAFEBABE);
        write_txn(32'h00000030, 32'h12345678);
        read_txn (32'h00000020);
        read_txn (32'h00000030);
        read_txn (32'h00000010);

        if (data_out === 32'hDEADBEEF)
            $display("*** PASS: Readback correct! ***");
        else
            $display("*** FAIL: Expected DEADBEEF got %08h ***", data_out);

        repeat(5) @(posedge clk);
        $display("All AXI4 transactions complete!");
        $finish;
    end
endmodule
