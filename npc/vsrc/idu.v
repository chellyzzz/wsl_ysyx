`include "para_defines.v"

module ysyx_23060124_idu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] ins,
  input i_rst_n, //for sim
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_imm,
  output reg [`ysyx_23060124_REG_ADDR-1:0] o_rd,
  output reg [`ysyx_23060124_REG_ADDR-1:0] o_rs1,
  output reg [`ysyx_23060124_REG_ADDR-1:0] o_rs2,
  output reg [`ysyx_23060124_OPT_WIDTH-1:0] o_exu_opt,
  output reg [`ysyx_23060124_OPT_WIDTH-1:0] o_load_opt,
  output reg [`ysyx_23060124_OPT_WIDTH-1:0] o_store_opt,
  output reg [`ysyx_23060124_OPT_WIDTH-1:0] o_brch_opt,
  output reg o_wen,
  output reg [`ysyx_23060124_EXU_SEL_WIDTH-1:0] o_src_sel,
  output o_if_unsigned,
  output o_brch,
  output o_jal,
  output o_jalr
);

wire [2:0] func3  = ins[14:12];
wire [6:0] opcode  = ins[6:0];
wire [6:0] func7 = ins[31:25];
wire [`ysyx_23060124_REG_ADDR-1:0] rs1 = ins[19:15];
wire [`ysyx_23060124_REG_ADDR-1:0] rs2 = ins[24:20];
wire [`ysyx_23060124_REG_ADDR-1:0] rd  = ins[11:7];



reg [2:0] id_err; //0:opc_err, 1:funct3_err, 2:funct7_err

