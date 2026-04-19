module axi4_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  wire                    clk, rst_n,
    input  wire [ID_WIDTH-1:0]     awid,
    input  wire [ADDR_WIDTH-1:0]   awaddr,
    input  wire [7:0]              awlen,
    input  wire                    awvalid,
    output reg                     awready,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    wlast,
    input  wire                    wvalid,
    output reg                     wready,
    output reg  [ID_WIDTH-1:0]     bid,
    output reg  [1:0]              bresp,
    output reg                     bvalid,
    input  wire                    bready,
    input  wire [ID_WIDTH-1:0]     arid,
    input  wire [ADDR_WIDTH-1:0]   araddr,
    input  wire [7:0]              arlen,
    input  wire                    arvalid,
    output reg                     arready,
    output reg  [ID_WIDTH-1:0]     rid,
    output reg  [DATA_WIDTH-1:0]   rdata,
    output reg                     rlast,
    output reg  [1:0]              rresp,
    output reg                     rvalid,
    input  wire                    rready
);
    reg [DATA_WIDTH-1:0] mem [0:255];
    reg [7:0]            burst_cnt;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [ID_WIDTH-1:0]   rd_id;
    reg [7:0]            rd_len;
    reg [ADDR_WIDTH-1:0] wr_addr_lat;
    reg [ID_WIDTH-1:0]   wr_id_lat;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready <= 1; wready <= 1;
            bvalid  <= 0; bid    <= 0; bresp <= 0;
            wr_addr_lat <= 0; wr_id_lat <= 0;
        end else begin
            if (awvalid && awready) begin
                wr_addr_lat <= awaddr;
                wr_id_lat   <= awid;
                awready     <= 0;
            end
            if (wvalid && wready) begin
                mem[wr_addr_lat[7:0]] <= wdata;
                if (wlast) begin
                    wready <= 0;
                    bvalid <= 1;
                    bid    <= wr_id_lat;
                    bresp  <= 2'b00;
                end
            end
            if (bvalid && bready) begin
                bvalid  <= 0;
                awready <= 1;
                wready  <= 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready   <= 1; rvalid <= 0;
            rid <= 0; rdata <= 0; rlast <= 0; rresp <= 0;
            burst_cnt <= 0; rd_addr <= 0; rd_id <= 0; rd_len <= 0;
        end else begin
            if (arvalid && arready) begin
                arready   <= 0;
                rd_addr   <= araddr;
                rd_id     <= arid;
                rd_len    <= arlen;
                burst_cnt <= 0;
                rvalid    <= 1;
                rdata     <= mem[araddr[7:0]];
                rid       <= arid;
                rresp     <= 2'b00;
                rlast     <= (arlen == 0);
            end
            if (rvalid && rready) begin
                burst_cnt <= burst_cnt + 1;
                if (burst_cnt == rd_len) begin
                    rvalid  <= 0;
                    rlast   <= 0;
                    arready <= 1;
                end else begin
                    rdata <= mem[rd_addr[7:0] + burst_cnt + 1];
                    rlast <= (burst_cnt + 1 == rd_len);
                end
            end
        end
    end
endmodule
