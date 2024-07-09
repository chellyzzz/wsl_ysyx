`include "para_defines.v"

module ysyx_23060124_CPU
(
  input wire S_AXI_ACLK,
  input wire S_AXI_ARESETN
  //read data channel
  // input wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_RDATA,
  // input wire [1 : 0] M_AXI_RRESP,
  // input wire  M_AXI_RVALID,
  // output wire  M_AXI_RREADY

  // //read adress channel
  // output wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
  // output wire  M_AXI_ARVALID,
  // input wire  M_AXI_ARREADY,

  // //write back channel
  // input wire [1 : 0] M_AXI_BRESP,
  // input wire  M_AXI_BVALID,
  // output wire  M_AXI_BREADY,

  // //write address channel  
  // output wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
  // output wire  M_AXI_AWVALID,
  // input wire  M_AXI_AWREADY,

  // //write data channel
  // output wire [`ysyx_23060124_ISA_WIDTH-1:0] M_AXI_WDATA,
  // output wire [`ysyx_23060124_ISA_WIDTH/8-1 : 0] M_AXI_WSTRB,
  // output wire  M_AXI_WVALID,
  // input wire  M_AXI_WREADY,  

);
assign clk = S_AXI_ACLK;
assign i_rst_n = S_AXI_ARESETN;

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
wire idu_wen, wbu_wen, csr_wen;
wire [`ysyx_23060124_ISA_WIDTH-1:0] pc_next, ifu_pc_next;
wire [`ysyx_23060124_EXU_SEL_WIDTH-1:0] i_src_sel;
wire brch,jal,jalr;                    // idu -> pcu.
wire ecall,mret;                       // idu -> pcu.
wire zero;                             // exu -> pcu.
wire a0_zero;                           //  if a0 is zero, a0_zero == 1
wire if_unsigned;                      // if_unsigned == 1, unsigned; else signed.
wire if_csrr;  // if csrrw or csrrs, then 1;
wire pc_update_en;
//
wire ifu2idu_valid, idu2ifu_ready;
wire idu2exu_valid, exu2idu_ready;
wire exu2wbu_valid, wbu2exu_ready;

// AXI4Lite_MASTER cpu_to_sram_master
// (
//   .clk(clk),
//   .rst_n(i_rst_n),
//   .i_addr(CPU.o_addr),
//   .i_wdata(CPU.o_wdata),
//   .i_wstrb(CPU.o_wstrb),
//   .i_wen(CPU.o_wen),
//   .i_ren(CPU.o_ren),
//   .o_rdata(CPU.i_rdata)
// );

ysyx_23060124_RegisterFile regfile1(
  .clk(clk),
  .i_ecall(ecall),
  .i_mret(mret),
  .waddr(addr_rd),
  .wdata(rd),
  .raddr1(addr_rs1),
  .raddr2(addr_rs2),
  .rdata1(rs1),
  .rdata2(rs2),
  .o_mret_a5(mret_a5),
  .wen(wbu_wen),
  .a0_zero(a0_zero)
);

ysyx_23060124_csr_RegisterFile Csrs(
  .clk(clk),
  .rst(i_rst_n),
  .csr_wen(csr_wen),
  .i_ecall(ecall),
  .i_mret(mret),
  .i_pc(ifu_pc_next),
  .csr_addr(csr_addr),
  .csr_wdata(csr_rd),
  .i_mret_a5(mret_a5),
  .o_mcause(mcause),
  .o_mstatus(mstatus),
  .o_mepc(mepc),
  .o_mtvec(mtvec),
  .csr_rdata(csr_rs2)
);

