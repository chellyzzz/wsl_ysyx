module ysyx_23060124_ALU (
    input              [32-1:0]         src1                       ,
    input              [32-1:0]         src2                       ,
    input                               valid                      ,
    output             [32-1:0]         res                         
);

assign add_res =  src1 + src2;
assign res =  valid ? add_res : 32'b0;

endmodule
