`include "para_defines.v"

module ysyx_23060124_CPU
(
  input  AXI_ACLK,
  input  AXI_ARESETN,
  //write address channel  
  output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_CPU_AXI_AWADDR,
  output  M_CPU_AXI_AWVALID,
  input  M_CPU_AXI_AWREADY,
  //write data channel
  output  M_CPU_AXI_WVALID,
  input  M_CPU_AXI_WREADY,
  output [`ysyx_23060124_ISA_WIDTH-1 : 0] M_CPU_AXI_WDATA,
  output [`ysyx_23060124_OPT_WIDTH-1 : 0] M_CPU_AXI_WSTRB,
  //read data channel
  input [`ysyx_23060124_ISA_WIDTH-1 : 0] M_CPU_AXI_RDATA,
  input [1 : 0] M_CPU_AXI_RRESP,
  input  M_CPU_AXI_RVALID,
  output  M_CPU_AXI_RREADY,
  //read adress channel
  output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_CPU_AXI_ARADDR,
  output  M_CPU_AXI_ARVALID,
  input  M_CPU_AXI_ARREADY,
  //write back channel
  input [1 : 0] M_CPU_AXI_BRESP,
  input  M_CPU_AXI_BVALID,
  output  M_CPU_AXI_BREADY
);
assign clk = AXI_ACLK;
assign i_rst_n = AXI_ARESETN;

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
ysyx_23060124_ifu ifu1(
    .i_pc_next                         (pc_next                   ),
    .clk                               (clk                       ),
    .ifu_rst                           (i_rst_n                   ),
    .i_pc_update                       (pc_update_en              ),
    .o_ins                             (ins                       ),
  //ifu -> sram axi
  //write address channel  
    .M_AXI_AWADDR                      (IFU_SRAM_AXI_AWADDR       ),
    .M_AXI_AWVALID                     (IFU_SRAM_AXI_AWVALID      ),
    .M_AXI_AWREADY                     (IFU_SRAM_AXI_AWREADY      ),
  //write data channel
    .M_AXI_WVALID                      (IFU_SRAM_AXI_WVALID       ),
    .M_AXI_WREADY                      (IFU_SRAM_AXI_WREADY       ),
    .M_AXI_WDATA                       (IFU_SRAM_AXI_WDATA        ),
    .M_AXI_WSTRB                       (IFU_SRAM_AXI_WSTRB        ),
  //read data channel
    .M_AXI_RDATA                       (IFU_SRAM_AXI_RDATA        ),
    .M_AXI_RRESP                       (IFU_SRAM_AXI_RRESP        ),
    .M_AXI_RVALID                      (IFU_SRAM_AXI_RVALID       ),
    .M_AXI_RREADY                      (IFU_SRAM_AXI_RREADY       ),
  //read adress channel
    .M_AXI_ARADDR                      (IFU_SRAM_AXI_ARADDR       ),
    .M_AXI_ARVALID                     (IFU_SRAM_AXI_ARVALID      ),
    .M_AXI_ARREADY                     (IFU_SRAM_AXI_ARREADY      ),
  //write back channel
    .M_AXI_BRESP                       (IFU_SRAM_AXI_BRESP        ),
    .M_AXI_BVALID                      (IFU_SRAM_AXI_BVALID       ),
    .M_AXI_BREADY                      (IFU_SRAM_AXI_BREADY       ),
  //ifu -> idu handshake
    .i_post_ready                      (idu2ifu_ready             ),
    .o_post_valid                      (ifu2idu_valid             ),
    .o_pc_next                         (ifu_pc_next               ) 
);

