
module ysyx_23060124_IDU (
    input                               clock                      ,
    input              [  31:2]         ins                        ,
    input                               reset                      ,

    output             [  31:0]         o_imm                      ,
    output             [   3:0]         o_rd                       ,
    output             [   3:0]         o_rs1                      ,
    output             [   3:0]         o_rs2                      ,
    output             [  11:0]         o_csr_addr                 ,
    output             [   2:0]         o_exu_opt                  ,

    output                              o_wen                      ,
    output                              o_csr_wen                  ,
    output             [   1:0]         o_src_sel                  ,
    output                              o_if_unsigned              ,
    output                              o_mret                     ,
    output                              o_ecall                    ,
    output                              o_load                     ,
    output                              o_store                    ,
    output                              o_brch                     ,
    output                              o_jal                      ,
    output                              o_jalr                     ,
    output                              o_ebreak                   ,
    output                              o_fence_i                  
);
/************************parameter**********************/
//TYPE_R_FUN3
localparam                              ADD   =  3'b000            ;
localparam                              SUB   =  3'b000            ;
localparam                              SLL   =  3'b001            ;
localparam                              SLT   =  3'b010            ;
localparam                              SLTU  =  3'b011            ;
localparam                              XOR   =  3'b100            ;
localparam                              SRL_SRA   =  3'b101        ;
localparam                              OR    =  3'b110            ;
localparam                              AND   =  3'b111            ;

//EXU_SRC_SEL
localparam                              EXU_SEL_REG = 2'b00        ;
localparam                              EXU_SEL_IMM = 2'b01        ;
localparam                              EXU_SEL_PC4 = 2'b10        ;
localparam                              EXU_SEL_PCI = 2'b11        ;

localparam                              TYPE_I       =  5'b00100 ;
localparam                              TYPE_I_LOAD  =  5'b00000 ;
localparam                              TYPE_JALR    =  5'b11001 ;
localparam                              TYPE_EBRK    =  5'b11100 ;
localparam                              TYPE_S       =  5'b01000 ;
localparam                              TYPE_R       =  5'b01100 ;
localparam                              TYPE_AUIPC   =  5'b00101 ;
localparam                              TYPE_LUI     =  5'b01101 ;
localparam                              TYPE_JAL     =  5'b11011 ;
localparam                              TYPE_B       =  5'b11000 ;
localparam                              TYPE_FENCE   =  5'b00011 ;
//TYPE_I_FUN3
localparam                              FUN3_SRL_SRA =  3'b101     ;
//CSRR
localparam                              FUN3_CSRRW = 3'b001        ;
localparam                              FUN3_CSRRS = 3'b010        ;
localparam                              FUN3_EXCPT = 3'b000        ;
//TYPE_EXCPT_RS2
localparam                              RS2_ECALL   =  5'b00000    ;
localparam                              RS2_MRET    =  5'b00010    ;

wire [2:0] func3    = ins[14:12];
wire [4:0] opcode   = ins[6:2];
wire [6:0] func7    = ins[31:25];
wire [3:0] rs1      = ins[18:15];
wire [3:0] rs2      = ins[23:20];
wire [3:0] rd       = ins[10:7];

wire TYPEI       = (opcode == TYPE_I         );
wire TYPEI_LOAD  = (opcode == TYPE_I_LOAD    );
wire TYPER       = (opcode == TYPE_R         );     
wire TYPELUI     = (opcode == TYPE_LUI       );   
wire TYPEAUIPC   = (opcode == TYPE_AUIPC     ); 
wire TYPEJAL     = (opcode == TYPE_JAL       );   
wire TYPEJALR    = (opcode == TYPE_JALR      );  
wire TYPES       = (opcode == TYPE_S         );     
wire TYPEB       = (opcode == TYPE_B         );     

assign o_imm = (TYPEI || TYPEI_LOAD) ? {{20{ins[31]}}, ins[31:20]} :
               (TYPELUI || TYPEAUIPC) ? {ins[31:12], 12'b0} :
               (TYPEJAL) ? {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0} :
               (TYPEJALR) ? {{20{ins[31]}}, ins[31:20]} :
               (TYPEB) ? {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0} :
               (TYPES) ? {{20{ins[31]}}, ins[31:25], ins[11:7]} :
               32'b0;

assign o_rd = rd;

assign o_rs1 = (TYPEAUIPC || TYPELUI ||TYPEJAL) ? 4'b0 : rs1;

assign o_rs2 = (TYPER || TYPEB || TYPES) ? rs2 : 4'b0;

//TODO: TYPE_I
assign o_csr_addr = (opcode == TYPE_EBRK) ? ins[31:20] : 12'b0;

assign o_wen        = (TYPES || TYPEB || opcode == TYPE_FENCE) ? 1'b0 : 1'b1;

assign o_csr_wen    = (opcode == TYPE_EBRK && |func3);
              
assign o_if_unsigned =  (TYPEI && func3 == SRL_SRA && func7[5]) ? 1'b1 :
                        (TYPER && func3 == SRL_SRA && func7[5]) ? 1'b1 :
                        (TYPER && func3 == ADD     && func7[5]) ? 1'b1 :
                        1'b0;

assign o_exu_opt =  (TYPELUI)     ? 3'b000:
                    (TYPEAUIPC)   ? 3'b000:
                    (TYPEJAL)     ? 3'b000:
                    (opcode == TYPE_EBRK && func3 == FUN3_CSRRS)    ? 3'b110:
                    func3;

assign o_src_sel =    (TYPEI)       ? EXU_SEL_IMM:
                      (TYPER)       ? EXU_SEL_REG:
                      (TYPELUI)     ? EXU_SEL_IMM:
                      (TYPEAUIPC)   ? EXU_SEL_PCI:
                      (TYPEJAL)     ? EXU_SEL_PC4:
                      (TYPEJALR)    ? EXU_SEL_PC4:
                      (TYPEI_LOAD)  ? EXU_SEL_IMM:
                      (TYPES)       ? EXU_SEL_IMM:
                      (TYPEB)       ? EXU_SEL_REG:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRW) ? EXU_SEL_IMM:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRS) ? EXU_SEL_REG:
                      'b0;
                    
assign o_ecall      = (opcode == TYPE_EBRK && func3 == 3'b0 && rs2[1:0] == 2'b00);
assign o_mret       = (opcode == TYPE_EBRK && func3 == 3'b0 && rs2[1:0] == 2'b10);

assign o_load       = (TYPEI_LOAD) ?  'b1: 'b0;
assign o_store      = (TYPES)      ?  'b1: 'b0;
assign o_brch       = (TYPEB)      ?  'b1: 'b0;
assign o_jal        = (TYPEJAL)    ?  'b1: 'b0;
assign o_jalr       = (TYPEJALR)   ?  'b1: 'b0;
assign o_fence_i    = (opcode == TYPE_FENCE)&&(func3 == 3'b001) ? 'b1: 'b0;
assign o_ebreak     = (opcode == TYPE_EBRK && func3 == 3'b0 && rs2[1:0] == 2'b01);

endmodule
