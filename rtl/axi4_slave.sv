module axi4_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  logic                    clk, rst_n,
    // Write address
    input  logic [ID_WIDTH-1:0]     awid,
    input  logic [ADDR_WIDTH-1:0]   awaddr,
    input  logic [7:0]              awlen,
    input  logic                    awvalid,
    output logic                    awready,
    // Write data
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic                    wlast,
    input  logic                    wvalid,
    output logic                    wready,
    // Write response
    output logic [ID_WIDTH-1:0]     bid,
    output logic [1:0]              bresp,
    output logic                    bvalid,
    input  logic                    bready,
    // Read address
    input  logic [ID_WIDTH-1:0]     arid,
    input  logic [ADDR_WIDTH-1:0]   araddr,
    input  logic [7:0]              arlen,
    input  logic                    arvalid,
    output logic                    arready,
    // Read data
    output logic [ID_WIDTH-1:0]     rid,
    output logic [DATA_WIDTH-1:0]   rdata,
    output logic                    rlast,
    output logic [1:0]              rresp,
    output logic                    rvalid,
    input  logic                    rready
);
    // Simple memory 256 words
    logic [DATA_WIDTH-1:0] mem [0:255];
    logic [7:0]  burst_cnt;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [ID_WIDTH-1:0]   rd_id;
    logic [7:0]  rd_len;

    // Write channel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready <= 1; wready <= 1;
            bvalid  <= 0; bid    <= 0; bresp <= 0;
        end else begin
            if (awvalid && awready) awready <= 0;
            if (wvalid  && wready) begin
                mem[awaddr[7:0]] <= wdata;
                if (wlast) begin
                    wready  <= 0;
                    bvalid  <= 1;
                    bid     <= awid;
                    awready <= 1;
                    wready  <= 1;
                end
            end
            if (bvalid && bready) bvalid <= 0;
        end
    end

    // Read channel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready <= 1; rvalid <= 0;
            rid <= 0; rdata <= 0; rlast <= 0; rresp <= 0;
            burst_cnt <= 0;
        end else begin
            if (arvalid && arready) begin
                arready   <= 0;
                rd_addr   <= araddr;
                rd_id     <= arid;
                rd_len    <= arlen;
                burst_cnt <= 0;
                rvalid    <= 1;
            end
            if (rvalid && rready) begin
                rdata     <= mem[rd_addr[7:0] + burst_cnt];
                rid       <= rd_id;
                rresp     <= 0;
                burst_cnt <= burst_cnt + 1;
                rlast     <= (burst_cnt == rd_len);
                if (burst_cnt == rd_len) begin
                    rvalid  <= 0;
                    rlast   <= 0;
                    arready <= 1;
                end
            end
        end
    end
endmodule
