`include "para_defines.v"
module ysyx_23060124_alu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] src1,
  input [`ysyx_23060124_ISA_WIDTH-1:0] src2,
  input if_unsigned,
  input [`ysyx_23060124_OPT_WIDTH-1:0] opt,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] res,
  output reg carry
);


always @(src1 or src2 or opt) begin
  res = `ysyx_23060124_ISA_WIDTH'b0;
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
    `ysyx_23060124_OPT_EXU_SRA: begin res = {{{32{src1[31]}},src1} >> src2[4:0]}[31:0]; end
    `ysyx_23060124_OPT_EXU_SLT: begin 
      if(if_unsigned) begin
        res = ({1'b0,src1} < {1'b0,src2}) ? 32'b1 : 32'b0; end
      else begin
        {carry,res} = {src1[31], src1} - {src2[31], src2}; 
        res = {31'b0, carry};
         end
      end   
    default: begin res = `ysyx_23060124_ISA_WIDTH'b0; end 
  endcase
end
endmodule
