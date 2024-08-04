
module ysyx_23060124_IDU (
    input              [32-1:0]         ins                        ,
    input                               i_rst_n                    ,
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output             [32-1:0]         o_imm                      ,
    output             [5-1:0]          o_rd                       ,
    output             [5-1:0]          o_rs1                      ,
    output             [5-1:0]          o_rs2                      ,
    output             [12-1:0]         o_csr_addr                 ,
    output             [3-1:0]          o_exu_opt                  ,
    output             [3-1:0]          o_load_opt                 ,
    output             [3-1:0]          o_store_opt                ,
    output             [3-1:0]          o_brch_opt                 ,
    output                              o_wen                      ,
    output                              o_csr_wen                  ,
    output             [2-1:0]          o_src_sel                  ,
    output                              o_if_unsigned              ,
    output                              o_mret                     ,
    output                              o_ecall                    ,
    output                              o_load                     ,
    output                              o_store                    ,
    output                              o_brch                     ,
    output                              o_jal                      ,
    output                              o_jalr                     ,
    output                              o_pre_ready                ,
    output                              o_post_valid                
);
/************************parameter**********************/
//TYPE_R_FUN3
localparam ADD   =  3'b000;
localparam SUB   =  3'b000;
localparam SLL   =  3'b001;
localparam SLT   =  3'b010;
localparam SLTU  =  3'b011;
localparam XOR   =  3'b100;
localparam SRL_SRA   =  3'b101;
localparam OR    =  3'b110;
localparam AND   =  3'b111;

//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;

localparam TYPE_I      =  7'b0010011;
localparam TYPE_I_LOAD =  7'b0000011;
localparam TYPE_JALR   =  7'b1100111;
localparam TYPE_EBRK  = 7'b1110011;
localparam TYPE_S     = 7'b0100011;
localparam TYPE_R     = 7'b0110011;
localparam TYPE_AUIPC = 7'b0010111;
localparam TYPE_LUI   = 7'b0110111;
localparam TYPE_JAL   = 7'b1101111;
localparam TYPE_B     = 7'b1100011;

//TYPE_I_FUN3
localparam FUN3_SRL_SRA =  3'b101;
//CSRR
localparam FUN3_CSRRW = 3'b001;
localparam FUN3_CSRRS = 3'b010;
localparam FUN3_EXCPT = 3'b000;
//TYPE_EXCPT_RS2
localparam RS2_ECALL   =  5'b00000;
localparam RS2_MRET    =  5'b00010;


assign o_pre_ready = i_post_ready;
assign o_post_valid = i_pre_valid;

wire [2:0] func3  = ins[14:12];
wire [6:0] opcode  = ins[6:0];
wire [6:0] func7 = ins[31:25];
wire [5-1:0] rs1 = ins[19:15];
wire [5-1:0] rs2 = ins[24:20];
wire [5-1:0] rd  = ins[11:7];

assign o_imm = (opcode == TYPE_I || opcode == TYPE_I_LOAD) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == TYPE_LUI || opcode == TYPE_AUIPC) ? {{0{ins[31]}}, ins[31:12], 12'b0} :
               (opcode == TYPE_JAL) ? {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0} :
               (opcode == TYPE_JALR) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == TYPE_B) ? {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0} :
               (opcode == TYPE_S) ? {{20{ins[31]}}, ins[31:25], ins[11:7]} :
               32'b0;

assign o_rd = (opcode == TYPE_I || opcode == TYPE_I_LOAD ||
               opcode == TYPE_R || opcode == TYPE_LUI ||
               opcode == TYPE_AUIPC || opcode == TYPE_JAL ||
               opcode == TYPE_JALR || opcode == TYPE_EBRK) ? rd : 5'b0;

assign o_rs1 = (opcode == TYPE_I || opcode == TYPE_I_LOAD ||
                opcode == TYPE_R || opcode == TYPE_JALR ||
                opcode == TYPE_B || opcode == TYPE_S ||
                opcode == TYPE_EBRK) ? rs1 : 5'b0;

