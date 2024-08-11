module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_ecall                    ,
    input              [32-1:0]         wdata                      ,
    input              [5-1:0]          waddr                      ,
    //
    input                               idu_wen                    ,
    input              [5-1:0]          idu_waddr                  ,
    output                              idu_vaild                  ,
    // 
    input              [5-1:0]          raddr1                     ,
    input              [5-1:0]          raddr2                     ,
    output             [32-1:0]         rdata1                     ,
    output             [32-1:0]         rdata2                     ,
    output             [32-1:0]         o_mret_a5                  ,
    input                               wen                        
);
reg [32-1:0] rf [16 - 1:1];
reg                    [  15:0]         scoreboard                 ;
  always @(posedge  clock) begin
    if(reset) begin
      scoreboard[15:0] <= {16{1'b1}};
    end
    if (wen && waddr != 0) begin
      rf[waddr[3:0]] <= wdata;
      scoreboard[waddr[3:0]] <= 1'b1;
    end
    else if(idu_wen && idu_waddr!= 0) begin
      scoreboard[idu_waddr[3:0]] <= 1'b0;
    end
  end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1[3:0]];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2[3:0]];
  assign idu_vaild = scoreboard[raddr1[3:0]] && scoreboard[raddr2[3:0]];
//TODO: not a5
  assign o_mret_a5 = i_ecall ? rf[15] : 0;

endmodule
