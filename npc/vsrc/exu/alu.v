module ysyx_23060124_ALU (
    input              [32-1:0]         src1                       ,
    input              [32-1:0]         src2                       ,
    input                               if_unsigned                ,
    input              [3-1:0]          opt                        ,
    output reg         [32-1:0]         res                        ,
    output reg                          carry                       
);
/***************parameter***************/
parameter ADD =  3'b000;
parameter SUB =  3'b000;
parameter SLL =  3'b001;
parameter SLT =  3'b010;
parameter SLTU=  3'b011;
parameter XOR =  3'b100;
parameter SRL =  3'b101;
parameter SRA =  3'b101;
parameter OR  =  3'b110;
parameter AND =  3'b111;


  wire [63:0] temp;
  assign temp = {{{32{src1[31]}},src1} >> src2[4:0]};

  always @(*) begin
    case(opt) 
      ADD: begin
        if(if_unsigned) begin
          res = src1 - src2; 
        end
        else begin
          res = src1 + src2; 
        end
      end
      // ysyx_23060124_OPT_EXU_SUB: begin 
      //   if(if_unsigned) begin
      //     {carry,res} = {1'b0, src1} - {1'b0, src2}; end
      //   else begin
      //     {carry,res} = {src1[31], src1} - {src2[31], src2}; 
      //     end
      //   end
      AND: begin res = src1 & src2; end
      OR:  begin res = src1 | src2; end  
      XOR: begin res = src1 ^ src2; end
      SLL: begin res = src1 << src2[4:0]; end
      SRL: begin 
        if(if_unsigned) res = temp[31:0]; 
        else res = src1 >> src2[4:0];
        end
      SLT: begin 
          res =  src1 - src2; 
          //TODO: slt
          // res = ({31srsrc1 < src2) ? 32'b1 : 32'b0;
          res = {31'b0, carry};
        end
      SLTU: begin 
          res = ({1'b0,src1} < {1'b0,src2}) ? 32'b1 : 32'b0;
        end
      default: begin res = 32'b0; end 
    endcase
  end
endmodule
