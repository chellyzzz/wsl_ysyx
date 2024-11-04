module ysyx_23060124_exu_wbu_regs (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    //TODO: combine addr_rd and csr_addr into one input
    //TODO: i_csr_wen adn i_wen into one input
    input                               i_jalr                     ,
    input                               i_ebreak                   ,
    input                               i_mret                     ,
    input                               i_ecall                    ,

    input              [  31:0]         i_res                      ,
    input              [  31:0]         i_pc_next                  ,
    input              [  11:0]         i_csr_addr                 ,
    input              [   3:0]         i_rd_addr                  ,

    output reg         [  31:0]         o_pc_next                  ,
    output reg         [  11:0]         o_csr_addr                 ,
    output reg         [   3:0]         o_rd_addr                  , 
    //
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    //
    output reg                          o_brch                     ,
    output reg                          o_jal                      ,
    output reg                          o_jalr                     ,
    output reg                          o_mret                     ,
    output reg                          o_ecall                    ,
    output reg                          o_ebreak                   ,
    //
    output reg         [  31:0]         o_res                      ,
    // output reg                          o_next                     ,
    input                               i_post_ready               ,
    input                               o_post_valid                
);

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc_next   <= 'b0; 
        o_csr_addr  <= 'b0; 
        o_rd_addr   <= 'b0; 
        o_wen       <= 'b0; 
        o_csr_wen   <= 'b0; 
        o_brch      <= 'b0; 
        o_jal       <= 'b0; 
        o_jalr      <= 'b0; 
        o_mret      <= 'b0; 
        o_ecall     <= 'b0;  
        o_res       <= 'b0; 
        o_ebreak    <= 'b0;
        // o_next      <= 'b0;
    end
    else if(i_post_ready && o_post_valid) begin
        o_pc_next   <= i_pc_next;
        o_csr_addr  <= i_csr_addr;
        o_rd_addr   <= i_rd_addr;
        o_wen       <= i_wen;
        o_csr_wen   <= i_csr_wen;
        o_brch      <= i_brch;
        o_jal       <= i_jal;
        o_jalr      <= i_jalr;
        o_mret      <= i_mret;
        o_ecall     <= i_ecall;
        o_res       <= i_res;
        o_ebreak    <= i_ebreak;
        // o_next      <= 1'b1;
    end
    else if(i_post_ready && ~o_post_valid) begin
        o_pc_next   <= 'b0; 
        o_csr_addr  <= 'b0; 
        o_rd_addr   <= 'b0; 
        o_wen       <= 'b0; 
        o_csr_wen   <= 'b0; 
        o_brch      <= 'b0; 
        o_jal       <= 'b0; 
        o_jalr      <= 'b0; 
        o_mret      <= 'b0; 
        o_ecall     <= 'b0; 
        o_res       <= 'b0; 
        o_ebreak    <= 'b0;
        // o_next      <= 'b0;
    end
end
endmodule   