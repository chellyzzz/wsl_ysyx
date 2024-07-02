`include "para_defines.v"

module SRAM (
    input clk,
    input reset,
    input [`ysyx_23060124_ISA_WIDTH - 1:0] raddr,
    input ren,
    output reg valid,
    output reg [`ysyx_23060124_ISA_WIDTH - 1:0] rdata,
    output reg [`ysyx_23060124_ISA_WIDTH - 1:0] o_pc
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_data;

import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int rsize);

always @(posedge clk or negedge reset) begin
    if (~reset) begin
        rdata <= 32'b0;
        valid <= 1'b0;
        o_pc <= 32'h80000000;
    end else begin
        if(ren) begin
            rdata <= read_data;
            valid <= 1'b1;
            o_pc <= raddr;            
        end
        else begin
            valid <= 1'b0;
        end
    end
end

always @(*) begin
    npc_pmem_read (raddr, read_data, reset, 4);
end
endmodule
