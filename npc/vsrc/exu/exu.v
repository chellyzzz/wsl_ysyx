 
`define ysyx_23060124_OPT_WIDTH 13
//BRCH_OPT
`define ysyx_23060124_OPT_BRCH_BEQ `ysyx_23060124_OPT_WIDTH'b0000_0000_00001
`define ysyx_23060124_OPT_BRCH_BGE `ysyx_23060124_OPT_WIDTH'b0000_1000_00000
`define ysyx_23060124_OPT_BRCH_BNE `ysyx_23060124_OPT_WIDTH'b0001_0000_00000
`define ysyx_23060124_OPT_BRCH_BLT `ysyx_23060124_OPT_WIDTH'b0010_0000_00000
`define ysyx_23060124_OPT_BRCH_BLTU `ysyx_23060124_OPT_WIDTH'b0100_0000_00000
`define ysyx_23060124_OPT_BRCH_BGEU `ysyx_23060124_OPT_WIDTH'b1000_0000_00000

module ysyx_23060124_EXU(
    input                               clock                      ,
    input                               i_rst_n                    ,
    input                               csr_src_sel                ,
    input              [32 - 1:0]       src1                       ,
    input              [32 - 1:0]       src2                       ,
    input              [32 - 1:0]       csr_rs2                    ,
    input                               if_unsigned                ,
    input              [32 - 1:0]       i_pc                       ,
    input              [32 - 1:0]       imm                        ,
    input              [`ysyx_23060124_OPT_WIDTH - 1:0]exu_opt                    ,
    input              [4 - 1:0]        load_opt                   ,
    input              [4 - 1:0]        store_opt                  ,
    input              [`ysyx_23060124_OPT_WIDTH - 1:0]brch_opt                   ,
    input              [2 - 1:0]        i_src_sel                  ,
    output             [32 - 1:0]       o_res                      ,
    output                              o_zero                     ,
  //axi interface
    //write address channel  
    output             [32-1 : 0]       M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [32-1 : 0]       M_AXI_WDATA                ,
    output             [4-1 : 0]        M_AXI_WSTRB                ,
    input                               M_AXI_WLAST                ,

    //read data channel
    input              [32-1 : 0]       M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [4-1 : 0]        M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [32-1 : 0]       M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [4-1 : 0]        M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [4-1 : 0]        M_AXI_BID                  ,
  //exu -> wbu handshake
    input                               i_post_ready               ,
    input                               i_pre_valid                ,
    output                              o_post_valid               ,
    output reg                          o_pre_ready                 
);

`define ysyx_23060124_EXU_SEL_REG 2'b00
`define ysyx_23060124_EXU_SEL_IMM 2'b01
`define ysyx_23060124_EXU_SEL_PC4 2'b10
`define ysyx_23060124_EXU_SEL_PCI 2'b11


wire lsu_post_valid;  

// assign o_pre_ready = 1'b1;
always @(posedge  clock or negedge i_rst_n) begin
  if(~i_rst_n) begin
    o_pre_ready <= 1'b0;
  end
  else if(i_pre_valid && ~o_pre_ready) begin
    o_pre_ready <= 1'b1;
  end
  else if(o_pre_ready && i_post_ready) begin
    o_pre_ready <= 1'b0;
  end
  else o_pre_ready <= o_pre_ready;
end

assign o_post_valid = lsu_post_valid;

wire [32 - 1:0] sel_src2;
wire [32-1:0] alu_src1,alu_src2;
wire [32 - 1:0] alu_res, lsu_res;
wire carry, brch_res;

assign sel_src2 = csr_src_sel ? csr_rs2 : src2;

assign alu_src1 = (i_src_sel == `ysyx_23060124_EXU_SEL_REG) ? src1 :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_IMM) ? src1 :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_PC4) ? i_pc :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_PCI) ? i_pc : 32'b0;

assign alu_src2 = (i_src_sel == `ysyx_23060124_EXU_SEL_REG) ? sel_src2 :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_IMM) ? imm :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_PC4) ? 32'h4 :
                 (i_src_sel == `ysyx_23060124_EXU_SEL_PCI) ? imm : 32'b0;

ysyx_23060124_ALU exu_alu(
  .src1(alu_src1),
  .src2(alu_src2),
  .if_unsigned(if_unsigned),
  .opt(exu_opt),
  .res(alu_res),
  .carry(carry)
);

ysyx_23060124_LSU exu_lsu(
    .clock                             (clock                     ),
    .i_rst_n                           (i_rst_n                   ),
    .lsu_src2                          (src2                      ),
    .alu_res                           (alu_res                   ),
    .load_opt                          (load_opt                  ),
    .store_opt                         (store_opt                 ),
    .lsu_res                           (lsu_res                   ),
    .if_unsigned                       (if_unsigned               ),
  //lsu ->exu sram axi
  //write address channel  
    .M_AXI_AWADDR                      (M_AXI_AWADDR              ),
    .M_AXI_AWVALID                     (M_AXI_AWVALID             ),
    .M_AXI_AWREADY                     (M_AXI_AWREADY             ),
    .M_AXI_AWLEN                       (M_AXI_AWLEN               ),
    .M_AXI_AWSIZE                      (M_AXI_AWSIZE              ),
    .M_AXI_AWBURST                     (M_AXI_AWBURST             ),
  //write data channel
    .M_AXI_WVALID                      (M_AXI_WVALID              ),
    .M_AXI_WREADY                      (M_AXI_WREADY              ),
    .M_AXI_WDATA                       (M_AXI_WDATA               ),
    .M_AXI_WSTRB                       (M_AXI_WSTRB               ),
    .M_AXI_WLAST                       (M_AXI_WLAST               ),
  //read data channel
    .M_AXI_RDATA                       (M_AXI_RDATA               ),
    .M_AXI_RRESP                       (M_AXI_RRESP               ),
    .M_AXI_RVALID                      (M_AXI_RVALID              ),
    .M_AXI_RREADY                      (M_AXI_RREADY              ),
    .M_AXI_RID                         (M_AXI_RID                 ),
    .M_AXI_RLAST                       (M_AXI_RLAST               ),
  //read adress channel
    .M_AXI_ARADDR                      (M_AXI_ARADDR              ),
    .M_AXI_ARVALID                     (M_AXI_ARVALID             ),
    .M_AXI_ARREADY                     (M_AXI_ARREADY             ),
    .M_AXI_ARID                        (M_AXI_ARID                ),
    .M_AXI_ARLEN                       (M_AXI_ARLEN               ),
    .M_AXI_ARSIZE                      (M_AXI_ARSIZE              ),
    .M_AXI_ARBURST                     (M_AXI_ARBURST             ),
  //write back channel
    .M_AXI_BRESP                       (M_AXI_BRESP               ),
    .M_AXI_BVALID                      (M_AXI_BVALID              ),
    .M_AXI_BREADY                      (M_AXI_BREADY              ),
    .M_AXI_BID                         (M_AXI_BID                 ),
  //handshake
    .i_pre_valid                       (i_pre_valid               ),
    .o_pre_ready                       (o_pre_ready               ),
    .o_post_valid                      (lsu_post_valid            ) 
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
