`define ysyx_23060124_OPT_WIDTH 13
`define ysyx_23060124_OPT_EXU_ADD  `ysyx_23060124_OPT_WIDTH'b0000_0000_00001
`define ysyx_23060124_OPT_EXU_SUB  `ysyx_23060124_OPT_WIDTH'b0000_0000_00010
`define ysyx_23060124_OPT_EXU_AND  `ysyx_23060124_OPT_WIDTH'b0000_0000_00100
`define ysyx_23060124_OPT_EXU_OR   `ysyx_23060124_OPT_WIDTH'b0000_0000_01000
`define ysyx_23060124_OPT_EXU_XOR  `ysyx_23060124_OPT_WIDTH'b0000_0000_10000
`define ysyx_23060124_OPT_EXU_SLL  `ysyx_23060124_OPT_WIDTH'b0000_0001_00000
`define ysyx_23060124_OPT_EXU_SRL  `ysyx_23060124_OPT_WIDTH'b0000_0010_00000
`define ysyx_23060124_OPT_EXU_SRA  `ysyx_23060124_OPT_WIDTH'b0000_0100_00000
`define ysyx_23060124_OPT_EXU_SLT  `ysyx_23060124_OPT_WIDTH'b0000_1000_00000
`define ysyx_23060124_OPT_EXU_SW   `ysyx_23060124_OPT_WIDTH'b0000_0000_00000

module ysyx_23060124_ALU (
  input [32-1:0] src1,
  input [32-1:0] src2,
  input if_unsigned,
  input [`ysyx_23060124_OPT_WIDTH-1:0] opt,
  output reg [32-1:0] res,
  output reg carry
);


wire [63:0] temp;
assign temp = {{{32{src1[31]}},src1} >> src2[4:0]};
always @(*) begin
  case(opt) 
    `ysyx_23060124_OPT_EXU_ADD: begin res = src1 + src2;   end
    `ysyx_23060124_OPT_EXU_SUB: begin 
      if(if_unsigned) begin
        {carry,res} = {1'b0, src1} - {1'b0, src2}; end
      else begin
        {carry,res} = {src1[31], src1} - {src2[31], src2}; 
        end
      end
    `ysyx_23060124_OPT_EXU_AND: begin res = src1 & src2; end
    `ysyx_23060124_OPT_EXU_OR:  begin res = src1 | src2; end  
    `ysyx_23060124_OPT_EXU_XOR: begin res = src1 ^ src2; end
    `ysyx_23060124_OPT_EXU_SLL: begin res = src1 << src2[4:0]; end
    `ysyx_23060124_OPT_EXU_SRL: begin res = src1 >> src2[4:0]; end
    `ysyx_23060124_OPT_EXU_SRA: begin res = temp[31:0]; end
    `ysyx_23060124_OPT_EXU_SLT: begin 
      if(if_unsigned) begin
        res = ({1'b0,src1} < {1'b0,src2}) ? 32'b1 : 32'b0; end
      else begin
        {carry,res} = {src1[31], src1} - {src2[31], src2}; 
        res = {31'b0, carry};
         end
      end   
    default: begin res = 32'b0; end 
  endcase
end
endmodule
