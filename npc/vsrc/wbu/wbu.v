`include "para_defines.v"

module ysyx_23060124_wbu (
  input clk,
  input i_rst_pcu,
  input i_pre_valid,
  input i_brch,
  input i_jal,
  input i_jalr,
  input i_csrr,
  input i_mret,
  input i_ecall,
  input i_zero,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_pc,
  // ecall and mret
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mepc,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mtvec,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_csrr_rd,
  // 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_rs1,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_imm,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_res,
  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] o_pc_next,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_rd,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_csr_rd,
  output o_pre_ready,
  output o_pc_update
);

// reg tmp_ready;
wire wen2ifu;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] pc_next;
assign o_rd = i_jal || i_jalr ? i_pc + 4 : i_res;
assign o_csr_rd = i_res;
assign pc_next =    i_jal ? (i_pc + i_imm) : 
                    (i_jalr ? (i_rs1 + i_imm) : 
                    (i_brch && i_res ? i_pc + i_imm : 
                    (i_ecall ? i_mtvec :
                    (i_mret ? i_mepc : i_pc + 4))));

ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) next_pc_reg(
  .clk(clk),
  .rst(i_rst_pcu),
  .din(pc_next),
  .dout(o_pc_next),
  .wen(1)
);

assign o_pc_update = (pc_next == o_pc_next);
assign o_pre_ready = 1'b1;

endmodule