assign o_rs2 = (opcode == TYPE_R || opcode == TYPE_B ||
                opcode == TYPE_S) ? rs2 : 5'b0;

assign o_csr_addr = (opcode == TYPE_EBRK) ? ins[31:20] : 12'b0;

assign o_wen = (opcode == TYPE_I     || opcode == TYPE_I_LOAD ||
                opcode == TYPE_R     || opcode == TYPE_LUI ||
                opcode == TYPE_AUIPC || opcode == TYPE_JAL ||
                opcode == TYPE_JALR  || opcode == TYPE_EBRK) ? 1'b1 : 1'b0;

assign o_csr_wen =  (opcode == TYPE_EBRK ) ? 1'b1 : 1'b0;
                 
assign o_if_unsigned =  (opcode == TYPE_I && func3 == SRL_SRA && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == TYPE_R && func3 == SRL_SRA && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == TYPE_R && func3 == ADD     && func7 == 7'b0100000) ? 1'b1 :
                        1'b0;

assign o_exu_opt =  (opcode == TYPE_I)       ? func3 :
                    (opcode == TYPE_R)       ? func3 :
                    (opcode == TYPE_LUI)     ? 3'b000:
                    (opcode == TYPE_AUIPC)   ? 3'b000:
                    (opcode == TYPE_JAL)     ? 3'b000:
                    (opcode == TYPE_JALR)    ? 3'b000:
                    (opcode == TYPE_I_LOAD)  ? 3'b000:
                    (opcode == TYPE_S)       ? 3'b000:
                    (opcode == TYPE_B && func3[1] == 1'b0)  ? 3'b010:
                    (opcode == TYPE_B && func3[2] == 1'b1)  ? 3'b011:
                    (opcode == TYPE_EBRK && func3 == FUN3_CSRRW)    ? 3'b000:
                    (opcode == TYPE_EBRK && func3 == FUN3_CSRRS)    ? 3'b110:
                    'b0;

assign o_load_opt =   (opcode == TYPE_I_LOAD) ? func3 : 3'b111;

assign o_store_opt =  (opcode == TYPE_S) ? func3 : 3'b111;

assign o_brch_opt =   (opcode == TYPE_B) ? func3 : 3'b010;
                    
assign o_src_sel =    (opcode == TYPE_I)       ? EXU_SEL_IMM:
                      (opcode == TYPE_R)       ? EXU_SEL_REG:
                      (opcode == TYPE_LUI)     ? EXU_SEL_IMM:
                      (opcode == TYPE_AUIPC)   ? EXU_SEL_PCI:
                      (opcode == TYPE_JAL)     ? EXU_SEL_PC4:
                      (opcode == TYPE_JALR)    ? EXU_SEL_PC4:
                      (opcode == TYPE_I_LOAD)  ? EXU_SEL_IMM:
                      (opcode == TYPE_S)       ? EXU_SEL_IMM:
                      (opcode == TYPE_B)       ? EXU_SEL_REG:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRW) ? EXU_SEL_IMM:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRS) ? EXU_SEL_REG:
                      'b0;
                    
assign o_ecall = (opcode == TYPE_EBRK)&&(rs2 == RS2_ECALL) &&(func3 == FUN3_EXCPT) ? 'b1: 'b0;
assign o_mret =  (opcode == TYPE_EBRK)&&(rs2 == RS2_MRET ) &&(func3 == FUN3_EXCPT) ? 'b1: 'b0;
assign o_load  = (opcode == TYPE_I_LOAD) ?  'b1: 'b0;
assign o_store = (opcode == TYPE_S)      ?  'b1: 'b0;
assign o_brch  = (opcode == TYPE_B)      ?  'b1: 'b0;
assign o_jal   = (opcode == TYPE_JAL)    ?  'b1: 'b0;
assign o_jalr  = (opcode == TYPE_JALR)   ?  'b1: 'b0;

endmodule
