`include "para_defines.v"

module ysyx_23060124_wbu (
  input clk,
  input i_rst_pcu,
  input i_pre_valid,
  input i_wen,
  input i_brch,
  input i_jal,
  input i_jalr,
  input i_csrr,
  input i_mret,
  input i_ecall,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_pc,
  // ecall and mret
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mepc,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mtvec,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_csrr_rd,
  // 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_rs1,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_imm,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_res,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_pc_next,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_rd_wdata,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_csr_rd,
  output o_pre_ready,
  output o_wbu_wen,
  output o_pc_update
);

wire [`ysyx_23060124_ISA_WIDTH - 1:0] pc;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] res;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] rs1;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] imm;
wire brch;
wire jal;
wire jalr;
wire csrr;
wire mret;
wire ecall;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] mtvec;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] mepc;

assign pc = i_pre_valid && o_pre_ready ? i_pc : pc;
assign res = i_pre_valid && o_pre_ready ? i_res : res;
assign rs1 = i_pre_valid && o_pre_ready ? i_rs1 : rs1;
assign imm = i_pre_valid && o_pre_ready ? i_imm : imm;
assign brch = i_pre_valid && o_pre_ready ? i_brch : brch;
assign jal = i_pre_valid && o_pre_ready ? i_jal : jal;
assign jalr = i_pre_valid && o_pre_ready ? i_jalr : jalr;
assign csrr = i_pre_valid && o_pre_ready ? i_csrr : csrr;
assign mret = i_pre_valid && o_pre_ready ? i_mret : mret;
assign ecall = i_pre_valid && o_pre_ready ? i_ecall : ecall;
assign mtvec = i_pre_valid && o_pre_ready ? i_mtvec : mtvec;
assign mepc = i_pre_valid && o_pre_ready ? i_mepc : mepc; 
assign o_wbu_wen = i_pre_valid && o_pre_ready ? i_wen : 1'b0;
// reg tmp_ready;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] pc_next;
assign o_rd_wdata = jal || jalr ? pc + 4 : res;
assign o_csr_rd = res;
assign o_pc_next =    jal ? (pc + imm) : 
                      (jalr ? (rs1 + imm) : 
                      (brch && res ? pc + imm : 
                      (ecall ? mtvec :
                      (mret ? mepc : pc + 4))));

// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) next_pc_reg(
//   .clk(clk),
//   .rst(i_rst_pcu),
//   .din(pc_next),
//   .dout(o_pc_next),
//   .wen(i_pre_valid)
// );

assign o_pc_update = i_pre_valid && o_pre_ready;
assign o_pre_ready = 1'b1;

endmodule
