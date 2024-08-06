module ysyx_23060124_Reg #(parameter WIDTH = 1, parameter RESET_VAL = 0) (
    input                               clock                      ,
    input                               rst                        ,
    input                               wen                        ,
    input              [WIDTH-1:0]      din                        ,
    output reg         [WIDTH-1:0]      dout                        
);

  always @(posedge  clock or negedge rst) begin
    if (!rst) dout <= RESET_VAL;
    else if (wen) dout <= din;
  end
  
endmodule

