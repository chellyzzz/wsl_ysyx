`define ysyx_23060124_OPT_WIDTH 13
`define ysyx_23060124_OPT_EXU_ADD  `ysyx_23060124_OPT_WIDTH'b0000_0000_00001
`define ysyx_23060124_OPT_EXU_SUB  `ysyx_23060124_OPT_WIDTH'b0000_0000_00010
`define ysyx_23060124_OPT_EXU_AND  `ysyx_23060124_OPT_WIDTH'b0000_0000_00100
`define ysyx_23060124_OPT_EXU_OR   `ysyx_23060124_OPT_WIDTH'b0000_0000_01000
`define ysyx_23060124_OPT_EXU_XOR  `ysyx_23060124_OPT_WIDTH'b0000_0000_10000
`define ysyx_23060124_OPT_EXU_SLL  `ysyx_23060124_OPT_WIDTH'b0000_0001_00000
`define ysyx_23060124_OPT_EXU_SRL  `ysyx_23060124_OPT_WIDTH'b0000_0010_00000
`define ysyx_23060124_OPT_EXU_SLT  `ysyx_23060124_OPT_WIDTH'b0000_1000_00000
`define ysyx_23060124_OPT_EXU_SW   `ysyx_23060124_OPT_WIDTH'b0000_0000_00000
//LSU_OPT
`define ysyx_23060124_OPT_LSU_LB 4'b1
`define ysyx_23060124_OPT_LSU_LH 4'b11
`define ysyx_23060124_OPT_LSU_LW 4'b1111
`define ysyx_23060124_EXU_SEL_REG 2'b00
`define ysyx_23060124_EXU_SEL_IMM 2'b01
`define ysyx_23060124_EXU_SEL_PC4 2'b10
`define ysyx_23060124_EXU_SEL_PCI 2'b11
//STORE
`define ysyx_23060124_OPT_LSU_SB 4'b1
`define ysyx_23060124_OPT_LSU_SH 4'b11
`define ysyx_23060124_OPT_LSU_SW 4'b1111

//TYPE_EXCPT_RS2
`define ysyx_23060124_RS2_ECALL 5'b00000
`define ysyx_23060124_RS2_EBREAK 5'b00001
`define ysyx_23060124_RS2_MRET 5'b00010
// TYPE_I_OPT
`define ysyx_23060124_TYPE_I 7'b0010011
`define ysyx_23060124_TYPE_I_LOAD 7'b0000011
`define ysyx_23060124_TYPE_JALR 7'b1100111
//ECALL EBREAK
`define ysyx_23060124_TYPE_EBRK 7'b1110011

//TYPE_S_OPT
`define ysyx_23060124_TYPE_S 7'b0100011
//TYPE_R_OPT
`define ysyx_23060124_TYPE_R 7'b0110011
//TYPE_U_OPT
`define ysyx_23060124_TYPE_AUIPC 7'b0010111
`define ysyx_23060124_TYPE_LUI 7'b0110111
// TYPE_J_OPT
`define ysyx_23060124_TYPE_JAL 7'b1101111
//TYPE_B
`define ysyx_23060124_TYPE_B 7'b1100011

//TYPE_I_FUN3
`define ysyx_23060124_FUN3_ADD 3'b000
`define ysyx_23060124_FUN3_SLL 3'b001
`define ysyx_23060124_FUN3_SLT 3'b010
`define ysyx_23060124_FUN3_XOR 3'b100
`define ysyx_23060124_FUN3_SLTU 3'b011
`define ysyx_23060124_FUN3_SRL_SRA 3'b101
`define ysyx_23060124_FUN3_OR  3'b110
`define ysyx_23060124_FUN3_AND 3'b111

//TYPE_I_LOAD_FUN3
`define ysyx_23060124_FUN3_LB 3'b000
`define ysyx_23060124_FUN3_LH 3'b001
`define ysyx_23060124_FUN3_LW 3'b010
`define ysyx_23060124_FUN3_LBU 3'b100
`define ysyx_23060124_FUN3_LHU 3'b101
//TYPE_S_FUN3
`define ysyx_23060124_FUN3_SH 3'b001
`define ysyx_23060124_FUN3_SB 3'b000
`define ysyx_23060124_FUN3_SW 3'b010