ysyx_23060124_idu idu1(
    .ins                               (ins                       ),
    .i_rst_n                           (i_rst_n                   ),
    .i_pre_valid                       (ifu2idu_valid             ),
    .i_post_ready                      (exu2idu_ready             ),
    .o_imm                             (imm                       ),
    .o_rd                              (addr_rd                   ),
    .o_rs1                             (addr_rs1                  ),
    .o_rs2                             (addr_rs2                  ),
    .o_csr_addr                        (csr_addr                  ),
    .o_exu_opt                         (exu_opt                   ),
    .o_load_opt                        (load_opt                  ),
    .o_store_opt                       (store_opt                 ),
    .o_brch_opt                        (brch_opt                  ),
    .o_wen                             (idu_wen                   ),
    .o_csr_wen                         (csr_wen                   ),
    .o_csrr                            (if_csrr                   ),
    .o_src_sel                         (i_src_sel                 ),
    .o_if_unsigned                     (if_unsigned               ),
    .o_ecall                           (ecall                     ),
    .o_mret                            (mret                      ),
    .o_brch                            (brch                      ),
    .o_jal                             (jal                       ),
    .o_jalr                            (jalr                      ),
    .o_pre_ready                       (idu2ifu_ready             ),
    .o_post_valid                      (idu2exu_valid             ) 
);
//write address channel  
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] IFU_SRAM_AXI_AWADDR,LSU_SRAM_AXI_AWADDR;
wire  IFU_SRAM_AXI_AWVALID, LSU_SRAM_AXI_AWVALID;
wire  IFU_SRAM_AXI_AWREADY, LSU_SRAM_AXI_AWREADY;
//write data channel
wire  IFU_SRAM_AXI_WVALID, LSU_SRAM_AXI_WVALID;
wire  IFU_SRAM_AXI_WREADY, LSU_SRAM_AXI_WREADY;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] IFU_SRAM_AXI_WDATA, LSU_SRAM_AXI_WDATA;
wire [`ysyx_23060124_OPT_WIDTH-1 : 0] IFU_SRAM_AXI_WSTRB, LSU_SRAM_AXI_WSTRB;
//read data channel
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] IFU_SRAM_AXI_RDATA, LSU_SRAM_AXI_RDATA;
wire [1 : 0] IFU_SRAM_AXI_RRESP, LSU_SRAM_AXI_RRESP;
wire  IFU_SRAM_AXI_RVALID, LSU_SRAM_AXI_RVALID;
wire  IFU_SRAM_AXI_RREADY, LSU_SRAM_AXI_RREADY;
//read adress channel
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] IFU_SRAM_AXI_ARADDR, LSU_SRAM_AXI_ARADDR;
wire  IFU_SRAM_AXI_ARVALID, LSU_SRAM_AXI_ARVALID;
wire  IFU_SRAM_AXI_ARREADY, LSU_SRAM_AXI_ARREADY;
//write back channel
wire [1 : 0] IFU_SRAM_AXI_BRESP, LSU_SRAM_AXI_BRESP;
wire  IFU_SRAM_AXI_BVALID, LSU_SRAM_AXI_BVALID;
wire  IFU_SRAM_AXI_BREADY, LSU_SRAM_AXI_BREADY;

ysyx_23060124_exu exu1(
  .clk(clk),
  .i_rst_n(i_rst_n),
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
  //lsu -> sram axi
  //write address channel  
  .M_AXI_AWADDR(LSU_SRAM_AXI_AWADDR),
  .M_AXI_AWVALID(LSU_SRAM_AXI_AWVALID),
  .M_AXI_AWREADY(LSU_SRAM_AXI_AWREADY),
  //write data channel
  .M_AXI_WVALID(LSU_SRAM_AXI_WVALID),
  .M_AXI_WREADY(LSU_SRAM_AXI_WREADY),
  .M_AXI_WDATA(LSU_SRAM_AXI_WDATA),
  .M_AXI_WSTRB(LSU_SRAM_AXI_WSTRB),
  //read data channel
  .M_AXI_RDATA(LSU_SRAM_AXI_RDATA),
  .M_AXI_RRESP(LSU_SRAM_AXI_RRESP),
  .M_AXI_RVALID(LSU_SRAM_AXI_RVALID),
  .M_AXI_RREADY(LSU_SRAM_AXI_RREADY),
  //read adress channel
  .M_AXI_ARADDR(LSU_SRAM_AXI_ARADDR),
  .M_AXI_ARVALID(LSU_SRAM_AXI_ARVALID),
  .M_AXI_ARREADY(LSU_SRAM_AXI_ARREADY),
  //write back channel
  .M_AXI_BRESP(LSU_SRAM_AXI_BRESP),
  .M_AXI_BVALID(LSU_SRAM_AXI_BVALID),
  .M_AXI_BREADY(LSU_SRAM_AXI_BREADY),
  //exu -> wbu handshake
  .i_pre_valid(idu2exu_valid),
  .i_post_ready(wbu2exu_ready),
  .o_post_valid(exu2wbu_valid),
  .o_pre_ready(exu2idu_ready)
);

ysyx_23060124_wbu wbu1(
    .clk                               (clk                       ),
    .i_rst_pcu                         (i_rst_n                   ),
    .i_pre_valid                       (exu2wbu_valid             ),
    .i_brch                            (brch                      ),
    .i_jal                             (jal                       ),
    .i_wen                             (idu_wen                   ),
    .i_jalr                            (jalr                      ),
    .i_csrr                            (if_csrr                   ),
    .i_mret                            (mret                      ),
    .i_ecall                           (ecall                     ),
    .i_mepc                            (mepc                      ),
    .i_mtvec                           (mtvec                     ),
    .i_csrr_rd                         (csr_rs2                   ),
    .i_rs1                             (rs1                       ),
    .i_pc                              (ifu_pc_next               ),
    .i_imm                             (imm                       ),
    .i_res                             (res                       ),
    .o_pc_next                         (pc_next                   ),
    .o_pc_update                       (pc_update_en              ),
    .o_rd_wdata                        (rd                        ),
    .o_csr_rd                          (csr_rd                    ),
    .o_wbu_wen                         (wbu_wen                   ),
    .o_pre_ready                       (wbu2exu_ready             ) 
);

AXI_LITE_ARBITRATOR ifu_lsu_arbitor(
    .CLK                               (clk                       ),
    .RESETN                            (i_rst_n                   ),
  // IFU AXI-Lite Interface
    .IFU_AWVALID                       (IFU_SRAM_AXI_AWVALID      ),
    .IFU_AWADDR                        (IFU_SRAM_AXI_AWADDR       ),
    .IFU_AWREADY                       (IFU_SRAM_AXI_AWREADY      ),
    .IFU_WVALID                        (IFU_SRAM_AXI_WVALID       ),
    .IFU_WDATA                         (IFU_SRAM_AXI_WDATA        ),
    .IFU_WSTRB                         (IFU_SRAM_AXI_WSTRB        ),
    .IFU_WREADY                        (IFU_SRAM_AXI_WREADY       ),
    .IFU_BRESP                         (IFU_SRAM_AXI_BRESP        ),
    .IFU_BVALID                        (IFU_SRAM_AXI_BVALID       ),
    .IFU_BREADY                        (IFU_SRAM_AXI_BREADY       ),
    .IFU_ARVALID                       (IFU_SRAM_AXI_ARVALID      ),
    .IFU_ARADDR                        (IFU_SRAM_AXI_ARADDR       ),
    .IFU_ARREADY                       (IFU_SRAM_AXI_ARREADY      ),
    .IFU_RDATA                         (IFU_SRAM_AXI_RDATA        ),
    .IFU_RRESP                         (IFU_SRAM_AXI_RRESP        ),
    .IFU_RVALID                        (IFU_SRAM_AXI_RVALID       ),
    .IFU_RREADY                        (IFU_SRAM_AXI_RREADY       ),

  // LSU AXI-Lite Interface
    .LSU_AWVALID                       (LSU_SRAM_AXI_AWVALID      ),
    .LSU_AWADDR                        (LSU_SRAM_AXI_AWADDR       ),
    .LSU_AWREADY                       (LSU_SRAM_AXI_AWREADY      ),
    .LSU_WVALID                        (LSU_SRAM_AXI_WVALID       ),
    .LSU_WDATA                         (LSU_SRAM_AXI_WDATA        ),
    .LSU_WSTRB                         (LSU_SRAM_AXI_WSTRB        ),
    .LSU_WREADY                        (LSU_SRAM_AXI_WREADY       ),
    .LSU_BRESP                         (LSU_SRAM_AXI_BRESP        ),
    .LSU_BVALID                        (LSU_SRAM_AXI_BVALID       ),
    .LSU_BREADY                        (LSU_SRAM_AXI_BREADY       ),
    .LSU_ARVALID                       (LSU_SRAM_AXI_ARVALID      ),
    .LSU_ARADDR                        (LSU_SRAM_AXI_ARADDR       ),
    .LSU_ARREADY                       (LSU_SRAM_AXI_ARREADY      ),
    .LSU_RDATA                         (LSU_SRAM_AXI_RDATA        ),
    .LSU_RRESP                         (LSU_SRAM_AXI_RRESP        ),
    .LSU_RVALID                        (LSU_SRAM_AXI_RVALID       ),
    .LSU_RREADY                        (LSU_SRAM_AXI_RREADY       ),

  // SRAM AXI-Lite Interface
    .SRAM_AWADDR                       (M_CPU_AXI_AWADDR           ),
    .SRAM_AWVALID                      (M_CPU_AXI_AWVALID          ),
    .SRAM_AWREADY                      (M_CPU_AXI_AWREADY          ),
    .SRAM_WDATA                        (M_CPU_AXI_WDATA            ),
    .SRAM_WSTRB                        (M_CPU_AXI_WSTRB            ),
    .SRAM_WVALID                       (M_CPU_AXI_WVALID           ),
    .SRAM_WREADY                       (M_CPU_AXI_WREADY           ),
    .SRAM_BRESP                        (M_CPU_AXI_BRESP            ),
    .SRAM_BVALID                       (M_CPU_AXI_BVALID           ),
    .SRAM_BREADY                       (M_CPU_AXI_BREADY           ),
    .SRAM_ARADDR                       (M_CPU_AXI_ARADDR           ),
    .SRAM_ARVALID                      (M_CPU_AXI_ARVALID          ),
    .SRAM_ARREADY                      (M_CPU_AXI_ARREADY          ),
    .SRAM_RDATA                        (M_CPU_AXI_RDATA            ),
    .SRAM_RRESP                        (M_CPU_AXI_RRESP            ),
    .SRAM_RVALID                       (M_CPU_AXI_RVALID           ),
    .SRAM_RREADY                       (M_CPU_AXI_RREADY           ) 
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