always @(ins)
begin
  o_imm = `ysyx_23060124_ISA_WIDTH'b0;
  o_rs1 = `ysyx_23060124_REG_ADDR'b0;
  o_rs2 = `ysyx_23060124_REG_ADDR'b0;
  o_rd  = `ysyx_23060124_REG_ADDR'b0;
  o_wen = 1'b0;
  id_err = 3'b0;
  o_if_unsigned = 1'b0;
  case(opcode)
    `ysyx_23060124_TYPE_I:      begin o_imm = {{20{ins[31]}},ins[31:20]};       o_rd = rd; o_rs1 = rs1;              o_wen = 1'b1; end
    `ysyx_23060124_TYPE_I_LOAD: begin o_imm = {{20{ins[31]}},ins[31:20]};       o_rd = rd; o_rs1 = rs1;              o_wen = 1'b1; end
    `ysyx_23060124_TYPE_R:      begin                                           o_rd = rd; o_rs1 = rs1; o_rs2 = rs2; o_wen = 1'b1; end
    `ysyx_23060124_TYPE_LUI:    begin o_imm = {{0{ins[31]}},ins[31:12],12'b0};  o_rd = rd;                           o_wen = 1'b1; end
    `ysyx_23060124_TYPE_AUIPC:  begin o_imm = {{0{ins[31]}},ins[31:12],12'b0};  o_rd = rd;                           o_wen = 1'b1; end
    `ysyx_23060124_TYPE_JAL:    begin o_imm = {{12{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0}; o_rd = rd; o_wen = 1'b1; end
    `ysyx_23060124_TYPE_JALR:   begin o_imm = {{12{ins[31]}},ins[31:20]};       o_rs1 = rs1; o_rd = rd;              o_wen = 1'b1; end
    `ysyx_23060124_TYPE_B:      begin o_imm = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0}; o_rs1 = rs1; o_rs2 = rs2;  end
    `ysyx_23060124_TYPE_S:      begin o_imm = {{20{ins[31]}},ins[31:25],ins[11:7]}; o_rs1 = rs1; o_rs2 = rs2; end
    `ysyx_23060124_TYPE_EBRK:   begin  end
    default: id_err[0] = i_rst_n ? 1'b1 : 1'b0; //opc_err
  endcase
end


always @(ins)
begin
  o_exu_opt = `ysyx_23060124_OPT_EXU_ADD;
  o_src_sel = `ysyx_23060124_EXU_SEL_REG;
  case(opcode)
    //TYPE_I
    `ysyx_23060124_TYPE_I: begin 
      case(func3)
        `ysyx_23060124_FUN3_ADD: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_AND: begin o_exu_opt = `ysyx_23060124_OPT_EXU_AND; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_OR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_OR;  o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_XOR: begin o_exu_opt = `ysyx_23060124_OPT_EXU_XOR; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_SLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_SLL: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLL; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
        `ysyx_23060124_FUN3_SLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; o_if_unsigned = 1'b1; end
        `ysyx_23060124_FUN3_SRL_SRA: begin 
          case(func7)
          `ysyx_23060124_FUN7_SRLI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
          `ysyx_23060124_FUN7_SRAI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRA; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
          default:id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
          endcase
        end
        default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
      endcase
      end
    //TYPE_R
    `ysyx_23060124_TYPE_R: begin
      case(func3)
      `ysyx_23060124_FUN3_ADD:begin
        case(func7)
        `ysyx_23060124_FUN7_R_ADD: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
        `ysyx_23060124_FUN7_R_SUB: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
        default: id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
        endcase
        end
      `ysyx_23060124_FUN3_SLL: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLL; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
      `ysyx_23060124_FUN3_SLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
      `ysyx_23060124_FUN3_XOR: begin o_exu_opt = `ysyx_23060124_OPT_EXU_XOR; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
      `ysyx_23060124_FUN3_SRL_SRA: begin 
          case(func7)
          `ysyx_23060124_FUN7_SRLI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRL; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
          `ysyx_23060124_FUN7_SRAI: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SRA; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
          default:id_err[2] = i_rst_n ? 1'b1 : 1'b0; //func7_err
          endcase
        end
      `ysyx_23060124_FUN3_OR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_OR;  o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
      `ysyx_23060124_FUN3_AND: begin o_exu_opt = `ysyx_23060124_OPT_EXU_AND; o_src_sel = `ysyx_23060124_EXU_SEL_REG; end
      `ysyx_23060124_FUN3_SLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SLT; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_if_unsigned = 1'b1; end
      default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
      endcase
      end
    //TYPE_ELSE
    `ysyx_23060124_TYPE_LUI:   begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end //x[rd] = imm + x[0]
    `ysyx_23060124_TYPE_AUIPC: begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PCI; end // x[rd] = pc + imm
    `ysyx_23060124_TYPE_JAL:   begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PC4; end // x[rd] = pc + 4, pc=pc+imm
    `ysyx_23060124_TYPE_JALR:  begin o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_PC4; end // x[rd] = pc + 4, pc=(x[rs1]+imm)&~1
    `ysyx_23060124_TYPE_EBRK:  begin  end
  endcase
end

//lsu
always @(ins)begin
  o_load_opt = 0;
  o_store_opt = 0;
  case(opcode)
  `ysyx_23060124_TYPE_I_LOAD: begin
    case(func3)
    `ysyx_23060124_FUN3_LB: begin o_load_opt = `ysyx_23060124_OPT_LSU_LB; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_LH: begin o_load_opt = `ysyx_23060124_OPT_LSU_LH; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_LW: begin o_load_opt = `ysyx_23060124_OPT_LSU_LW; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_LBU: begin o_load_opt = `ysyx_23060124_OPT_LSU_LBU; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_LHU: begin o_load_opt = `ysyx_23060124_OPT_LSU_LHU; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    default: id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
    endcase
  end
  `ysyx_23060124_TYPE_S: begin 
    case(func3)
    `ysyx_23060124_FUN3_SB: begin o_store_opt = `ysyx_23060124_OPT_LSU_SB; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_SH: begin o_store_opt = `ysyx_23060124_OPT_LSU_SH; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    `ysyx_23060124_FUN3_SW: begin o_store_opt = `ysyx_23060124_OPT_LSU_SW; o_exu_opt = `ysyx_23060124_OPT_EXU_ADD; o_src_sel = `ysyx_23060124_EXU_SEL_IMM; end
    default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
    endcase
  end
  endcase
end
//BRAHCH
always @(ins)begin
  o_brch_opt = 0;
  case(opcode)
    `ysyx_23060124_TYPE_B: begin
      case(func3)
      `ysyx_23060124_FUN3_BEQ: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BEQ; end //rs1==rs2?pc+imm
      `ysyx_23060124_FUN3_BNE: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BNE; end //rs1!=rs2?pc+imm
      `ysyx_23060124_FUN3_BLT: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BLT; end //rs1<rs2?pc+imm
      `ysyx_23060124_FUN3_BGE: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BGE; end //rs1>=rs2?pc+imm
      `ysyx_23060124_FUN3_BLTU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BLTU; o_if_unsigned = 1'b1; end //rs1<rs2?pc+imm
      `ysyx_23060124_FUN3_BGEU: begin o_exu_opt = `ysyx_23060124_OPT_EXU_SUB; o_src_sel = `ysyx_23060124_EXU_SEL_REG; o_brch_opt = `ysyx_23060124_OPT_BRCH_BGEU; o_if_unsigned = 1'b1; end //rs1>=rs2?pc+imm
      default:id_err[1] = i_rst_n ? 1'b1 : 1'b0; //func3_err
      endcase
    end
  endcase
end
assign o_brch = (opcode == `ysyx_23060124_TYPE_B)? 1:0;
assign o_jal  = (opcode == `ysyx_23060124_TYPE_JAL)? 1:0;
assign o_jalr = (opcode == `ysyx_23060124_TYPE_JALR)? 1:0;

always@(ins)begin
    if(i_rst_n & |ins & id_err[0]) $display("\n----------ins decode error, ins = %x, opcode = %b---------------\n", ins, opcode);
    if(i_rst_n & |ins & id_err[1]) $display("\n----------ins decode error, ins = %x, func3 = %b---------------\n", ins, func3 );
    if(i_rst_n & |ins & id_err[2]) $display("\n----------ins decode error, ins = %x, func7 = %b---------------\n", ins, func7 );
    if(i_rst_n & |ins & |id_err ) $finish; //ins docode err.
  end


endmodule
