`include "para_defines.v"

module ysyx_23060124_csr_RegisterFile (
  input clk,
  input rst,
  input csr_wen,
  input i_ecall,
  input i_mret,
  input [`ysyx_23060124_ISA_WIDTH-1:0] i_pc,
  input [`ysyx_23060124_CSR_ADDR-1:0] csr_addr,
  input [`ysyx_23060124_ISA_WIDTH-1:0] csr_wdata,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] i_mret_a5,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mcasue,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mstatus,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mepc,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] o_mtvec,
  output reg [`ysyx_23060124_ISA_WIDTH-1:0] csr_rdata
);

reg [`ysyx_23060124_ISA_WIDTH-1:0] mcause, mstatus, mepc, mtvec;

always @(posedge clk) begin
    if (csr_wen)begin 
        case (csr_addr)
            `ysyx_23060124_CSR_ADDR'h300: mstatus <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h341: mepc <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h342: mcause <= csr_wdata;
            `ysyx_23060124_CSR_ADDR'h305: mtvec <= csr_wdata;
        // default: $finish
        endcase
    end
    if(i_ecall)begin
        mepc <= i_pc;
        mcause <= i_mret_a5;
        mstatus[7] <= mstatus[3];
        mstatus[12:11] <= 2'b11;
        mstatus[3] <= 1'b0;
    end
    if(i_mret)begin
        mstatus[3] <= mstatus[7];
        mstatus[7] <= 1'b1;
        mstatus[12:11] <= 2'b0;
    end
end

always @(csr_addr) begin
    case (csr_addr)
        `ysyx_23060124_CSR_ADDR'h300: csr_rdata = mstatus;
        `ysyx_23060124_CSR_ADDR'h341: csr_rdata = mepc;
        `ysyx_23060124_CSR_ADDR'h342: csr_rdata = mcause;
        `ysyx_23060124_CSR_ADDR'h305: csr_rdata = mtvec;
        default: csr_rdata = 0; // Safe default value to avoid latches
    endcase
end

assign o_mcause = i_ecall ? mcause : 0;
assign o_mstatus = i_ecall || i_mret ? mstatus : 0;
assign o_mepc = i_ecall || i_mret ? mepc : 0;
assign o_mtvec = i_ecall ? mtvec : 0;

// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, 0) mepc(
//   .clk(clk),
//   .rst(i_rst_pcu),
//   .din(w_mepc),
//   .dout(r_mepc),
//   .wen(mepc_wen)
// );
// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, 0) mcause(
//   .clk(clk),
//   .rst(i_rst_pcu),
//   .din(w_mcause),
//   .dout(r_mcause),
//   .wen(mcause_wen)
// );
// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, 0) mstatus(
//   .clk(clk),
//   .rst(i_rst_pcu),
//   .din(w_mstatus),
//   .dout(r_mstatus),
//   .wen(mstatus_wen)
// );
// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, 0) mtvec(
//   .clk(clk),
//   .rst(i_rst_pcu),
//   .din(w_mtvec),
//   .dout(r_mtvec),
//   .wen(mtvec_wen)
// );
endmodule
