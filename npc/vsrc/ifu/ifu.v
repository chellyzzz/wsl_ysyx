`include "para_defines.v"

module ysyx_23060124_ifu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] i_pc,
  input clk,
  input ifu_rst,
  input i_post_ready,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_ins,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_pc_next,
  output o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] ins;

// import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);
// always @(*) begin
//   npc_pmem_read (i_pc, ins, ifu_rst, 4);
// end
reg [`ysyx_23060124_ISA_WIDTH-1:0] reg_pc_next;
SRAM ifu_sram (
    .clk(clk),
    .reset(ifu_rst),
    .raddr(i_pc),
    .ren(~o_post_valid),
    .valid(o_post_valid),
    .rdata(ins),
    .o_pc(reg_pc_next)
);

// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) ifu2idu_pc_next(
//   .clk(clk),
//   .rst(ifu_rst),
//   .din(i_pc),
//   .dout(reg_pc_next),
//   .wen(o_post_valid)
// );

assign o_ins = i_post_ready && o_post_valid ? ins : o_ins;
// assign o_pc_next = i_post_ready & o_post_valid ? reg_pc_next : 
//                    (~ifu_rst ? 32'h80000000 : o_pc_next);
assign o_pc_next = reg_pc_next;
// assign o_ins = ins;
endmodule
