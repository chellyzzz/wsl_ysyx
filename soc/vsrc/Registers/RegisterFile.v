module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               i_ecall                    ,
    input              [32-1:0]         wdata                      ,
    input              [5-1:0]          waddr                      ,
    input              [5-1:0]          raddr1                     ,
    input              [5-1:0]          raddr2                     ,
    output             [32-1:0]         rdata1                     ,
    output             [32-1:0]         rdata2                     ,
    output             [32-1:0]         o_mret_a5                  ,
    input                               wen                        
);
  reg [32-1:0] rf [16 - 1:1];
  always @(posedge  clock) begin
    if (wen && waddr != 0) rf[waddr[3:0]] <= wdata;
  end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1[3:0]];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2[3:0]];

//TODO: not a5
  assign o_mret_a5 = i_ecall ? rf[15] : 0;

endmodule
