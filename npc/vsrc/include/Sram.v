`include "para_defines.v"

module SRAM (
    input clk,
    input rst,
    input [`ysyx_23060124_ISA_WIDTH - 1:0] raddr,
    input ren,
    output reg [`ysyx_23060124_ISA_WIDTH - 1:0] rdata,
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_data;

import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        rdata <= 32'b0;
    end else begin
        if(ren) begin
            rdata <= read_data;
        end
        else rdata <= rdata;
    end
end

always @(*) begin
    npc_pmem_read (raddr, read_data, rst, 4);
end
endmodule

module SRAM4LSU (
    input clk,
    input rst,
    input [`ysyx_23060124_ISA_WIDTH - 1:0] raddr,
    input [`ysyx_23060124_ISA_WIDTH - 1:0] waddr,
    input [`ysyx_23060124_ISA_WIDTH - 1:0] wdata,
    input ren,
    input wen,
    output reg [`ysyx_23060124_ISA_WIDTH - 1:0] rdata,
    output reg o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_data;

import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int len);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);
import "DPI-C" function void store_skip (input int addr);

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        rdata <= 32'b0;
        o_post_valid <= 1'b0;
    end else begin
        if(ren) begin
            rdata <= read_data;
            o_post_valid <= 1'b1;
        end
        else begin
            rdata <= rdata;
            o_post_valid <= 1'b0;
        end
    end
end

always @(*) begin
    npc_pmem_read (raddr, read_data, ren, 4);
end

endmodule