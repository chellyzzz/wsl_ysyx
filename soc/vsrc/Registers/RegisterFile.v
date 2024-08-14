module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               reset                      ,
    input              [32-1:0]         wdata                      ,
    input              [5-1:0]          waddr                      ,
  
    //
    input              [   4:0]         exu_rd                     ,
    input              [   4:0]         wbu_rd                     ,

    //
    input                               idu_wen                    ,
    input              [5-1:0]          idu_waddr                  ,
    output reg                          idu_vaild                  ,
    // 
    input              [5-1:0]          raddr1                     ,
    input              [5-1:0]          raddr2                     ,

    output             [32-1:0]         rdata1                     ,
    output             [32-1:0]         rdata2                     ,
    input                               wen                        
);
reg [32-1:0] rf [16 - 1:1];
reg                    [  15:0]         scoreboard                 ;
always @(posedge  clock) begin
  if(reset) begin
    scoreboard[15:0] <= {16{1'b1}};
  end
  if((waddr == idu_waddr) && idu_wen && wen) begin
    scoreboard[waddr[3:0]]<= 1'b1;
  end
  else begin
  if (wen && waddr != 0) begin
    scoreboard[waddr[3:0]] <= 1'b1;
  end
  if(idu_wen && idu_waddr!= 0) begin
    scoreboard[idu_waddr[3:0]] <= 1'b0;
  end
  end
end

always @(posedge  clock) begin
  if (wen && waddr != 0) begin
    rf[waddr[3:0]] <= wdata;
  end
end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1[3:0]];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2[3:0]];
  // assign idu_vaild = scoreboard[raddr1[3:0]] && scoreboard[raddr2[3:0]];

  wire valid1, valid2;
  assign valid1 = (raddr1 != 5'b0)&&((raddr1 == exu_rd)||(raddr1 == wbu_rd));
  assign valid2 = (raddr2 != 5'b0)&&((raddr2 == exu_rd)||(raddr2 == wbu_rd));
  assign idu_vaild = ~(valid1 || valid2) ;

endmodule

