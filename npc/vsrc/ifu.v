`include "para_defines.v"

module ysyx_23060124_ifu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] pc_next,
  input clk,
  input ifu_rst,
  output reg o_pc,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_ins,
);

import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);

always @(*) begin
  npc_pmem_read (pc_next, o_ins, ifu_rst, 4);
end

ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) pc_reg(
  .clk(clk),
  .rst(ifu_rst),
  .din(pc_next),
  .dout(o_pc),
  .wen(1)
);

endmodule
