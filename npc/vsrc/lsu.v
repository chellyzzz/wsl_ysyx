`include "para_defines.v"

module ysyx_23060124_lsu(
  input [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_src2,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] alu_res,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] load_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] store_opt,
  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_res
);
reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_res;

import "DPI-C" function void npc_pmem_read (input int raddr, input int if_mtrace, output int rdata, input bit ren, input int rsize);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);
//load
always @(load_opt) begin
    case(load_opt)
    `ysyx_23060124_OPT_LSU_LB: begin  npc_pmem_read(alu_res, 1, read_res, |load_opt, 1); end
    `ysyx_23060124_OPT_LSU_LH: begin  npc_pmem_read(alu_res, 1, read_res, |load_opt, 2); end
    `ysyx_23060124_OPT_LSU_LW: begin  npc_pmem_read(alu_res, 1, read_res, |load_opt, 4); end
    `ysyx_23060124_OPT_LSU_LBU: begin  npc_pmem_read(alu_res, 1, read_res, |load_opt, 1); end
    `ysyx_23060124_OPT_LSU_LHU: begin  npc_pmem_read(alu_res, 1, read_res, |load_opt, 2); end
    default: begin read_res = `ysyx_23060124_ISA_WIDTH'b0; end
    endcase
end

always @(read_res) begin
    case(load_opt)
    `ysyx_23060124_OPT_LSU_LB: begin lsu_res = {{24{read_res[7]}}, read_res[7:0]}; end
    `ysyx_23060124_OPT_LSU_LH: begin lsu_res = {{16{read_res[15]}}, read_res[15:0]}; end
    `ysyx_23060124_OPT_LSU_LW: begin lsu_res =read_res; end
    `ysyx_23060124_OPT_LSU_LBU: begin lsu_res = read_res; end
    `ysyx_23060124_OPT_LSU_LHU: begin lsu_res = read_res; end
    default: begin lsu_res = `ysyx_23060124_ISA_WIDTH'b0; end
    endcase
end
//store
always @(store_opt) begin
    case(store_opt)
    `ysyx_23060124_OPT_LSU_SB: begin  npc_pmem_write(alu_res, lsu_src2, |store_opt, 1); end
    `ysyx_23060124_OPT_LSU_SH: begin  npc_pmem_write(alu_res, lsu_src2, |store_opt, 2); end
    `ysyx_23060124_OPT_LSU_SW: begin  npc_pmem_write(alu_res, lsu_src2, |store_opt, 4); end
    endcase
end

endmodule
