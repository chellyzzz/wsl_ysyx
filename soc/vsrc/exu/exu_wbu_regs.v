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
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input                               i_mepc                     ,
    input                               i_mtvec                    ,
    input                               i_rs1                      ,
    input                               i_pc                       ,
    input                               i_imm                      ,
    input                               i_res                      ,
    input                               o_pc_next                  ,
    input                               o_pc_update                ,
    input                               o_rd_wdata                 ,
    input                               o_csr_rd                   ,
    input                               o_wbu_wen                  ,
    input                               o_wbu_csr_wen               


);

//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;



always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc_next <= 32'b0;
        o_alu_rs1 <= 32'b0;
        o_alu_rs2 <= 32'b0;
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
    else begin
        o_pc_next <= i_pc;
        o_alu_rs1 <= alu_src1;      
        o_alu_rs2 <= alu_src2;   
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