//CSRR
`define ysyx_23060124_FUN3_CSRRW 3'b001
`define ysyx_23060124_FUN3_CSRRS 3'b010
`define ysyx_23060124_FUN3_EXCPT 3'b000

//TYPE_I_FUN7
`define ysyx_23060124_FUN7_SRLI 7'b0000000
`define ysyx_23060124_FUN7_SRAI 7'b0100000
//TYPE_R_FUN7
`define ysyx_23060124_FUN7_R_ADD 7'b0000000
`define ysyx_23060124_FUN7_R_SUB 7'b0100000
//BRCH_OPT
`define ysyx_23060124_OPT_BRCH_BEQ `ysyx_23060124_OPT_WIDTH'b0000_0000_00001
`define ysyx_23060124_OPT_BRCH_BGE `ysyx_23060124_OPT_WIDTH'b0000_1000_00000
`define ysyx_23060124_OPT_BRCH_BNE `ysyx_23060124_OPT_WIDTH'b0001_0000_00000
`define ysyx_23060124_OPT_BRCH_BLT `ysyx_23060124_OPT_WIDTH'b0010_0000_00000
`define ysyx_23060124_OPT_BRCH_BLTU `ysyx_23060124_OPT_WIDTH'b0100_0000_00000
`define ysyx_23060124_OPT_BRCH_BGEU `ysyx_23060124_OPT_WIDTH'b1000_0000_00000

module ysyx_23060124_IDU (
    input              [32-1:0]         ins                        ,
    input                               i_rst_n                    ,
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output reg         [32-1:0]         o_imm                      ,
    output reg         [5-1:0]          o_rd                       ,
    output reg         [5-1:0]          o_rs1                      ,
    output reg         [5-1:0]          o_rs2                      ,
    output reg         [12-1:0]         o_csr_addr                 ,
    output reg         [3-1:0]          o_exu_opt                  ,
    output reg         [3-1:0]          o_load_opt                 ,
    output reg         [3-1:0]          o_store_opt                ,
    output reg         [3-1:0]          o_brch_opt                 ,
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    output reg                          o_csrr                     ,
    output reg         [2-1:0]          o_src_sel                  ,
    output reg                          o_if_unsigned              ,
    output                              o_mret                     ,
    output                              o_ecall                    ,
    output                              o_brch                     ,
    output                              o_jal                      ,
    output                              o_jalr                     ,
    output                              o_pre_ready                ,
    output                              o_post_valid                
);
/************************parameter**********************/
//TYPE_B_FUN3
parameter BEQ   = 3'b000;
parameter BNE   = 3'b001;
parameter BLT   = 3'b100;
parameter BGE   = 3'b101;
parameter BLTU  = 3'b110;
parameter BGEU  = 3'b111;
//TYPE_R_FUN3
parameter ADD   =  3'b000;
parameter SUB   =  3'b000;
parameter SLL   =  3'b001;
parameter SLT   =  3'b010;
parameter SLTU  =  3'b011;
parameter XOR   =  3'b100;
parameter SRL   =  3'b101;
parameter SRA   =  3'b101;
parameter OR    =  3'b110;
parameter AND   =  3'b111;

assign o_pre_ready = i_post_ready;
assign o_post_valid = i_pre_valid;

wire [2:0] func3  = ins[14:12];
wire [6:0] opcode  = ins[6:0];
wire [6:0] func7 = ins[31:25];
wire [5-1:0] rs1 = ins[19:15];
wire [5-1:0] rs2 = ins[24:20];
wire [5-1:0] rd  = ins[11:7];
// reg [2:0] id_err; //0:opc_err, 1:funct3_err, 2:funct7_err

// 默认值
assign o_imm = (opcode == `ysyx_23060124_TYPE_I || opcode == `ysyx_23060124_TYPE_I_LOAD) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == `ysyx_23060124_TYPE_LUI || opcode == `ysyx_23060124_TYPE_AUIPC) ? {{0{ins[31]}}, ins[31:12], 12'b0} :
               (opcode == `ysyx_23060124_TYPE_JAL) ? {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0} :
               (opcode == `ysyx_23060124_TYPE_JALR) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == `ysyx_23060124_TYPE_B) ? {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0} :
               (opcode == `ysyx_23060124_TYPE_S) ? {{20{ins[31]}}, ins[31:25], ins[11:7]} :
               32'b0;

assign o_rd = (opcode == `ysyx_23060124_TYPE_I || opcode == `ysyx_23060124_TYPE_I_LOAD ||
               opcode == `ysyx_23060124_TYPE_R || opcode == `ysyx_23060124_TYPE_LUI ||
               opcode == `ysyx_23060124_TYPE_AUIPC || opcode == `ysyx_23060124_TYPE_JAL ||
               opcode == `ysyx_23060124_TYPE_JALR || opcode == `ysyx_23060124_TYPE_EBRK) ? rd : 5'b0;

assign o_rs1 = (opcode == `ysyx_23060124_TYPE_I || opcode == `ysyx_23060124_TYPE_I_LOAD ||
                opcode == `ysyx_23060124_TYPE_R || opcode == `ysyx_23060124_TYPE_JALR ||
                opcode == `ysyx_23060124_TYPE_B || opcode == `ysyx_23060124_TYPE_S ||
                opcode == `ysyx_23060124_TYPE_EBRK) ? rs1 : 5'b0;

