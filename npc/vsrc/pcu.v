`include "para_defines.v"

module ysyx_23060124_pcu (
  input clk,
  input i_rst_pcu,
  input i_clk,
  input i_brch,
  input i_jal,
  input i_jalr,
  input i_mret,
  input i_ecall,
  input i_zero,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_pc,
  // ecall and mret
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mepc,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mtvec,
  // 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_rs1,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_imm,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_res,
  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] o_pc_next,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_rd
);

wire [`ysyx_23060124_ISA_WIDTH - 1:0] pc_next;

assign o_rd = i_jal || i_jalr ? i_pc + 4 : i_res;

assign pc_next = i_jal ? (i_pc + i_imm) : (i_jalr ? (i_rs1 + i_imm) : (i_brch && i_res ? i_pc + i_imm : (i_ecall ? i_mtvec :(i_mret ? i_mepc : i_pc + 4) )));
// always @(*) begin
//     if (i_jal) begin
//         pc_next = i_pc + i_imm;
//     end 
//     else if (i_jalr) begin
//         pc_next = i_rs1 + i_imm;
//     end 
//     else if(i_ecall) begin
//         pc_next = i_mtvec;
//     end
//     else if(i_mret) begin
//         pc_next = i_mepc;
//     end
//     else if (i_brch && i_res) begin
//         pc_next = i_pc + i_imm;
//     end 
//     else begin
//         pc_next = i_pc + 4;
//     end
// end

ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) next_pc_reg(
  .clk(clk),
  .rst(i_rst_pcu),
  .din(pc_next),
  .dout(o_pc_next),
  .wen(1)
);

endmodule
