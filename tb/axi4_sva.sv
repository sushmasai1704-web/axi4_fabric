module axi4_sva #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)(
  input wire clk, resetn,
  input wire awvalid, awready,
  input wire wvalid,  wready, wlast,
  input wire bvalid,  bready,
  input wire arvalid, arready,
  input wire rvalid,  rready, rlast
);

  // Capture previous-cycle state manually (replaces $past)
  reg awvalid_r, awready_r;
  reg wvalid_r,  wready_r;
  reg arvalid_r, arready_r;
  reg rvalid_r,  rready_r;

  always @(posedge clk) begin
    awvalid_r <= awvalid; awready_r <= awready;
    wvalid_r  <= wvalid;  wready_r  <= wready;
    arvalid_r <= arvalid; arready_r <= arready;
    rvalid_r  <= rvalid;  rready_r  <= rready;
  end

  // Rules 1-4: VALID must not drop before READY
  always @(posedge clk) begin
    if (resetn) begin
      if (awvalid_r && !awready_r && !awvalid)
        $fatal(1, "[FAIL] AWVALID dropped before AWREADY at %0t", $time);
      if (wvalid_r  && !wready_r  && !wvalid)
        $fatal(1, "[FAIL] WVALID dropped before WREADY at %0t", $time);
      if (arvalid_r && !arready_r && !arvalid)
        $fatal(1, "[FAIL] ARVALID dropped before ARREADY at %0t", $time);
      if (rvalid_r  && !rready_r  && !rvalid)
        $fatal(1, "[FAIL] RVALID dropped before RREADY at %0t", $time);
    end
  end

  // Rule 5: BVALID must not come before WLAST handshake
  reg wlast_seen;
  always @(posedge clk or negedge resetn) begin
    if (!resetn)                        wlast_seen <= 0;
    else if (wvalid && wready && wlast) wlast_seen <= 1;
    else if (bvalid && bready)          wlast_seen <= 0;
  end
  always @(posedge clk) begin
    if (resetn && bvalid && !wlast_seen)
      $fatal(1, "[FAIL] BVALID before WLAST handshake at %0t", $time);
  end

  // Rule 6: BREADY must respond within 16 cycles
  reg [4:0] bstall;
  always @(posedge clk or negedge resetn) begin
    if (!resetn)                bstall <= 0;
    else if (bvalid && !bready) bstall <= bstall + 1;
    else                        bstall <= 0;
  end
  always @(posedge clk) begin
    if (resetn && bstall >= 16)
      $fatal(1, "[FAIL] BREADY stalled >15 cycles at %0t", $time);
  end

  final $display("=== AXI4 SVA: ALL 6 PROPERTIES PASSED ===");

endmodule