SRAM_ifu ifu_sram(
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(ifu_rst),
    //read data channel
    .S_AXI_RDATA(s_axi_rdata),
    .S_AXI_RRESP(rresp),
    .S_AXI_RVALID(s_axi_rvalid),
    .S_AXI_RREADY(M_AXI_RREADY),
    //read adress channel
    .S_AXI_ARADDR(pc_next),
    .S_AXI_ARVALID(M_AXI_ARVALID),
    .S_AXI_ARREADY(s_axi_arready),
    //write back channel
    .S_AXI_BRESP(s_axi_bresp),
    .S_AXI_BVALID(s_axi_bvalid),
    .S_AXI_BREADY(1),
    //write address channel  
    .S_AXI_AWADDR(0),
    .S_AXI_AWVALID(0),
    .S_AXI_AWREADY(s_axi_awready),
    //write data channel
    .S_AXI_WDATA(0),
    .S_AXI_WSTRB(0),
    .S_AXI_WVALID(0),
    .S_AXI_WREADY(s_axi_wready)
);

ysyx_23060124_ifu ifu1(
  .i_pc_next(pc_next),
  .clk(clk),
  .ifu_rst(i_rst_n),
  .i_pc_update(pc_update_en),
  .o_ins(ins),
  .i_post_ready(idu2ifu_ready),
  .o_post_valid(ifu2idu_valid),
  .o_pc_next(ifu_pc_next)
);

ysyx_23060124_idu idu1(
  .ins(ins),
  .i_rst_n(i_rst_n),
  .i_pre_valid(ifu2idu_valid),
  .i_post_ready(exu2idu_ready),
  .o_imm(imm),
  .o_rd(addr_rd),
  .o_rs1(addr_rs1),
  .o_rs2(addr_rs2),
  .o_csr_addr(csr_addr),
  .o_exu_opt(exu_opt),
  .o_load_opt(load_opt),
  .o_store_opt(store_opt),
  .o_brch_opt(brch_opt),
  .o_wen(idu_wen),
  .o_csr_wen(csr_wen),
  .o_csrr(if_csrr),
  .o_src_sel(i_src_sel),
  .o_if_unsigned(if_unsigned),
  .o_ecall(ecall),
  .o_mret(mret),
  .o_brch(brch),
  .o_jal(jal),
  .o_jalr(jalr),
  .o_pre_ready(idu2ifu_ready),
  .o_post_valid(idu2exu_valid)
);

ysyx_23060124_exu exu1(
  .clk(clk),
  .i_rst_n(i_rst_n),
  .i_pre_valid(idu2exu_valid),
  .i_post_ready(wbu2exu_ready),
  .csr_src_sel(csr_wen),
  .src1(rs1),
  .src2(rs2),
  .csr_rs2(csr_rs2),
  .if_unsigned(if_unsigned),
  .i_pc(ifu_pc_next),
  .imm(imm),
  .exu_opt(exu_opt),
  .load_opt(load_opt),
  .store_opt(store_opt),
  .brch_opt(brch_opt),
  .i_src_sel(i_src_sel),
  .o_res(res),
  .o_zero(zero),
  .o_post_valid(exu2wbu_valid),
  .o_pre_ready(exu2idu_ready)
);


ysyx_23060124_wbu wbu1(
  .clk(clk),
  .i_rst_pcu(i_rst_n),
  .i_pre_valid(exu2wbu_valid),
  .i_brch(brch),
  .i_jal(jal),
  .i_wen(idu_wen),
  .i_jalr(jalr),
  .i_csrr(if_csrr),
  .i_mret(mret),
  .i_ecall(ecall),
  .i_mepc(mepc),
  .i_mtvec(mtvec),
  .i_csrr_rd(csr_rs2),
  .i_rs1(rs1),
  .i_pc(ifu_pc_next),
  .i_imm(imm),
  .i_res(res),
  .o_pc_next(pc_next),
  .o_pc_update(pc_update_en),
  .o_rd_wdata(rd),
  .o_csr_rd(csr_rd),
  .o_wbu_wen(wbu_wen),
  .o_pre_ready(wbu2exu_ready)
);

import "DPI-C" function bit if_ebrk(input int ins);
always@(posedge clk)
begin
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
