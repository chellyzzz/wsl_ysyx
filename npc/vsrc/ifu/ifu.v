`include "para_defines.v"

module ysyx_23060124_ifu (
  input [`ysyx_23060124_ISA_WIDTH-1:0] i_pc_next,
  input clk,
  input ifu_rst,
  input i_pc_update,
  input i_post_ready,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_ins,
  output [`ysyx_23060124_ISA_WIDTH-1:0] o_pc_next,
  output o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] ins, ins_tmp;

// import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);
// always @(*) begin
//   npc_pmem_read (i_pc, ins, ifu_rst, 4);
// end
reg [`ysyx_23060124_ISA_WIDTH-1:0] reg_pc_next;
reg [`ysyx_23060124_ISA_WIDTH-1:0] pc_next;

ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) next_pc_reg(
  .clk(clk),
  .rst(ifu_rst),
  .din(i_pc_next),
  .dout(pc_next),
  .wen(i_pc_update)
);


SRAM ifu_sram (
    .clk(clk),
    .rst(ifu_rst),
    .raddr(pc_next),
    .ren(1),
    .rdata(ins)
);

always @(posedge clk or negedge ifu_rst) begin
    ins_tmp <= ins;
end
assign o_post_valid = ins != ins_tmp;
// always @(posedge clk or negedge ifu_rst) begin
//     if (~ifu_rst) begin
//         reg_pc_next <= 32'h80000000;
//         o_post_valid <= 1'b1;
//     end else begin
//         if(i_pc_update) begin
//             reg_pc_next <= pc_next;    
//             o_post_valid <= 1'b1;        
//         end
//         else begin
//             o_post_valid <= 1'b0;
//         end
//     end
// end
assign o_ins = i_post_ready && o_post_valid ? ins : o_ins;
assign o_pc_next =  i_post_ready && o_post_valid ? pc_next : o_pc_next;
endmodule
