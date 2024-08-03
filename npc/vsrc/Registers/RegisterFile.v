 

module ysyx_23060124_RegisterFile (
  input clk,
  input i_rst_n,
  input i_ecall,
  input i_mret,
  input [32-1:0] wdata,
  input [5-1:0] waddr,
  input [5-1:0] raddr1,
  input [5-1:0] raddr2,
  output [32-1:0] rdata1,
  output [32-1:0] rdata2,
  output [32-1:0] o_mret_a5,
  input wen,
  output a0_zero
);
  reg [32-1:0] rf [32 - 1:0];

  integer i;

  always @(posedge clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
    for (i = 0; i < 32; i = i + 1) rf[i] <= 0;
    end
    else if (wen && waddr != 0) rf[waddr] <= wdata;
  end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2];

  assign a0_zero = ~|rf[10]; 
  assign o_mret_a5 = i_ecall ? rf[15] : 0;

endmodule