assign o_rs2 = (opcode == `ysyx_23060124_TYPE_R || opcode == `ysyx_23060124_TYPE_B ||
                opcode == `ysyx_23060124_TYPE_S) ? rs2 : 5'b0;

assign o_csr_addr = (opcode == `ysyx_23060124_TYPE_EBRK) ? ins[31:20] : 12'b0;

assign o_wen = (opcode == `ysyx_23060124_TYPE_I || opcode == `ysyx_23060124_TYPE_I_LOAD ||
                opcode == `ysyx_23060124_TYPE_R || opcode == `ysyx_23060124_TYPE_LUI ||
                opcode == `ysyx_23060124_TYPE_AUIPC || opcode == `ysyx_23060124_TYPE_JAL ||
                opcode == `ysyx_23060124_TYPE_JALR) ? 1'b1 : 1'b0;

assign o_csr_wen = 1'b0;
assign o_csrr = 1'b0;
// assign id_err = (opcode != `ysyx_23060124_TYPE_I && opcode != `ysyx_23060124_TYPE_I_LOAD &&
//                  opcode != `ysyx_23060124_TYPE_R && opcode != `ysyx_23060124_TYPE_LUI &&
//                  opcode != `ysyx_23060124_TYPE_AUIPC && opcode != `ysyx_23060124_TYPE_JAL &&
//                  opcode != `ysyx_23060124_TYPE_JALR && opcode != `ysyx_23060124_TYPE_B &&
//                  opcode != `ysyx_23060124_TYPE_S && opcode != `ysyx_23060124_TYPE_EBRK) ? 
//                  (i_rst_n ? 3'b001 : 3'b0) : 3'b0;

                 
assign o_if_unsigned =  (opcode == `ysyx_23060124_TYPE_I && func3 == `ysyx_23060124_FUN3_SRL_SRA && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == `ysyx_23060124_TYPE_R && func3 == `ysyx_23060124_FUN3_ADD && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == `ysyx_23060124_TYPE_B) ? 1'b1 :
                        1'b0;

assign o_exu_opt =  (opcode == `ysyx_23060124_TYPE_I)       ? func3 :
                    (opcode == `ysyx_23060124_TYPE_R)       ? func3 :
                    (opcode == `ysyx_23060124_TYPE_LUI)     ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_AUIPC)   ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_JAL)     ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_JALR)    ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_I_LOAD)  ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_S)       ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_B)       ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_EBRK && func3 == `ysyx_23060124_FUN3_CSRRW)    ? 3'b000:
                    (opcode == `ysyx_23060124_TYPE_EBRK && func3 == `ysyx_23060124_FUN3_CSRRS)    ? 3'b110:
                    'b0;

assign o_load_opt =   (opcode == `ysyx_23060124_TYPE_I_LOAD) ? func3 : 3'b0;

assign o_store_opt =  (opcode == `ysyx_23060124_TYPE_S) ? func3 : 3'b0;

