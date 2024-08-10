module ysyx_23060124_IFU
(
    input              [32-1:0]         i_pc_next                  ,
    input                               clock                      ,
    input                               rst_n_sync                 ,
    input                               i_pc_update                ,
    input                               i_post_ready               ,
    output reg         [32-1:0]         o_ins                      ,
    output reg         [32-1:0]         o_pc_next                  ,
    //ifu_to_idu valid
    output reg                          o_post_valid               ,
    //ifu_to_cache
    output reg                          req                        ,
    output reg         [  31:0]         req_addr                   ,
    input                               hit                        ,
    input              [  31:0]         icache_ins                 , 
    input                               cache_valid               ,
    //AXI
    input                               M_AXI_RLAST                
);

localparam                              RESET_PC = 32'h3000_0000   ;
reg                    [32-1:0]         pc_next                    ;

always @(posedge clock)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if(~rst_n_sync) begin                                                  
        req <= 1'b1;
        req_addr <= RESET_PC;       
    end                                     
    else                                                                       
        begin  
        if(i_pc_update) begin
            req <= 1'b1;
            req_addr <= i_pc_next;
        end
        else if(cache_valid) begin
            req <= 1'b0;
            req_addr <= 32'h0;
        end
        else begin
            req <= 1'b0;       
            req_addr <= req_addr;
        end
        end                                                                      
    end     


//----------------------------
// only for ifu
//----------------------------

// ysyx_23060124_Reg #(.WIDTH(32), .RESET_VAL(RESET_PC)) next_pc_reg(
//     .clock                             (clock                     ),
//     .rst                               (rst_n_sync                ),
//     .din                               (i_pc_next                 ),
//     .dout                              (pc_next                   ),
//     .wen                               (i_pc_update               ) 
// );

wire [32-1:0] pc;
wire [32-1:0] ins;
always @(posedge  clock or negedge rst_n_sync) begin
  if (~rst_n_sync) pc_next <= RESET_PC;
  else if (i_pc_update) pc_next <= i_pc_next;
  else pc_next <= pc_next + 4;
end


assign pc = pc_next;
assign ins = icache_ins;

always @(posedge  clock) begin
  if(~rst_n_sync) begin
    o_post_valid <= 1'b0;
  end
  else if(cache_valid) begin
    o_post_valid <= 1'b1;
  end
  else if(o_post_valid && i_post_ready) begin
    o_post_valid <= 1'b0;
  end
  else o_post_valid <= 1'b0;
end

always @(posedge  clock) begin
  if(~rst_n_sync) begin
    o_ins <= 32'h0;
    o_pc_next <= RESET_PC;
  end
  else if(cache_valid) begin
    o_ins <= ins;
    o_pc_next <= pc;
  end
end

endmodule
