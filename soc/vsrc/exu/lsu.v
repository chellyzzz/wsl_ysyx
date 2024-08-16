module ysyx_23060124_LSU
(
    input                               clock                      ,
    input                               reset                     ,
    input              [  31:0]         store_src                  ,
    input              [  31:0]         alu_res                    ,
    input              [   2:0]         exu_opt                    ,
    output reg         [  31:0]         load_res                   ,
    //
    input                               i_load                     ,
    input                               i_store                    ,
    //axi interface
    //write address channel  
    output             [  31:0]         M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [   3:0]         M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [  31:0]         M_AXI_WDATA                ,
    output             [   3:0]         M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [  31:0]         M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [   3:0]         M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [  31:0]         M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [   3:0]         M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [   3:0]         M_AXI_BID                  ,
  //lsu -> wbu handshake
    input                               o_pre_ready                ,
    input                               i_pre_valid                
);
/************parameter************/
//exu_opt
parameter LB  = 3'b000;
parameter LH  = 3'b001;
parameter LW  = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;
 
wire                   [   3:0]         wstrb                      ;
// Initiate AXI transactions
wire                                    INIT_AXI_TXN               ;

// AXI4LITE signals
reg                                     axi_awvalid                ;
reg                                     axi_wvalid                 ;
reg                                     axi_wlast                  ;
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                    [  31:0]         axi_rdata                  ;
reg                                     axi_bready                 ;
//combine awaddr araddr to 1
reg                    [  31:0]         axi_axaddr                 ;

reg                                     init_txn_ff                ;
reg                                     init_txn_ff2               ;
reg                                     init_txn_edge              ;
reg                                     o_pre_ready_d1             ;

wire                                    init_txn_pulse             ;
wire                                    is_ls, not_ls              ;
reg                    [   1:0]         shift                      ;

assign M_AXI_AWADDR = axi_axaddr;
assign M_AXI_WDATA  = store_src << 8*shift;

assign M_AXI_AWVALID	= axi_awvalid;
assign M_AXI_AWLEN = 'b0;
assign M_AXI_AWSIZE =   (exu_opt == SW) ? 3'b010 :
                        (exu_opt == SH) ? 3'b001 :
                        (exu_opt == SB) ? 3'b000 : 3'b010;
assign M_AXI_AWID    = 0;
assign M_AXI_AWBURST = 2'b00;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign wstrb =  (exu_opt == SB) ? 4'b0001 :
                (exu_opt == SH) ? 4'b0011 :
                (exu_opt == SW) ? 4'b1111 : 4'b0000;

assign M_AXI_WSTRB = wstrb << shift;
assign M_AXI_WLAST = axi_wlast;

//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR = axi_axaddr;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARLEN = 'b0;
assign M_AXI_ARSIZE =   (exu_opt[1:0] == 2'b10) ? 3'b010 :
                        (exu_opt[1:0] == 2'b01) ? 3'b001 :
                        (exu_opt[1:0] == 2'b00) ? 3'b000 : 3'b010;
                        
assign M_AXI_ARBURST = 2'b00;
assign M_AXI_ARID = 0;

//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
//Example design I/O
assign init_txn_pulse	= reset ? 1'b1 : (!init_txn_ff2) && init_txn_ff;
assign INIT_AXI_TXN   = reset ? 1'b1 : (o_pre_ready_d1 && is_ls ? 1'b1 : 1'b0);
assign is_ls = |i_load  || |i_store;
assign not_ls = ~is_ls;
wire txn_pulse_load;
wire txn_pulse_store;
assign txn_pulse_load   = |i_load  && init_txn_pulse;
assign txn_pulse_store  = |i_store && init_txn_pulse;  

reg IDLE;
// assign shift = alu_res[1:0];

always @(posedge clock)begin
    if(reset)begin
      o_pre_ready_d1 <= 1'b0; 
    end
    else begin
      o_pre_ready_d1 <= o_pre_ready;
    end
end

always @(posedge clock)										      
    begin                                                                        
    if (reset)                                                   
        begin                                                                    
        init_txn_ff <= 1'b0;                                                   
        init_txn_ff2 <= 1'b0;     
        shift <= 2'b00;                                              
        end                                                                               
    else                                                                       
        begin  
        init_txn_ff <= INIT_AXI_TXN;
        init_txn_ff2 <= init_txn_ff;
        axi_axaddr <= alu_res;
        shift <= alu_res[1:0];  
        end                                                                      
    end     


	  always @(posedge clock)										      
	  begin                                                                         
	    if (reset)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	    else                                                                       
	      begin                                                                    
	        if (txn_pulse_store == 1'b1)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;
	          end                                                                  
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end      

	   always @(posedge clock)                                        
	   begin                                                                         
	     if (reset)                                                    
	       begin                                                                     
	         axi_wvalid <= 1'b0;       
           axi_wlast <= 1'b1;                                              
	       end                                                                       
	     else if (txn_pulse_store == 1'b1)                                                
	       begin                                                                     
	         axi_wvalid <= 1'b1;       
           axi_wlast <= 1'b1;                                              
	       end                                                                       
	     else if (M_AXI_WREADY && axi_wvalid)                                        
	       begin                                                                     
	        axi_wvalid <= 1'b0;         
	       end                                                                       
	   end                                                                           

	  always @(posedge clock)                                    
	  begin                                                                
	    if (reset)                                           
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                                                   
	    else if (M_AXI_BVALID && ~axi_bready)                              
	      begin                                                            
	        axi_bready <= 1'b1;                                            
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                                                                                  
    always @(posedge clock)                                                     
    begin                                                                            
    if (reset)                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    else if (txn_pulse_load == 1'b1)                                                    
        begin                                                                        
        axi_arvalid <= 1'b1;  
        end                                                                          
    else if (axi_arvalid && M_AXI_ARREADY)                                         
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    end                                                                              
                     
    always @(posedge clock)                                    
    begin                                                                 
    if (reset)                                                                                    
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                                                        
    else if (M_AXI_RVALID && ~axi_rready)                               
        begin                                                             
        axi_rready <= 1'b1;                                             
        end                                                               
    else if (axi_rready)                                                
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                               
    end 
                                
    always @(posedge clock )
    begin
        if (reset)
        begin
            axi_rdata  <= 0;
        end 
        else
        begin    
            if (M_AXI_RVALID && ~axi_rready)
            begin
              case(shift)
                2'b00: axi_rdata <= M_AXI_RDATA;
                2'b01: axi_rdata <= {8'b0, M_AXI_RDATA[31:8]};
                2'b10: axi_rdata <= {16'b0, M_AXI_RDATA[31:16]};
                2'b11: axi_rdata <= {24'b0, M_AXI_RDATA[31:24]};
            endcase
            end   
        end
    end

always @(*) begin
  case(exu_opt)
    LB  : load_res = {{24{axi_rdata[7]}}, axi_rdata[7:0]};
    LH  : load_res = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
    LW  : load_res = axi_rdata[31:0];
    LBU : load_res = {24'b0, axi_rdata[7:0]};
    LHU : load_res = {{16'b0}, axi_rdata[15:0]};
    default: load_res = 32'b0;
  endcase
end
endmodule
