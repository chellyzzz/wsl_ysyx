module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               reset                      ,
    input              [  31:0]         wdata                      ,
    input              [   3:0]         waddr                      ,
  
    //
    input              [   3:0]         exu_rd                     ,
    input              [  31:0]         exu_wdata                  ,
    input                               exu_wen                    ,
    input              [   3:0]         wbu_rd                     ,
    input              [  31:0]         wbu_wdata                  ,
    input                               wbu_wen                    ,
    //
    input                               idu_wen                    ,
    input              [   3:0]         idu_waddr                  ,
    // 
    input              [   3:0]         raddr1                     ,
    input              [   3:0]         raddr2                     ,

    output             [  31:0]         rdata1                     ,
    output             [  31:0]         rdata2                     ,
    input                               wen                         
);

reg  [31:0] regfile [15:1];
wire [31:0] rf      [15:0];

genvar i;
generate
  for(i = 1; i < 16; i = i + 1) begin
    assign rf[i] = regfile[i];
  end
endgenerate

assign rf[0] = 32'b0;

always @(posedge  clock) begin
  if (wen && waddr != 0) begin
    regfile[waddr[3:0]] <= wdata;
  end
end

assign rdata1 = (raddr1 == exu_rd && exu_wen)  ? exu_wdata:
                (raddr1 == wbu_rd && wbu_wen)  ? wbu_wdata:
                rf[raddr1[3:0]];

assign rdata2 = (raddr2 == exu_rd && exu_wen)  ? exu_wdata:
                (raddr2 == wbu_rd && wbu_wen)  ? wbu_wdata:
                rf[raddr2[3:0]];


endmodule

