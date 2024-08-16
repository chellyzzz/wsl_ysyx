module ysyx_23060124_idu_exu_regs (
    input              [  31:0]         i_pc                       ,
    input                               clock                      ,
    input                               reset                      ,
    // handshake signals
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output                              o_pre_ready                ,
    output                              o_post_valid               ,

    input                               i_rf_valid                 ,
    input              [  31:0]         i_imm                      ,
    input              [  11:0]         i_csr_addr                 ,
    input              [  31:0]         i_src1                     ,
    input              [  31:0]         i_src2                     ,
    input              [   3:0]         i_rd                       ,
    input              [  31:0]         i_csr_rs2                  ,
    input                               i_csr_src_sel              ,
    /***TODO:
    combine wen, csr_wen into one input
    combine csr_addr rd into one input
    ***/
    input              [   2:0]         i_exu_opt                  ,
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
    input                               i_ebreak                   ,
    
    input              [  31:0]         i_mepc                     ,
    input              [  31:0]         i_mtvec                    ,

    output reg         [  31:0]         o_pc                       ,
    output reg         [  31:0]         o_src1                     ,
    output reg         [  31:0]         o_src2                     ,
    output reg         [  31:0]         o_imm                      ,
    output reg         [   1:0]         o_src_sel                  ,

    output reg         [   3:0]         o_rd                       ,
    //
    output reg         [  11:0]         o_csr_addr                 ,
    output reg         [   3:0]         o_exu_opt                  ,
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    output reg                          o_if_unsigned              ,
    output reg                          o_mret                     ,
    output reg                          o_ecall                    ,
    
    output reg                          o_load                     ,
    output reg                          o_store                    ,
    output reg                          o_brch                     ,
    output reg                          o_jal                      ,
    output reg                          o_ebreak                   ,
    //
    output reg                          o_jalr                      
);

reg                                     post_valid                 ;

assign o_post_valid = i_rf_valid && post_valid;
assign o_pre_ready  = i_rf_valid && i_post_ready; 
always @(posedge clock or posedge reset) begin
    if(reset) begin
        post_valid <= 1'b0;   
    end
    else if(i_pre_valid) begin
        post_valid <= 1'b1;
    end
    else if(~i_pre_valid && i_post_ready && o_post_valid)begin
        post_valid <= 1'b0;
    end
end


wire                    [  31:0]         sel_src1                   ;
wire                    [  31:0]         sel_src2                   ;

assign sel_src1 =   i_ecall ? i_mtvec :
                    i_mret  ? i_mepc  :
                    i_src1;

assign sel_src2 =   i_csr_src_sel ? i_csr_rs2 : 
                    i_src2;

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc            <= 32'b0;
        o_src1          <= 32'b0;
        o_src2          <= 32'b0;
        o_imm           <= 32'b0;
        o_src_sel       <= 2'b0;
        o_rd            <= 4'b0;
        o_exu_opt       <= 4'b0;
        o_wen           <= 1'b0;
        o_csr_wen       <= 1'b0;
        o_if_unsigned   <= 1'b0;
        o_mret          <= 1'b0;
        o_ecall         <= 1'b0;
        o_load          <= 1'b0;
        o_store         <= 1'b0;
        o_brch          <= 1'b0;
        o_jal           <= 1'b0;
        o_jalr          <= 1'b0;
        o_ebreak        <= 1'b0;
        //
        o_csr_addr      <= 12'b0;

    end
    else if(i_post_ready && o_post_valid) begin
        o_pc            <= i_pc;
        o_src1          <= sel_src1;
        o_src2          <= sel_src2;
        o_imm           <= i_imm;
        o_src_sel       <= i_src_sel;

        o_rd            <= i_rd;
        o_exu_opt       <=  (i_exu_opt == 3'b000 && i_if_unsigned) ? 4'b1000 :
                            {1'b0, i_exu_opt};
        o_wen           <= i_wen;
        o_csr_wen       <= i_csr_wen;
        o_if_unsigned   <= i_if_unsigned;
        o_mret          <= i_mret;
        o_ecall         <= i_ecall;
        o_load          <= i_load;
        o_store         <= i_store;
        o_brch          <= i_brch;
        o_jal           <= i_jal;
        o_jalr          <= i_jalr;
        o_ebreak        <= i_ebreak;
        o_csr_addr      <= i_csr_addr;

    end
    else if(i_post_ready && ~o_post_valid) begin
        o_pc            <= 32'b0;
        o_src1          <= 32'b0;
        o_src2          <= 32'b0;
        o_imm           <= 32'b0;
        //TODO:
        o_src_sel       <= 2'b0;

        o_rd            <= 4'b0;
        o_exu_opt       <= 4'b0;

        o_wen           <= 1'b0;
        o_csr_wen       <= 1'b0;
        o_if_unsigned   <= 1'b0;
        o_mret          <= 1'b0;
        o_ecall         <= 1'b0;
        o_load          <= 1'b0;
        o_store         <= 1'b0;
        o_brch          <= 1'b0;
        o_jal           <= 1'b0;
        o_jalr          <= 1'b0;
        o_ebreak        <= 1'b0;
        //
        o_csr_addr      <= 12'b0;
    end
end

endmodule   