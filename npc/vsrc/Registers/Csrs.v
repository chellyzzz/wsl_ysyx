 

module ysyx_23060124_CSR_RegisterFile (
  input clk,
  input rst,
  input csr_wen,
  input i_ecall,
  input i_mret,
  input [32-1:0] i_pc,
  input [12-1:0] csr_addr,
  input [32-1:0] csr_wdata,
  input [32 - 1:0] i_mret_a5,
  output reg [32-1:0] o_mcause,
  output reg [32-1:0] o_mstatus,
  output reg [32-1:0] o_mepc,
  output reg [32-1:0] o_mtvec,
  output reg [32-1:0] csr_rdata
);
// ysyx_23060124
wire [32-1:0] mvendorid , marchid;
assign mvendorid = 32'h79737978;
assign marchid = 32'h23060124;

reg [32-1:0] mcause, mstatus, mepc, mtvec;

always @(posedge clk) begin
    if (csr_wen)begin 
        case (csr_addr)
            12'h300: mstatus <= csr_wdata;
            12'h341: mepc <= csr_wdata;
            12'h342: mcause <= csr_wdata;
            12'h305: mtvec <= csr_wdata;
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
        12'h300: csr_rdata = mstatus;
        12'h341: csr_rdata = mepc;
        12'h342: csr_rdata = mcause;
        12'h305: csr_rdata = mtvec;
        12'hf11: csr_rdata = mvendorid;
        12'hf12: csr_rdata = marchid;
        default: csr_rdata = 0; // Safe default value to avoid latches
    endcase
end

assign o_mcause = i_ecall ? mcause : 0;
assign o_mstatus = i_ecall || i_mret ? mstatus : 0;
assign o_mepc = i_ecall || i_mret ? mepc : 0;
assign o_mtvec = i_ecall ? mtvec : 0;

endmodule
