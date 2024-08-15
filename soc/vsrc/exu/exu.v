module ysyx_23060124_EXU(
    input                               clock                      ,
    input                               reset                      ,
    input              [  31:0]         i_src1                     ,
    input              [  31:0]         i_src2                     ,
    input              [  31:0]         i_pc                       ,
    input              [  31:0]         i_imm                      ,
    input              [   1:0]         i_src_sel                  ,

    input                               if_unsigned                ,
    //control signal
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    //ecall and mret
    input                               i_ecall                    ,
    input                               i_mret                     ,

    input              [   2:0]         exu_opt                    ,

    output             [  31:0]         o_res                      ,
    output                              o_brch                     ,
    output             [  31:0]         o_pc_next                  ,
  //axi interface
    //write address channel  
    output             [  31:0]         M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [   3:0]         M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [  31:0]         M_AXI_WDATA                ,
    output             [   3:0]         M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [  31:0]         M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [   3:0]         M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [  31:0]         M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [   3:0]         M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [   3:0]         M_AXI_BID                  ,
  //exu -> wbu handshake
    input                               i_post_ready               ,
    input                               i_pre_valid                ,
    output                              o_post_valid               ,
    output                              o_pre_ready                 
);


/******************parameter******************/
parameter BEQ   = 3'b000;
parameter BNE   = 3'b001;
parameter BLT   = 3'b100;
parameter BGE   = 3'b101;
parameter BLTU  = 3'b110;
parameter BGEU  = 3'b111;


wire                   [  31:0]         alu_res, load_res           ;
wire                                    brch_res                   ;
wire                                    if_lsu                     ;

reg post_valid;
assign if_lsu = i_load || i_store;
assign o_post_valid =  if_lsu  ?  (M_AXI_RLAST && M_AXI_RREADY)||(M_AXI_BREADY) : 
                        post_valid;

assign o_pre_ready  =  if_lsu  ?  (M_AXI_RLAST && M_AXI_RREADY)||(M_AXI_BREADY) : 
                       1'b1;

always @(posedge clock) begin
    if(reset) begin
        post_valid <= 1'b0;   
    end
    else if(i_pre_valid) begin
        post_valid <= 1'b1;
    end
    else if(~i_pre_valid)begin
        post_valid <= 1'b0;
    end
end
wire [2:0] alu_opt;
assign alu_opt =  if_lsu                ? 3'b000:
                  i_brch && ~exu_opt[1] ? 3'b010:
                  i_brch &&  exu_opt[2] ? 3'b011:
                  exu_opt;

//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;

// wire                   [  31:0]         alu_src1                   ;
// wire                   [  31:0]         alu_src2                   ;
// assign alu_src1 = (i_src_sel == EXU_SEL_REG) ? i_src1   :
//                   (i_src_sel == EXU_SEL_IMM) ? i_src1   :
//                   (i_src_sel == EXU_SEL_PC4) ? i_pc     :
//                   (i_src_sel == EXU_SEL_PCI) ? i_pc     : 32'b0;

// assign alu_src2 = (i_src_sel == EXU_SEL_REG) ? i_src2   :
//                   (i_src_sel == EXU_SEL_IMM) ? i_imm    :
//                   (i_src_sel == EXU_SEL_PC4) ? 32'h4    :
//                   (i_src_sel == EXU_SEL_PCI) ? i_imm    : 32'b0;

reg                    [  31:0]         alu_src1                   ;
reg                    [  31:0]         alu_src2                   ;
always @(*) begin
  case(i_src_sel)
    EXU_SEL_REG : begin
      alu_src1 = i_src1;
      alu_src2 = i_src2;
    end
    EXU_SEL_IMM : begin
      alu_src1 = i_src1;
      alu_src2 = i_imm;
    end
    EXU_SEL_PC4 : begin
      alu_src1 = i_pc;
      alu_src2 = 32'h4;
    end
    EXU_SEL_PCI : begin
      alu_src1 = i_pc;
      alu_src2 = i_imm;
    end
  endcase
end


assign o_pc_next =    i_jal             ? i_pc    + i_imm : 
                      i_jalr            ? i_src1  + i_imm : 
                      i_brch            ? i_pc    + i_imm :
                      i_ecall           ? i_src1          :
                      i_mret            ? i_src1          : 
                      i_pc + 4;

ysyx_23060124_ALU exu_alu(
    .src1                              (alu_src1                  ),
    .src2                              (alu_src2                  ),
    .shamt                             (if_unsigned               ),
    .opt                               (alu_opt                   ),
    .res                               (alu_res                   ) 
);

ysyx_23060124_LSU exu_lsu(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .store_src                         (i_src2                    ),
    .alu_res                           (alu_res                   ),
    .exu_opt                           (exu_opt                   ),
    .load_res                          (load_res                  ),
    .i_load                            (i_load                    ),
    .i_store                           (i_store                   ),
  //lsu ->exu sram axi
  //write address channel  
    .M_AXI_AWADDR                      (M_AXI_AWADDR              ),
    .M_AXI_AWVALID                     (M_AXI_AWVALID             ),
    .M_AXI_AWREADY                     (M_AXI_AWREADY             ),
    .M_AXI_AWLEN                       (M_AXI_AWLEN               ),
    .M_AXI_AWSIZE                      (M_AXI_AWSIZE              ),
    .M_AXI_AWBURST                     (M_AXI_AWBURST             ),
    .M_AXI_AWID                        (M_AXI_AWID                ),

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
    .o_pre_ready                       (o_pre_ready               )
);
wire beq, bne, blt, bge, bltu, bgeu;
assign beq = (alu_src1 == alu_src2);
assign bne = (alu_src1 != alu_src2);

assign brch_res = (~i_brch)            ? 1'b0 : 
//TODO: combine BEQ and BNE
                  (exu_opt == BEQ ) ? beq  :
                  (exu_opt == BNE ) ? bne  :
                  (exu_opt == BLT ) ? (alu_res[0] == 1'b1) :
                  (exu_opt == BGE ) ? (alu_res[0] == 1'b0) :
                  (exu_opt == BLTU) ? (alu_res[0] == 1'b1) :
                  (exu_opt == BGEU) ? (alu_res[0] == 1'b0) :
                  1'b0;

assign o_res = i_load ? load_res : alu_res;
assign o_brch = brch_res;

endmodule
