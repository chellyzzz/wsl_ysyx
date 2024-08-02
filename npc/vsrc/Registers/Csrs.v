`include "para_defines.v"

module ysyx_23060124_CSR_RegisterFile (
  input clk,
  input rst,
  input csr_wen,
  input i_ecall,
  input i_mret,
  input [`ysyx_23060124_ISA_WIDTH-1:0] i_pc,
  input [`ysyx_23060124_CSR_ADDR-1:0] csr_addr,
  input [`ysyx_23060124_ISA_WIDTH-1:0] csr_wdata,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mret_a5,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mcause,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mstatus,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mepc,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mtvec,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] csr_rdata
);
// ysyx_23060124
wire [`ysyx_23060124_ISA_WIDTH-1:0] mvendorid , marchid;
assign mvendorid = 32'h79737978;
assign marchid = 32'h23060124;

reg [`ysyx_23060124_ISA_WIDTH-1:0] mcause, mstatus, mepc, mtvec;

always @(posedge clk) begin
    if (csr_wen)begin 
        case (csr_addr)
            `ysyx_23060124_CSR_ADDR'h300: mstatus <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h341: mepc <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h342: mcause <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h305: mtvec <= csr_wdata;
            default: begin
                // $display("csr_addr %h not supported", csr_addr);
            end
        endcase
    end
    if(i_ecall)begin
        mepc <= i_pc;
        mcause <= i_mret_a5;
        mstatus <= {mstatus[31:13], 2'b11, mstatus[10:8],mstatus[3],mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[7] <= mstatus[3];
        // mstatus[12:11] <= 2'b11;
        // mstatus[3] <= 1'b0;
    end
    if(i_mret)begin
        mstatus <={mstatus[31:13], 2'b0, mstatus[10:8],1'b1,mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[3] <= mstatus[7];
        // mstatus[7] <= 1'b1;
        // mstatus[12:11] <= 2'b0;
    end
end

always @(csr_addr) begin
    case (csr_addr)
        `ysyx_23060124_CSR_ADDR'h300: csr_rdata = mstatus;
        `ysyx_23060124_CSR_ADDR'h341: csr_rdata = mepc;
        `ysyx_23060124_CSR_ADDR'h342: csr_rdata = mcause;
        `ysyx_23060124_CSR_ADDR'h305: csr_rdata = mtvec;
        `ysyx_23060124_CSR_ADDR'hf11: csr_rdata = mvendorid;
        `ysyx_23060124_CSR_ADDR'hf12: csr_rdata = marchid;
        default: csr_rdata = 0; // Safe default value to avoid latches
    endcase
end

assign o_mcause = i_ecall ? mcause : 0;
assign o_mstatus = i_ecall || i_mret ? mstatus : 0;
assign o_mepc = i_ecall || i_mret ? mepc : 0;
assign o_mtvec = i_ecall ? mtvec : 0;

endmodule
