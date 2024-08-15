module ysyx_23060124_CSR_RegisterFile (
    input                               clock                      ,
    input                               reset                        ,
    input                               i_csr_wen                  ,
    input                               i_ecall                    ,
    input                               i_mret                     ,
    input              [  31:0]         i_pc                       ,
    
    input              [  11:0]         i_csr_raddr                ,
    output             [  31:0]         o_csr_rdata                ,

    input              [  11:0]         i_csr_waddr                ,
    input              [  31:0]         i_csr_wdata                ,

    output             [  31:0]         o_mepc                     ,
    output             [  31:0]         o_mtvec                    
);
// ysyx_23060124
wire [31:0] mvendorid , marchid;
assign mvendorid    = 32'h79737978;
assign marchid      = 32'h23060124;

reg [31:0] mstatus, mepc, mcause;
reg [31:0] mtvec;

always @(posedge  clock) begin
    if(reset) begin
        mstatus <= 32'b0;
        mepc <= 32'b0;
        mcause <= 32'd11;
        mtvec <= 32'b0;
    end
    else if(i_ecall)begin
        mepc    <= i_pc;
        mcause  <= 32'd11;
        mstatus <= {mstatus[31:13], 2'b11, mstatus[10:8],mstatus[3],mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[7] <= mstatus[3];
        // mstatus[12:11] <= 2'b11;
        // mstatus[3] <= 1'b0;
    end
    else if(i_mret)begin
        mepc <= mepc;
        mcause <= mcause;
        mstatus <={mstatus[31:13], 2'b0, mstatus[10:8],1'b1,mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[3] <= mstatus[7];
        // mstatus[7] <= 1'b1;
        // mstatus[12:11] <= 2'b0;
    end
    else if (i_csr_wen) begin 
        case (i_csr_waddr)
            12'h300: mstatus    <= i_csr_wdata;
            12'h341: mepc       <= i_csr_wdata;
            12'h342: mcause     <= i_csr_wdata;
            12'h305: mtvec      <= i_csr_wdata;
            default: begin
            end
        endcase
    end
    else begin
        mtvec <= mtvec;
        mepc <= mepc;
        mcause <= mcause;
        mstatus <= mstatus;
    end
end

assign o_csr_rdata  = i_csr_raddr == 12'hf11 ? mvendorid :
                      i_csr_raddr == 12'hf12 ? marchid :
                      i_csr_raddr == 12'h300 ? mstatus :
                      i_csr_raddr == 12'h341 ? mepc :
                      i_csr_raddr == 12'h342 ? mcause :
                      i_csr_raddr == 12'h305 ? mtvec : 
                      32'b0;

assign o_mepc       = i_mret    ? mepc  : 32'b0;
assign o_mtvec      = i_ecall   ? mtvec : 32'b0;

endmodule
