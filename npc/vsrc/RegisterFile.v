`include "para_defines.v"

module ysyx_23060124_RegisterFile (
  input clk,
  input i_mret,
  input [`ysyx_23060124_ISA_WIDTH-1:0] wdata,
  input [`ysyx_23060124_REG_ADDR-1:0] waddr,
  input [`ysyx_23060124_REG_ADDR-1:0] raddr1,
  input [`ysyx_23060124_REG_ADDR-1:0] raddr2,
  output [`ysyx_23060124_ISA_WIDTH-1:0] rdata1,
  output [`ysyx_23060124_ISA_WIDTH-1:0] rdata2,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_mret_a5,
  input wen,
  output a0_zero
);
  reg [`ysyx_23060124_ISA_WIDTH-1:0] rf [`ysyx_23060124_REG_NUM - 1:0];
  
  always @(posedge clk) begin
    if (wen && waddr != 0) rf[waddr] <= wdata;
  end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2];

  assign a0_zero = ~|rf[10]; 
  assign o_mret_a5 = i_mret ? rf[15] : 0;

  // always @(raddr1 or raddr2) begin
  //   $display("raddr1 = 0x%h", raddr1);
  //   $display("raddr2 = 0x%h", raddr2);
  //   $display("a0 = 0x%h", rf[10]);
  // end
  // always @(rdata1 or rdata2) begin
  //   $display("rdata1 = 0x%h", rdata1);
  //   $display("rdata2 = 0x%h", rdata2);
  // end
endmodule
