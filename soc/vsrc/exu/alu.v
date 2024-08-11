module ysyx_23060124_ALU (
    input              [32-1:0]         src1                       ,
    input              [32-1:0]         src2                       ,
    input                               if_unsigned                ,
    input              [3-1:0]          opt                        ,
    output             [32-1:0]         res                        
);
/***************parameter***************/
parameter ADD =  3'b000;
parameter SUB =  3'b000;
parameter SLL =  3'b001;
parameter SLT =  3'b010;
parameter SLTU=  3'b011;
parameter XOR =  3'b100;
parameter SRL =  3'b101;
parameter OR  =  3'b110;
parameter AND =  3'b111;

wire [31:0] add_res;
wire [31:0] and_res;
wire [31:0] or_res;
wire [31:0] xor_res;
wire [31:0] sll_res;
wire [31:0] srl_res;
wire [31:0] slt_res;
wire [31:0] sltu_res;
wire [63:0] temp;

//TODO: combine add and sub
assign temp = {{{32{src1[31]}},src1} >> src2[4:0]};
assign add_res = if_unsigned ? src1 - src2 : src1 + src2;
assign and_res = src1 & src2;
assign or_res  = src1 | src2;
assign xor_res = src1 ^ src2;
assign sll_res = src1 << src2[4:0];
assign srl_res = if_unsigned ? temp[31:0] : src1 >>> src2[4:0];
assign slt_res = (src1[31] != src2[31]) ? (src1[31] ? 32'b1 : 32'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
assign sltu_res = ({1'b0, src1} < {1'b0, src2}) ? 32'b1 : 32'b0;


assign res = (opt == ADD) ? add_res :
             (opt == AND) ? and_res :
             (opt == OR)  ? or_res  :
             (opt == XOR) ? xor_res :
             (opt == SLL) ? sll_res :
             (opt == SRL) ? srl_res :
             (opt == SLT) ? slt_res :
             (opt == SLTU)? sltu_res: 32'b0;

endmodule
