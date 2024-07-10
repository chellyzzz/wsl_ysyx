`include "para_defines.v"

module ysyx_23060124_exu(
  input clk,
  input i_rst_n,
  input csr_src_sel,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] src1,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] src2,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] csr_rs2,
  input if_unsigned,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_pc,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] imm,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] exu_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] load_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] store_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] brch_opt,
  input [`ysyx_23060124_EXU_SEL_WIDTH - 1:0] i_src_sel,
  output [`ysyx_23060124_ISA_WIDTH - 1:0] o_res,
  output o_zero,
  //axi interface
  //write address channel  
  output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
  output  M_AXI_AWVALID,
  input  M_AXI_AWREADY,
  //write data channel
  output  M_AXI_WVALID,
  input  M_AXI_WREADY,
  output [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_WDATA,
  output [`ysyx_23060124_OPT_WIDTH-1 : 0] M_AXI_WSTRB,
  //read data channel
  input [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_RDATA,
  input [1 : 0] M_AXI_RRESP,
  input  M_AXI_RVALID,
  output  M_AXI_RREADY,
  //read adress channel
  output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
  output  M_AXI_ARVALID,
  input  M_AXI_ARREADY,
  //write back channel
  input [1 : 0] M_AXI_BRESP,
  input  M_AXI_BVALID,
  output  M_AXI_BREADY,
  //exu -> wbu handshake
  input i_post_ready,
  input i_pre_valid,
  output o_post_valid,
  output o_pre_ready
);

wire lsu_post_valid;  

assign o_pre_ready = 1'b1;
assign o_post_valid = lsu_post_valid;

wire [`ysyx_23060124_ISA_WIDTH - 1:0] sel_src2;
wire [`ysyx_23060124_ISA_WIDTH-1:0] alu_src1,alu_src2;
wire [`ysyx_23060124_ISA_WIDTH - 1:0] alu_res, lsu_res;
wire carry, brch_res;

assign sel_src2 = csr_src_sel ? csr_rs2 : src2;

ysyx_23060124_MuxKeyWithDefault #(1<<`ysyx_23060124_EXU_SEL_WIDTH, `ysyx_23060124_EXU_SEL_WIDTH, `ysyx_23060124_ISA_WIDTH) mux_src1 (alu_src1, i_src_sel, `ysyx_23060124_ISA_WIDTH'b0, {
    `ysyx_23060124_EXU_SEL_REG, src1,
    `ysyx_23060124_EXU_SEL_IMM, src1,
    `ysyx_23060124_EXU_SEL_PC4, i_pc,
    `ysyx_23060124_EXU_SEL_PCI, i_pc
  });

ysyx_23060124_MuxKeyWithDefault #(1<<`ysyx_23060124_EXU_SEL_WIDTH, `ysyx_23060124_EXU_SEL_WIDTH, `ysyx_23060124_ISA_WIDTH) mux_src2 (alu_src2, i_src_sel, `ysyx_23060124_ISA_WIDTH'b0, {
    `ysyx_23060124_EXU_SEL_REG, sel_src2,
    `ysyx_23060124_EXU_SEL_IMM, imm,
    `ysyx_23060124_EXU_SEL_PC4, `ysyx_23060124_ISA_WIDTH'h4,
    `ysyx_23060124_EXU_SEL_PCI, imm
});

// always @(alu_src1 or alu_src2 or imm) begin
//   $display("alu_src1 = 0x%h at 0x%h", alu_src1, i_pc);
//   $display("alu_src2 = 0x%h at 0x%h", alu_src2, i_pc);
//   $display("imm = 0x%h at 0x%h", imm, i_pc);
// end

ysyx_23060124_alu exu_alu(
  .src1(alu_src1),
  .src2(alu_src2),
  .if_unsigned(if_unsigned),
  .opt(exu_opt),
  .res(alu_res),
  .carry(carry)
);

ysyx_23060124_lsu exu_lsu(
  .i_clk(clk),
  .i_rst_n(i_rst_n),
  .lsu_src2(src2),
  .alu_res(alu_res),
  .load_opt(load_opt),
  .store_opt(store_opt),
  .lsu_res(lsu_res),
  //lsu ->exu sram axi
  //write address channel  
  .M_AXI_AWADDR(M_AXI_AWADDR),
  .M_AXI_AWVALID(M_AXI_AWVALID),
  .M_AXI_AWREADY(M_AXI_AWREADY),
  //write data channel
  .M_AXI_WVALID(M_AXI_WVALID),
  .M_AXI_WREADY(M_AXI_WREADY),
  .M_AXI_WDATA(M_AXI_WDATA),
  .M_AXI_WSTRB(M_AXI_WSTRB),
  //read data channel
  .M_AXI_RDATA(M_AXI_RDATA),
  .M_AXI_RRESP(M_AXI_RRESP),
  .M_AXI_RVALID(M_AXI_RVALID),
  .M_AXI_RREADY(M_AXI_RREADY),
  //read adress channel
  .M_AXI_ARADDR(M_AXI_ARADDR),
  .M_AXI_ARVALID(M_AXI_ARVALID),
  .M_AXI_ARREADY(M_AXI_ARREADY),
  //write back channel
  .M_AXI_BRESP(M_AXI_BRESP),
  .M_AXI_BVALID(M_AXI_BVALID),
  .M_AXI_BREADY(M_AXI_BREADY),
  //handshake
  .i_post_ready(i_post_ready),
  .i_pre_valid(i_pre_valid),
  .o_post_valid(lsu_post_valid),
  .o_pre_ready(o_pre_ready)
);

assign brch_res = (brch_opt == `ysyx_23060124_OPT_BRCH_BEQ) ? ((alu_res == 0)) :
                  (brch_opt == `ysyx_23060124_OPT_BRCH_BNE) ? ((alu_res != 0)) :
                  (brch_opt == `ysyx_23060124_OPT_BRCH_BLT) ? (carry == 1'b1) :
                  (brch_opt == `ysyx_23060124_OPT_BRCH_BGE) ? (carry == 1'b0) :
                  (brch_opt == `ysyx_23060124_OPT_BRCH_BLTU) ? ((carry == 1'b1)) :
                  (brch_opt == `ysyx_23060124_OPT_BRCH_BGEU) ? ((carry == 1'b0)) :
                  1'b0;

assign o_res = (|load_opt) ? lsu_res : (|brch_opt ? {31'b0, brch_res} : alu_res);
assign o_zero = ~(|o_res);

endmodule
