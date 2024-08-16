module ysyx_23060124_ALU (
    input       signed [  31:0]         src1                       ,
    input       signed [  31:0]         src2                       ,
    input                               shamt                      ,
    input              [   3:0]         opt                        ,
    output reg         [  31:0]         res                         
);

/***************parameter***************/
parameter ADD =  4'b0000;
parameter SUB =  4'b1000;
parameter SLL =  4'b0001;
parameter SLT =  4'b0010;
parameter SLTU=  4'b0011;
parameter XOR =  4'b0100;
parameter SRL =  4'b0101;
parameter OR  =  4'b0110;
parameter AND =  4'b0111;

wire                   [  31:0]         add_res                    ;
wire                   [  31:0]         and_res                    ;
wire                   [  31:0]         or_res                     ;
wire                   [  31:0]         xor_res                    ;
wire                   [  31:0]         sll_res                    ;
wire                   [  31:0]         srl_sra_res                ;
wire                   [  31:0]         slt_res                    ;
wire                   [  31:0]         sltu_res                   ;
wire            signed [  31:0]         arithmetic_shift           ;
wire                   [  31:0]         logical_shift              ;
wire                   [  31:0]         minus_res                  ;

assign arithmetic_shift = src1 >>> src2[4:0];
assign logical_shift    = src1 >> src2[4:0];

assign add_res      = src1 + src2;
assign minus_res    = src1 - src2;
assign and_res      = src1 & src2;
assign or_res       = src1 | src2;
assign xor_res      = src1 ^ src2;
assign sll_res      = src1 << src2[4:0];
assign srl_sra_res  = shamt ? arithmetic_shift : logical_shift;
assign slt_res      = (src1[31] != src2[31]) ? (src1[31] ? 32'b1 : 32'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
assign sltu_res     = ({1'b0, src1} < {1'b0, src2}) ? 32'b1 : 32'b0;

always @(*) begin
    case(opt)
        ADD:    res = add_res;
        SUB:    res = minus_res;
        SLL:    res = sll_res;
        SLT:    res = slt_res;
        SLTU:   res = sltu_res;
        XOR:    res = xor_res;
        SRL:    res = srl_sra_res;
        OR:     res  = or_res;
        AND:    res = and_res;
        default: res = 32'b0;
    endcase
end
endmodule
