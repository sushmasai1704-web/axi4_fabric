module axi4_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  wire                    clk, rst_n,
    output reg  [ID_WIDTH-1:0]     awid,
    output reg  [ADDR_WIDTH-1:0]   awaddr,
    output reg  [7:0]              awlen,
    output reg                     awvalid,
    input  wire                    awready,
    output reg  [DATA_WIDTH-1:0]   wdata,
    output reg                     wlast,
    output reg                     wvalid,
    input  wire                    wready,
    input  wire [ID_WIDTH-1:0]     bid,
    input  wire [1:0]              bresp,
    input  wire                    bvalid,
    output reg                     bready,
    output reg  [ID_WIDTH-1:0]     arid,
    output reg  [ADDR_WIDTH-1:0]   araddr,
    output reg  [7:0]              arlen,
    output reg                     arvalid,
    input  wire                    arready,
    input  wire [ID_WIDTH-1:0]     rid,
    input  wire [DATA_WIDTH-1:0]   rdata,
    input  wire                    rlast,
    input  wire [1:0]              rresp,
    input  wire                    rvalid,
    output reg                     rready,
    input  wire                    start_write,
    input  wire                    start_read,
    input  wire [ADDR_WIDTH-1:0]   addr_in,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg  [DATA_WIDTH-1:0]   data_out,
    output reg                     done
);
    localparam IDLE    = 3'd0;
    localparam WR_ADDR = 3'd1;
    localparam WR_DATA = 3'd2;
    localparam WR_RESP = 3'd3;
    localparam RD_ADDR = 3'd4;
    localparam RD_DATA = 3'd5;

    reg [2:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            awvalid <= 0; wvalid  <= 0; bready  <= 0;
            arvalid <= 0; rready  <= 0; done    <= 0;
            awid    <= 0; arid    <= 0; awlen   <= 0; arlen <= 0;
            wlast   <= 0; wdata   <= 0; awaddr  <= 0; araddr <= 0;
            data_out<= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    if (start_write) begin
                        awaddr  <= addr_in;
                        awid    <= 4'h1;
                        awlen   <= 8'h0;
                        awvalid <= 1;
                        state   <= WR_ADDR;
                    end else if (start_read) begin
                        araddr  <= addr_in;
                        arid    <= 4'h2;
                        arlen   <= 8'h0;
                        arvalid <= 1;
                        state   <= RD_ADDR;
                    end
                end
                WR_ADDR: if (awready) begin
                    awvalid <= 0;
                    wdata   <= data_in;
                    wlast   <= 1;
                    wvalid  <= 1;
                    state   <= WR_DATA;
                end
                WR_DATA: if (wready) begin
                    wvalid <= 0; wlast <= 0;
                    bready <= 1;
                    state  <= WR_RESP;
                end
                WR_RESP: if (bvalid) begin
                    bready <= 0; done <= 1;
                    state  <= IDLE;
                end
                RD_ADDR: if (arready) begin
                    arvalid <= 0;
                    rready  <= 1;
                    state   <= RD_DATA;
                end
                RD_DATA: if (rvalid) begin
                    data_out <= rdata;
                    rready   <= 0;
                    done     <= 1;
                    state    <= IDLE;
                end
            endcase
        end
    end
endmodule
