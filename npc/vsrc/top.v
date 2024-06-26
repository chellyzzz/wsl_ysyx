`include "para_defines.v"

module top(clk, i_rst_n);

input clk;
input i_rst_n;
wire rst_n_sync;

ysyx_23060124_stdrst u_stdrst(
  .i_clk        (clk        ),
  .i_rst_n      (i_rst_n      ),
  .o_rst_n_sync (rst_n_sync   )
);
  
wire [`ysyx_23060124_ISA_WIDTH-1:0] imm,ins;
wire [`ysyx_23060124_REG_ADDR-1:0] addr_rs1,addr_rs2,addr_rd;
wire [`ysyx_23060124_CSR_ADDR-1:0] csr_addr;
wire [`ysyx_23060124_ISA_WIDTH-1:0] rs1, rs2, rd;
//csr wdata rd
wire [`ysyx_23060124_ISA_WIDTH-1:0]csr_rd;

wire [`ysyx_23060124_ISA_WIDTH-1:0] res;
//mret ecall
wire [`ysyx_23060124_ISA_WIDTH-1:0] csr_rs2;
wire [`ysyx_23060124_ISA_WIDTH-1:0] mcause, mstatus, mepc, mtvec, mret_a5;
wire [`ysyx_23060124_OPT_WIDTH-1:0] exu_opt, load_opt, store_opt, brch_opt;
wire wen, csr_wen;
wire [`ysyx_23060124_ISA_WIDTH-1:0] pc_next;
wire [`ysyx_23060124_EXU_SEL_WIDTH-1:0] i_src_sel;
wire brch,jal,jalr;                    // idu -> pcu.
wire ecall,mret;                       // idu -> pcu.
wire zero;                             // exu -> pcu.
wire a0_zero;                           //  if a0 is zero, a0_zero == 1
wire if_unsigned;                      // if_unsigned == 1, unsigned; else signed.
wire if_csrr;  // if csrrw or csrrs, then 1;

ysyx_23060124_RegisterFile regfile1(
  .clk(clk),
  .i_mret(mret),
  .waddr(addr_rd),
  .wdata(rd),
  .raddr1(addr_rs1),
  .raddr2(addr_rs2),
  .rdata1(rs1),
  .rdata2(rs2),
  .o_mret_a5(mret_a5),
  .wen(wen),
  .a0_zero(a0_zero)
);

ysyx_23060124_csr_RegisterFile Csrs(
  .clk(clk),
  .rst(rst_n_sync),
  .csr_wen(csr_wen),
  .i_ecall(ecall),
  .i_mret(mret),
  .i_pc(pc_next),
  .csr_addr(csr_addr),
  .csr_wdata(csr_rd),
  .i_mret_a5(mret_a5),
  .o_mcasue(mcause),
  .o_mstatus(mstatus),
  .o_mepc(mepc),
  .o_mtvec(mtvec),
  .csr_rdata(csr_rs2)
);

ysyx_23060124_ifu ifu1(
  .pc_next(pc_next),
  .clk(clk),
  .ifu_rst(rst_n_sync),
  .o_ins(ins)
);

ysyx_23060124_idu idu1(
  .ins(ins),
  .i_rst_n(rst_n_sync),
  .o_imm(imm),
  .o_rd(addr_rd),
  .o_rs1(addr_rs1),
  .o_rs2(addr_rs2),
  .o_csr_addr(csr_addr),
  .o_exu_opt(exu_opt),
  .o_load_opt(load_opt),
  .o_store_opt(store_opt),
  .o_brch_opt(brch_opt),
  .o_wen(wen),
  .o_csr_wen(csr_wen),
  .o_csrr(if_csrr),
  .o_src_sel(i_src_sel),
  .o_if_unsigned(if_unsigned),
  .o_ecall(ecall),
  .o_mret(mret),
  .o_brch(brch),
  .o_jal(jal),
  .o_jalr(jalr)
);

ysyx_23060124_exu exu1(
  .clk(clk),
  .i_rst_n(rst_n_sync),
  .csr_src_sel(csr_wen),
  .src1(rs1),
  .src2(rs2),
  .csr_rs2(csr_rs2),
  .if_unsigned(if_unsigned),
  .i_pc(pc_next),
  .imm(imm),
  .exu_opt(exu_opt),
  .load_opt(load_opt),
  .store_opt(store_opt),
  .brch_opt(brch_opt),
  .i_src_sel(i_src_sel),
  .o_res(res),
  .o_zero(zero)
);


ysyx_23060124_pcu pcu1(
  .clk(clk),
  .i_rst_pcu(rst_n_sync),
  .i_brch(brch),
  .i_jal(jal),
  .i_jalr(jalr),
  .i_csrr(if_csrr),
  .i_mret(mret),
  .i_ecall(ecall),
  .i_zero(0),
  .i_mepc(mepc),
  .i_mtvec(mtvec),
  .i_csrr_rd(csr_rs2),
  .i_rs1(rs1),
  .i_imm(imm),
  .i_res(res),
  .o_pc_next(pc_next),
  .o_rd(rd),
  .o_csr_rd(csr_rd)
);

import "DPI-C" function bit if_ebrk(input int ins);
import "DPI-C" function void check_rst(input bit rst_flag);
always@(*)
begin
  check_rst(rst_n_sync);
  if(if_ebrk(ins))begin  //ins == ebreak.
    if(a0_zero)begin
      $display("\n\033[32mHIT GOOD TRAP at pc = 0x%h\033[0m\n", pc_next); // 输出绿色
    end
    else begin
      $display("\n\033[31mHIT BAD TRAP at pc = 0x%h\033[0m\n", pc_next); // 输出红色
    end
    $finish;
  end
end
endmodule
