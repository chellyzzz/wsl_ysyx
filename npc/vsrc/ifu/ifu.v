`include "para_defines.v"

module ysyx_23060124_ifu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] i_pc,
  input clk,
  input ifu_rst,
  input i_post_ready,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_ins,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_pc_next,
  output reg o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] ins;

// import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);
// always @(*) begin
//   npc_pmem_read (i_pc, ins, ifu_rst, 4);
// end
reg [`ysyx_23060124_ISA_WIDTH-1:0] reg_pc_next;

SRAM ifu_sram (
    .clk(clk),
    .reset(ifu_rst),
    .raddr(i_pc),
    .ren(~o_post_valid),
    .rdata(ins)
);

always @(posedge clk or negedge ifu_rst) begin
    if (~ifu_rst) begin
        reg_pc_next <= 32'h80000000;
        o_post_valid <= 1'b0;
    end else begin
        if(~o_post_valid) begin
            reg_pc_next <= i_pc;    
            o_post_valid <= 1'b1;        
        end
        else begin
            o_post_valid <= 1'b0;
        end
    end
end

assign o_ins = i_post_ready && o_post_valid ? ins : o_ins;
assign o_pc_next = reg_pc_next;
endmodule