assign o_brch_opt =   (opcode == `ysyx_23060124_TYPE_B) ? func3 : 3'b0;
                    
assign o_src_sel =    (opcode == `ysyx_23060124_TYPE_I)       ? `ysyx_23060124_EXU_SEL_IMM:
                      (opcode == `ysyx_23060124_TYPE_R)       ? `ysyx_23060124_EXU_SEL_REG:
                      (opcode == `ysyx_23060124_TYPE_LUI)     ? `ysyx_23060124_EXU_SEL_IMM:
                      (opcode == `ysyx_23060124_TYPE_AUIPC)   ? `ysyx_23060124_EXU_SEL_PCI:
                      (opcode == `ysyx_23060124_TYPE_JAL)     ? `ysyx_23060124_EXU_SEL_PC4:
                      (opcode == `ysyx_23060124_TYPE_JALR)    ? `ysyx_23060124_EXU_SEL_PC4:
                      (opcode == `ysyx_23060124_TYPE_I_LOAD)  ? `ysyx_23060124_EXU_SEL_IMM:
                      (opcode == `ysyx_23060124_TYPE_S)       ? `ysyx_23060124_EXU_SEL_IMM:
                      (opcode == `ysyx_23060124_TYPE_B)       ? `ysyx_23060124_EXU_SEL_REG:
                      (opcode == `ysyx_23060124_TYPE_EBRK && func3 == `ysyx_23060124_FUN3_CSRRW) ? `ysyx_23060124_EXU_SEL_IMM:
                      (opcode == `ysyx_23060124_TYPE_EBRK && func3 == `ysyx_23060124_FUN3_CSRRS) ? `ysyx_23060124_EXU_SEL_REG:
                      'b0;
                    
assign o_ecall = (opcode == `ysyx_23060124_TYPE_EBRK)&&(rs2 == `ysyx_23060124_RS2_ECALL)&&(func3 == `ysyx_23060124_FUN3_EXCPT) ? 'b1: 'b0;
assign o_mret = (opcode == `ysyx_23060124_TYPE_EBRK)&&(rs2 == `ysyx_23060124_RS2_MRET)&&(func3 == `ysyx_23060124_FUN3_EXCPT) ?   'b1: 'b0;

assign o_brch = (opcode == `ysyx_23060124_TYPE_B) ?     'b1: 'b0;
assign o_jal  = (opcode == `ysyx_23060124_TYPE_JAL) ?   'b1: 'b0;
assign o_jalr = (opcode == `ysyx_23060124_TYPE_JALR) ?  'b1: 'b0;


// always @(ins)
// begin
//   o_imm = 32'b0;
//   o_rs1 = 5'b0;
//   o_rs2 = 5'b0;
//   o_csr_addr = 12'b0;
//   o_rd  = 5'b0;
//   o_load_opt = 'b0;
//   o_store_opt = 'b0;
//   o_brch_opt = 0;
//   o_wen = 1'b0;
//   o_csr_wen = 1'b0;
//   o_csrr =  1'b0;
//   id_err = 3'b0;
//   o_if_unsigned = 1'b0;
//   case(opcode)
//     `ysyx_23060124_TYPE_I:      begin o_imm = {{20{ins[31]}},ins[31:20]};       o_rd = rd; o_rs1 = rs1;              o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_I_LOAD: begin o_imm = {{20{ins[31]}},ins[31:20]};       o_rd = rd; o_rs1 = rs1;              o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_R:      begin                                           o_rd = rd; o_rs1 = rs1; o_rs2 = rs2; o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_LUI:    begin o_imm = {{0{ins[31]}},ins[31:12],12'b0};  o_rd = rd;                           o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_AUIPC:  begin o_imm = {{0{ins[31]}},ins[31:12],12'b0};  o_rd = rd;                           o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_JAL:    begin o_imm = {{12{ins[31]}},ins[19:12],ins[20],ins[30:21],1'b0}; o_rd = rd; o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_JALR:   begin o_imm = {{20{ins[31]}},ins[31:20]};       o_rs1 = rs1; o_rd = rd;              o_wen = 1'b1; end
//     `ysyx_23060124_TYPE_B:      begin o_imm = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0}; o_rs1 = rs1; o_rs2 = rs2;  end
//     `ysyx_23060124_TYPE_S:      begin o_imm = {{20{ins[31]}},ins[31:25],ins[11:7]}; o_rs1 = rs1; o_rs2 = rs2; end
//     `ysyx_23060124_TYPE_EBRK:   begin o_csr_addr = ins[31:20];       o_rd = rd; o_rs1 = rs1;; end
//     default: id_err[0] = i_rst_n ? 1'b1 : 1'b0; //opc_err
//   endcase
// end

