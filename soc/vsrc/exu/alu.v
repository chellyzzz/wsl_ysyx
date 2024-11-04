module ysyx_23060124_ALU (
    input       signed [  31:0]         src1                       ,
    input       signed [  31:0]         src2                       ,
    input              [   9:0]         opt                        ,
    output reg         [  31:0]         res                         
);

/***************parameter***************/
wire                   [  31:0]         add_res                    ;
wire                   [  31:0]         and_res                    ;
wire                   [  31:0]         or_res                     ;
wire                   [  31:0]         xor_res                    ;
wire                   [  31:0]         sll_res                    ;
wire                   [  31:0]         slt_res                    ;
wire                   [  31:0]         sltu_res                   ;
wire            signed [  31:0]         srl_res                    ;
wire                   [  31:0]         sra_res                    ;
wire                   [  31:0]         sub_res                    ;

wire                                    op_add                     ;
wire                                    op_sub                     ;
wire                                    op_and                     ;
wire                                    op_or                      ;
wire                                    op_xor                     ;
wire                                    op_sll                     ;
wire                                    op_slt                     ;
wire                                    op_sltu                    ;
wire                                    op_srl                     ;
wire                                    op_sra                     ;


assign op_add = opt[0];
assign op_sub = opt[1];
assign op_sll = opt[2];
assign op_slt = opt[3];
assign op_sltu= opt[4];
assign op_xor = opt[5];
assign op_srl = opt[6];
assign op_or  = opt[7];
assign op_and = opt[8];
assign op_sra = opt[9];

assign add_res      = src1 + src2;
assign sub_res      = src1 - src2;
assign and_res      = src1 & src2;
assign or_res       = src1 | src2;
assign xor_res      = src1 ^ src2;
assign sll_res      = src1 << src2[4:0];
assign srl_res      = src1 >>> src2[4:0];
assign sra_res      = src1 >> src2[4:0];
assign slt_res      = (src1[31] != src2[31]) ? (src1[31] ? 32'b1 : 32'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
assign sltu_res     = ({1'b0, src1} < {1'b0, src2}) ? 32'b1 : 32'b0;

always_comb begin
    unique case(1'b1)
        op_add:     res = add_res;
        op_sub:     res = sub_res;
        op_slt:     res = slt_res;
        op_sltu:    res = sltu_res;
        op_and:     res = and_res;
        op_or:      res = or_res;
        op_xor:     res = xor_res;
        op_sll:     res = sll_res;
        op_srl:     res = srl_res;
        op_sra:     res = sra_res;
        default:    res = 32'b0;
    endcase
end

endmodule
