module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               reset                      ,
    input              [  31:0]         wdata                      ,
    input              [   3:0]         waddr                      ,
  
    //
    input              [   3:0]         exu_rd                     ,
    input              [  31:0]         exu_wdata                  ,
    input              [   3:0]         wbu_rd                     ,
    input              [  31:0]         wbu_wdata                  ,
    //
    input                               idu_wen                    ,
    input              [   3:0]         idu_waddr                  ,
    output                              idu_vaild                  ,
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

wire   valid1, valid2;
wire   data_valid1, data_valid2;
wire   zero_valid1, zero_valid2;

assign data_valid1 = (raddr1 != exu_rd)&&(raddr1 != wbu_rd);
assign data_valid2 = (raddr2 != exu_rd)&&(raddr2 != wbu_rd);

assign zero_valid1 = (raddr1 == 4'b0);
assign zero_valid2 = (raddr2 == 4'b0);

assign valid1 = zero_valid1|| data_valid1;
assign valid2 = zero_valid2|| data_valid2;
assign idu_vaild = valid1 && valid2;

// assign rdata1 = (raddr1 == exu_rd)  ? exu_wdata:
//                 (raddr1 == wbu_rd)  ? wbu_wdata:
//                 rf[raddr1[3:0]];
// assign rdata2 = (raddr2 == exu_rd)  ? exu_wdata:
//                 (raddr2 == wbu_rd)  ? wbu_wdata:
//                 rf[raddr2[3:0]];

assign rdata1 = rf[raddr1[3:0]];
assign rdata2 = rf[raddr2[3:0]];

endmodule