// always @(ins)
// begin
//   o_exu_opt = `ysyx_23060124_OPT_EXU_ADD;
//   o_src_sel = `ysyx_23060124_EXU_SEL_REG;
//   case(opcode)
//     //TYPE_I
//     `ysyx_23060124_TYPE_I: begin 
//       case(func3)
//         `ysyx_23060124_FUN3_ADD: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_AND: begin o_exu_opt = `ysyx_23060124_OPT_EXU_AND; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_OR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_OR;  o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_XOR: begin o_exu_opt = `ysyx_23060124_OPT_EXU_XOR; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_SLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_SLL: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLL; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_if_unsigned = 1'b0;end
//         `ysyx_23060124_FUN3_SLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLTU; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//         `ysyx_23060124_FUN3_SRL_SRA: begin 
//           case(func7)
//           `ysyx_23060124_FUN7_SRLI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
//           `ysyx_23060124_FUN7_SRAI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b1; end
//           default:id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
//           endcase
//         end
//         default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase
//       end
//     //TYPE_R
//     `ysyx_23060124_TYPE_R: begin
//       case(func3)
//       `ysyx_23060124_FUN3_ADD:begin
//         case(func7)
//         `ysyx_23060124_FUN7_R_ADD: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//         `ysyx_23060124_FUN7_R_SUB: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//         default: id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
//         endcase
//         end
//       `ysyx_23060124_FUN3_SLL: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLL; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_SLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_XOR: begin o_exu_opt = `ysyx_23060124_OPT_EXU_XOR; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_SRL_SRA: begin 
//           case(func7)
//           `ysyx_23060124_FUN7_SRLI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//           `ysyx_23060124_FUN7_SRAI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b0; end
//           default:id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
//           endcase
//         end
//       `ysyx_23060124_FUN3_OR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_OR;  o_src_sel = `ysyx_23060124_EXU_SEL_REG;  o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_AND: begin o_exu_opt = `ysyx_23060124_OPT_EXU_AND; o_src_sel = `ysyx_23060124_EXU_SEL_REG;  o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_SLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b1; end
//       default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase
//       end
//     //TYPE_ELSE
//     `ysyx_23060124_TYPE_LUI:   begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end //x[rd] = imm + x[0]
//     `ysyx_23060124_TYPE_AUIPC: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PCI; o_if_unsigned = 1'b0; end // x[rd] = pc + imm
//     `ysyx_23060124_TYPE_JAL:   begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PC4; o_if_unsigned = 1'b0; end // x[rd] = pc + 4, pc=pc+imm
//     `ysyx_23060124_TYPE_JALR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PC4; o_if_unsigned = 1'b0; end // x[rd] = pc + 4, pc=(x[rs1]+imm)&~1
//     //TYPE_LOAD or STORE
//     `ysyx_23060124_TYPE_I_LOAD: begin
//       case(func3)
//       `ysyx_23060124_FUN3_LB:  begin o_load_opt = `ysyx_23060124_OPT_LSU_LB; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_LH:  begin o_load_opt = `ysyx_23060124_OPT_LSU_LH; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_LW:  begin o_load_opt = `ysyx_23060124_OPT_LSU_LW; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_LBU: begin o_load_opt = `ysyx_23060124_OPT_LSU_LB; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b1; end
//       `ysyx_23060124_FUN3_LHU: begin o_load_opt = `ysyx_23060124_OPT_LSU_LH; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b1; end
//       default: id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase
//     end
//     `ysyx_23060124_TYPE_S: begin 
//       case(func3)
//       `ysyx_23060124_FUN3_SB: begin o_store_opt = `ysyx_23060124_OPT_LSU_SB; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_SH: begin o_store_opt = `ysyx_23060124_OPT_LSU_SH; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       `ysyx_23060124_FUN3_SW: begin o_store_opt = `ysyx_23060124_OPT_LSU_SW; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b0; end
//       default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase
//     end    
//     //TYPE_BRANCH
//     `ysyx_23060124_TYPE_B: begin
//       case(func3)
//       `ysyx_23060124_FUN3_BEQ: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BEQ;   o_if_unsigned = 1'b0; end //rs1==rs2?pc+imm
//       `ysyx_23060124_FUN3_BNE: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BNE;   o_if_unsigned = 1'b0; end //rs1!=rs2?pc+imm
//       `ysyx_23060124_FUN3_BLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BLT;   o_if_unsigned = 1'b0; end //rs1<rs2?pc+imm
//       `ysyx_23060124_FUN3_BGE: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BGE;   o_if_unsigned = 1'b0; end //rs1>=rs2?pc+imm
//       `ysyx_23060124_FUN3_BLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BLTU; o_if_unsigned = 1'b1; end //rs1<rs2?pc+imm
//       `ysyx_23060124_FUN3_BGEU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BGEU; o_if_unsigned = 1'b1; end //rs1>=rs2?pc+imm
//       default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase
//     end
//     // CSR
//     `ysyx_23060124_TYPE_EBRK: begin 
//       case(func3) 
//         `ysyx_23060124_FUN3_CSRRW: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM;  o_csr_wen = 1'b1; o_wen = 1'b1; o_if_unsigned = 1'b0; end
//         `ysyx_23060124_FUN3_CSRRS: begin o_exu_opt = `ysyx_23060124_OPT_EXU_OR; o_src_sel = `ysyx_23060124_EXU_SEL_REG;  o_csr_wen = 1'b1; o_wen = 1'b1;  o_if_unsigned = 1'b0; end
//         `ysyx_23060124_FUN3_EXCPT: begin end
//       default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
//       endcase 
//      end
//     default: id_err[0] = i_rst_n ? 1'b1 : 1'b0; //opc_err
//   endcase
// end

endmodule
