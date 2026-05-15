module axi4_assertions #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)(
  input clk, input resetn,
  input awvalid, input awready,
  input wvalid, input wready, input wlast,
  input bvalid, input bready,
  input arvalid, input arready,
  input rvalid, input rready, input rlast
);
  reg awvalid_prev, wvalid_prev, arvalid_prev, rvalid_prev;
  reg aw_done, w_done;
  integer b_wait;

  always @(posedge clk) awvalid_prev <= awvalid;
  always @(posedge clk) wvalid_prev  <= wvalid;
  always @(posedge clk) arvalid_prev <= arvalid;
  always @(posedge clk) rvalid_prev  <= rvalid;

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin aw_done<=0; w_done<=0; b_wait<=0; end
    else begin
      if (awvalid && awready) aw_done <= 1;
      if (wvalid  && wready && wlast) w_done <= 1;
      if (bvalid  && bready) begin aw_done<=0; w_done<=0; end
      if (awvalid_prev && !awready && !awvalid)
        $fatal(1,"[FAIL] AWVALID dropped before AWREADY at %0t",$time);
      if (wvalid_prev && !wready && !wvalid)
        $fatal(1,"[FAIL] WVALID dropped before WREADY at %0t",$time);
      if (bvalid && !w_done)
        $fatal(1,"[FAIL] BVALID before WLAST at %0t",$time);
      if (bvalid && !bready) b_wait <= b_wait + 1;
      else b_wait <= 0;
      if (b_wait > 15)
        $fatal(1,"[FAIL] BREADY stalled >15 cycles at %0t",$time);
      if (arvalid_prev && !arready && !arvalid)
        $fatal(1,"[FAIL] ARVALID dropped before ARREADY at %0t",$time);
      if (rvalid_prev && !rready && !rvalid)
        $fatal(1,"[FAIL] RVALID dropped before RREADY at %0t",$time);
    end
  end

endmodule
