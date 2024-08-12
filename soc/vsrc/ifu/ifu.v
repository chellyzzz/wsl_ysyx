module ysyx_23060124_IFU
(
    input              [32-1:0]         i_pc_next                  ,
    input                               clock                      ,
    input                               rst_n_sync                 ,
    input                               i_pc_update                ,
    input                               i_post_ready               ,
    output             [32-1:0]         ins                        ,
    output reg         [32-1:0]         pc_next                    ,
    //ifu_to_cache
    output reg                          req                        ,
    output             [  31:0]         req_addr                   ,
    input              [  31:0]         icache_ins                 ,
    input                               cache_valid                 
);

localparam                              RESET_PC = 32'h3000_0000   ;

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

assign req_addr = pc_next;

// TODO:  combine pc_next and o_pc_next
always @(posedge  clock or negedge rst_n_sync) begin
  if (~rst_n_sync) pc_next <= RESET_PC;
  else if(i_pc_update) pc_next <= i_pc_next;
  else if(cache_valid && i_post_ready) pc_next <= pc_next + 4;
  else pc_next <= pc_next;
end

assign ins = icache_ins;

endmodule
