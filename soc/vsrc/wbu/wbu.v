module ysyx_23060124_WBU (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_pre_valid                ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input              [32 - 1:0]       i_pc                       ,
  // ecall and mret
    input              [32 - 1:0]       i_mepc                     ,
    input              [32 - 1:0]       i_mtvec                    ,
  // 
    input              [32 - 1:0]       i_rs1                      ,
    input              [32 - 1:0]       i_imm                      ,
    input              [32 - 1:0]       i_res                      ,
    output             [32 - 1:0]       o_pc_next                  ,
    output             [32 - 1:0]       o_rd_wdata                 ,
    output             [32 - 1:0]       o_csr_rd                   ,
    output reg                          o_pre_ready                ,
    output                              o_wbu_wen                  ,
    output                              o_wbu_csr_wen              ,
    output                              o_pc_update                 
);

//TODO: res and pc+Imm
wire [32 - 1:0] pc;
wire [32 - 1:0] res;
wire [32 - 1:0] rs1;
wire [32 - 1:0] imm;
wire brch;
wire jal;
wire jalr;
wire mret;
wire ecall;
wire [32 - 1:0] mtvec;
wire [32 - 1:0] mepc;

assign pc            =  i_pre_valid && o_pre_ready ? i_pc        :  'b0;
assign res           =  i_pre_valid && o_pre_ready ? i_res       :  'b0;
assign rs1           =  i_pre_valid && o_pre_ready ? i_rs1       :  'b0;
assign imm           =  i_pre_valid && o_pre_ready ? i_imm       :  'b0;
assign brch          =  i_pre_valid && o_pre_ready ? i_brch      :  'b0;
assign jal           =  i_pre_valid && o_pre_ready ? i_jal       :  'b0;
assign jalr          =  i_pre_valid && o_pre_ready ? i_jalr      :  'b0;
assign mret          =  i_pre_valid && o_pre_ready ? i_mret      :  'b0;
assign ecall         =  i_pre_valid && o_pre_ready ? i_ecall     :  'b0;
assign mtvec         =  i_pre_valid && o_pre_ready ? i_mtvec     :  'b0;
assign mepc          =  i_pre_valid && o_pre_ready ? i_mepc      :  'b0;
assign o_wbu_wen     =  i_pre_valid && o_pre_ready ? i_wen       :  1'b0;
assign o_wbu_csr_wen =  i_pre_valid && o_pre_ready ? i_csr_wen   :  1'b0;

assign o_rd_wdata = res;

assign o_csr_rd  = res;

assign o_pc_next =    jal ? (pc + imm) : 
                      (jalr ? (rs1 + imm) : 
                      (brch && res[0] ? pc + imm : 
                      (ecall ? mtvec :
                      (mret ? mepc : pc + 4))));

always @(posedge clock or posedge reset) begin
  if(reset) begin
    o_pre_ready <= 1'b1;
  end
end
assign o_pc_update = i_pre_valid && o_pre_ready;

endmodule
