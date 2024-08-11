module ysyx_23060124_idu_exu_regs (
    input              [  31:0]         i_pc                       ,
    input                               clock                      ,
    input                               reset                      ,
    // handshake signals
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output                              o_pre_ready                ,
    output                              o_post_valid               ,
    //
    input                               i_rf_valid                 ,
    input              [  31:0]         i_imm                      ,
    input              [  11:0]         i_csr_addr                 ,
    input              [  31:0]         src1                       ,
    input              [  31:0]         src2                       ,
    input              [   4:0]         i_rd                       ,
    input              [  31:0]         csr_rs2                    ,
    input                               csr_src_sel                ,
    /***TODO: 
    combine exu_opt, load_opt, store_opt, brch_opt into one input
    combine wen, csr_wen into one input 
    combine csr_addr rd into one input
    ***/
    input              [   2:0]         i_exu_opt                  ,
    input              [   2:0]         i_load_opt                 ,
    input              [   2:0]         i_store_opt                ,
    input              [   2:0]         i_brch_opt                 ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    input              [   1:0]         i_src_sel                  ,
    input                               i_if_unsigned              ,
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    input                               i_fence_i                  ,

    output reg         [  31:0]         o_pc_next                  ,
    output reg         [  31:0]         o_alu_rs1                  ,
    output reg         [  31:0]         o_alu_rs2                  ,
    output reg         [  31:0]         o_agu_rs2                  ,
    output reg         [   4:0]         o_rd                       ,
    output reg         [   2:0]         o_exu_opt                  ,
    output reg         [   2:0]         o_load_opt                 ,
    output reg         [   2:0]         o_store_opt                ,
    output reg         [   2:0]         o_brch_opt                 ,
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    output reg                          o_if_unsigned              ,
    output reg                          o_mret                     ,
    output reg                          o_ecall                    ,
    output reg                          o_load                     ,
    output reg                          o_store                    ,
    output reg                          o_brch                     ,
    output reg                          o_jal                      ,
    output reg                          o_jalr                     
);

//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;

wire                   [  31:0]         alu_src1                   ;
wire                   [  31:0]         alu_src2                   ;
wire                   [32-1:0]         sel_src2                   ;
wire                   [  31:0]         agu_src2                   ;
assign sel_src2 = csr_src_sel ? csr_rs2 : src2;
assign alu_src1 = (i_src_sel == EXU_SEL_REG) ? src1 :
                  (i_src_sel == EXU_SEL_IMM) ? src1 :
                  (i_src_sel == EXU_SEL_PC4) ? i_pc :
                  (i_src_sel == EXU_SEL_PCI) ? i_pc : 32'b0;

assign alu_src2 = (i_src_sel == EXU_SEL_REG) ? sel_src2 :
                  (i_src_sel == EXU_SEL_IMM) ? i_imm :
                  (i_src_sel == EXU_SEL_PC4) ? 32'h4 :
                  (i_src_sel == EXU_SEL_PCI) ? i_imm : 32'b0;

assign agu_src2 =   i_brch ? i_imm :
                    i_jal  ? i_imm  :
                    i_jalr ? src1   :
                    32'h4;

reg                                     pre_ready                  ;
reg                                     post_valid                 ;

assign o_post_valid = i_rf_valid ? post_valid : 1'b0;
assign o_pre_ready  = i_rf_valid ? pre_ready  : 1'b0; 
always @(posedge clock or posedge reset) begin
    if(reset) begin
        pre_ready <= 1'b1;
        post_valid <= 1'b0;   
    end
    else if(i_pre_valid && i_rf_valid) begin
        pre_ready <= 1'b1;  
        post_valid <= 1'b1;
    end
    else begin
        post_valid <= post_valid;
        pre_ready <= pre_ready;
    end
end

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc_next <= 32'b0;
        o_alu_rs1 <= 32'b0;
        o_alu_rs2 <= 32'b0;
        o_agu_rs2 <= 32'b0;
        o_rd <= 5'b0;
        o_exu_opt <= 3'b0;
        o_load_opt <= 3'b0;
        o_store_opt <= 3'b0;
        o_brch_opt <= 3'b0;
        o_wen <= 1'b0;
        o_csr_wen <= 1'b0;
        o_if_unsigned <= 1'b0;
        o_mret <= 1'b0;
        o_ecall <= 1'b0;
        o_load <= 1'b0;
        o_store <= 1'b0;
        o_brch <= 1'b0;
        o_jal <= 1'b0;
        o_jalr <= 1'b0;
    end
    else if(i_rf_valid) begin
        o_pc_next <= i_pc;
        o_alu_rs1 <= alu_src1;      
        o_alu_rs2 <= alu_src2;   
        o_agu_rs2 <= agu_src2;
        o_rd <= i_rd;
        o_exu_opt <= i_exu_opt;
        o_load_opt <= i_load_opt;
        o_store_opt <= i_store_opt;
        o_brch_opt <= i_brch_opt;
        o_wen <= i_wen;
        o_csr_wen <= i_csr_wen;
        o_if_unsigned <= i_if_unsigned;
        o_mret <= i_mret;
        o_ecall <= i_ecall;
        o_load <= i_load;
        o_store <= i_store;
        o_brch <= i_brch;
        o_jal <= i_jal;
        o_jalr <= i_jalr;
    end

end
endmodule   