`include "para_defines.v"

module top
(
  input clk,
  input i_rst_n
);

wire rst_n_sync;

ysyx_23060124_stdrst u_stdrst(
  .i_clk        (clk        ),
  .i_rst_n      (i_rst_n      ),
  .o_rst_n_sync (rst_n_sync   )
);

ysyx_23060124_CPU CPU
(
  .S_AXI_ACLK(clk),
  .S_AXI_ARESETN(rst_n_sync)
);

// SRAM SRAM1
// (
//     .clk(clk),
//     .rst_n(i_rst_n),
//     .raddr(alu_res),
//     .waddr(alu_res),
//     .wdata(lsu_src2),
//     .ren(|load_opt & i_pre_valid),
//     .wen(|store_opt),
//     .store_opt(store_opt),
//     .rdata(read_res),
//     .i_pre_valid(i_pre_valid),
//     .o_post_valid(o_post_valid)
// );
endmodule