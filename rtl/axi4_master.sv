module axi4_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  logic                    clk, rst_n,
    // Write address
    output logic [ID_WIDTH-1:0]     awid,
    output logic [ADDR_WIDTH-1:0]   awaddr,
    output logic [7:0]              awlen,
    output logic                    awvalid,
    input  logic                    awready,
    // Write data
    output logic [DATA_WIDTH-1:0]   wdata,
    output logic                    wlast,
    output logic                    wvalid,
    input  logic                    wready,
    // Write response
    input  logic [ID_WIDTH-1:0]     bid,
    input  logic [1:0]              bresp,
    input  logic                    bvalid,
    output logic                    bready,
    // Read address
    output logic [ID_WIDTH-1:0]     arid,
    output logic [ADDR_WIDTH-1:0]   araddr,
    output logic [7:0]              arlen,
    output logic                    arvalid,
    input  logic                    arready,
    // Read data
    input  logic [ID_WIDTH-1:0]     rid,
    input  logic [DATA_WIDTH-1:0]   rdata,
    input  logic                    rlast,
    input  logic [1:0]              rresp,
    input  logic                    rvalid,
    output logic                    rready,
    // User interface
    input  logic                    start_write,
    input  logic                    start_read,
    input  logic [ADDR_WIDTH-1:0]   addr_in,
    input  logic [DATA_WIDTH-1:0]   data_in,
    output logic [DATA_WIDTH-1:0]   data_out,
    output logic                    done
);
    typedef enum logic [2:0] {IDLE, WR_ADDR, WR_DATA, WR_RESP, RD_ADDR, RD_DATA} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            awvalid <= 0; wvalid  <= 0; bready  <= 0;
            arvalid <= 0; rready  <= 0; done    <= 0;
            awid    <= 0; arid    <= 0; awlen   <= 0; arlen <= 0;
            wlast   <= 0; wdata   <= 0;
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
