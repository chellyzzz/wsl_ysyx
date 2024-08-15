module CLINT(
    input                               clock                      ,
    input                               reset                      ,
    //read data channel
    output             [  31:0]         S_AXI_RDATA                ,
    output             [   1:0]         S_AXI_RRESP                ,
    output                              S_AXI_RVALID               ,
    input                               S_AXI_RREADY               ,
    output                              S_AXI_RLAST                ,
    output             [   3:0]         S_AXI_RID                  ,

    //read adress channel
    input                               S_AXI_ARADDR               ,
    input                               S_AXI_ARVALID              ,
    output                              S_AXI_ARREADY              ,
    input              [   3:0]         S_AXI_ARID                 ,
    input              [   7:0]         S_AXI_ARLEN                ,
    input              [   2:0]         S_AXI_ARSIZE               ,
    input              [   1:0]         S_AXI_ARBURST              
);

/**********************regs******************************/
wire                   [  63:0]         reg_mtime                  ;

assign S_AXI_ARREADY    = 1'b1;
assign S_AXI_RRESP      = 2'b0;
assign S_AXI_RVALID     = 1'b1;
assign S_AXI_RLAST      = 1'b1;
assign S_AXI_RID        = 4'b0;


Reg  #(.WIDTH(64), .RESET_VAL(64'b0)) mtime_reg
(
    .clk(clock),
    .rst(reset),
    .din(reg_mtime+1),
    .dout(reg_mtime),
    .wen(1'b1)
);
 
assign S_AXI_RDATA = S_AXI_ARADDR ? reg_mtime[63 : 32] : reg_mtime[31 : 0];

endmodule

module Reg #(WIDTH = 1, RESET_VAL = 0) (
  input clk,
  input rst,
  input [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout,
  input wen
);
  always @(posedge clk) begin
    if (rst) dout <= RESET_VAL;
    else if (wen) dout <= din;
  end

endmodule