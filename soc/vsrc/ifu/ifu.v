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
    output                              o_post_valid               ,
    //ifu_to_cache
    output reg                          req                        ,
    output             [  31:0]         req_addr                   ,
    input              [  31:0]         icache_ins                 , 
    input                               cache_valid               
    //AXI
);

localparam                              RESET_PC = 32'h3000_0000   ;
reg                    [32-1:0]         pc_next                    ;

always @(posedge clock)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if(~rst_n_sync) begin                                                  
        req <= 1'b1;
    end                                     
    else                                                                       
        begin  
        if(cache_valid && i_post_ready) begin
            req <= 1'b1;
        end
        else if(cache_valid) begin
            req <= 1'b0;
        end
        else begin
            req <= 1'b0;       
        end
        end                                                                      
    end     

wire [32-1:0] ins;
assign req_addr = pc_next;

// TODO:  combine pc_next and o_pc_next
always @(posedge  clock or negedge rst_n_sync) begin
  if (~rst_n_sync) pc_next <= RESET_PC;
  else if(i_pc_update) pc_next <= i_pc_next;
  else if(cache_valid && i_post_ready) pc_next <= pc_next + 4;
  else pc_next <= pc_next;
end

assign ins = icache_ins;
assign o_post_valid = cache_valid;

always @(posedge  clock) begin
  if(~rst_n_sync) begin
    o_ins <= 32'h0;
    o_pc_next <= RESET_PC;
  end
  else if(cache_valid && i_post_ready) begin
    o_ins <= ins;
    o_pc_next <= pc_next;
  end
  else begin
    o_ins <= o_ins;
    o_pc_next <= o_pc_next;
  end
end

endmodule
