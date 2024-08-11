module ysyx_23060124_EXU(
    input                               clock                      ,
    input                               i_rst_n                    ,
    input              [  31:0]         alu_src1                   ,
    input              [  31:0]         alu_src2                   ,
    input              [  31:0]         agu_src2                   ,
    input                               if_unsigned                ,
    //control signal
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,

    input              [  31:0]         i_pc                       ,
    input              [   2:0]         exu_opt                    ,
    input              [   2:0]         load_opt                   ,
    input              [   2:0]         store_opt                  ,
    input              [   2:0]         brch_opt                   ,
    output             [  31:0]         o_res                      ,
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
    output reg                          o_pre_ready                 
);


/******************parameter******************/
parameter BEQ   = 3'b000;
parameter BNE   = 3'b001;
parameter BLT   = 3'b100;
parameter BGE   = 3'b101;
parameter BLTU  = 3'b110;
parameter BGEU  = 3'b111;


wire                   [  31:0]         alu_res, lsu_res           ;
wire                                    carry, brch_res            ;
wire                                    lsu_post_valid             ;

assign o_post_valid = lsu_post_valid;

always @(posedge  clock or negedge i_rst_n) begin
  if(~i_rst_n) begin
    o_pre_ready <= 1'b1;
  end
  else if(i_pre_valid && ~o_pre_ready) begin
    o_pre_ready <= 1'b1;
  end
  else if(i_pre_valid && o_pre_ready) begin
    o_pre_ready <= 1'b1;
  end
  else o_pre_ready <= o_pre_ready;
end


ysyx_23060124_ALU exu_alu(
    .src1                              (alu_src1                  ),
    .src2                              (alu_src2                  ),
    .if_unsigned                       (if_unsigned               ),
    .opt                               (exu_opt                   ),
    .res                               (alu_res                   ) 
);

ysyx_23060124_AGU exu_agu(
    .src1                              (i_pc                      ),
    .src2                              (agu_src2                  ),
    .res                               (o_pc_next                 ) 
);

ysyx_23060124_LSU exu_lsu(
    .clock                             (clock                     ),
    .i_rst_n                           (i_rst_n                   ),
    .lsu_src2                          (alu_src2                  ),
    .alu_res                           (alu_res                   ),
    .load_opt                          (load_opt                  ),
    .store_opt                         (store_opt                 ),
    .lsu_res                           (lsu_res                   ),
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
    .o_pre_ready                       (o_pre_ready               ),
    .o_post_valid                      (lsu_post_valid            ) 
);


assign brch_res = (~i_brch)            ? 1'b0 : 
//TODO: combine BEQ and BNE
                  (brch_opt == BEQ )   ? (alu_src1 == alu_src2)  :
                  (brch_opt == BNE )   ? (alu_src1 != alu_src2)  :
                  (brch_opt == BLT )   ? (alu_res[0] == 1'b1) :
                  (brch_opt == BGE )   ? (alu_res[0] == 1'b0) :
                  (brch_opt == BLTU)   ? (alu_res[0] == 1'b1) :
                  (brch_opt == BGEU)   ? (alu_res[0] == 1'b0) :
                  1'b0;

assign o_res = i_load ? lsu_res : (i_brch ? {31'b0, brch_res} : alu_res);

endmodule
