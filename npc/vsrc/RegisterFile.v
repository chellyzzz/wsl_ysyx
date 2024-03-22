`include "para_defines.v"

module ysyx_23060124_RegisterFile (
  input clk,
  input [`ysyx_23060124_ISA_WIDTH-1:0] wdata,
  input [`ysyx_23060124_REG_ADDR-1:0] waddr,
  input [`ysyx_23060124_REG_ADDR-1:0] raddr1,
  input [`ysyx_23060124_REG_ADDR-1:0] raddr2,
  output [`ysyx_23060124_ISA_WIDTH-1:0] rdata1,
  output [`ysyx_23060124_ISA_WIDTH-1:0] rdata2,
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
  
endmodule