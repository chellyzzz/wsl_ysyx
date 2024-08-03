module ysyx_23060124_LSU 
(
    input                               clock                      ,
    input                               i_rst_n                    ,
    input              [32 - 1:0]       lsu_src2                   ,
    input              [32 - 1:0]       alu_res                    ,
    input              [3 - 1:0]        load_opt                   ,
    input              [3 - 1:0]        store_opt                  ,
    output reg         [32 - 1:0]       lsu_res                    ,
  //axi interface

    //write address channel  
    output             [32-1 : 0]       M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [32-1 : 0]       M_AXI_WDATA                ,
    output             [4-1 : 0]        M_AXI_WSTRB                ,
    input                               M_AXI_WLAST                ,

    //read data channel
    input              [32-1 : 0]       M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [4-1 : 0]        M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [32-1 : 0]       M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [4-1 : 0]        M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [4-1 : 0]        M_AXI_BID                  ,
  //lsu -> wbu handshake
    input                               o_pre_ready                ,
    input                               i_pre_valid                ,
    output reg                          o_post_valid                
);
/************parameter************/
//LSU_OPT
parameter LB  = 3'b000;
parameter LH  = 3'b001;
parameter LW  = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;

assign M_AXI_ARESETN = i_rst_n; 
assign M_AXI_ACLK = clock;
 
reg [32 - 1 : 0] store_addr, store_src2;
reg [3 - 1 : 0] store_opt_next;


wire                   [   3:0]         wstrb                      ;
// Initiate AXI transactions
wire                                    INIT_AXI_TXN               ;
wire                                    M_AXI_ACLK                 ;
wire                                    M_AXI_ARESETN              ;

// AXI4LITE signals
reg                                     axi_awvalid                ;
reg                                     axi_wvalid                 ;
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                    [32-1:0]         axi_rdata                  ;
reg                                     axi_bready                 ;
reg                    [32-1 : 0]       axi_awaddr                 ;
reg                    [32-1 : 0]       axi_araddr                 ;
reg                                     init_txn_ff                ;
reg                                     init_txn_ff2               ;
reg                                     init_txn_edge              ;
reg                                     o_pre_ready_d1             ;

wire                                    init_txn_pulse             ;
wire                                    is_ls, not_ls              ;
wire                   [   1:0]         shift                      ;
wire                   [32-1:0]         read_res                   ;

//Adding the offset address to the base addr of the slave
assign M_AXI_AWADDR    = alu_res;
//AXI 4 write data
assign M_AXI_WDATA = lsu_src2 << 8*shift;

assign M_AXI_AWVALID	= axi_awvalid;
assign M_AXI_AWLEN = 'b0;
assign M_AXI_AWSIZE =   (store_opt == SW) ? 3'b010 :
                        (store_opt == SH) ? 3'b001 :
                        (store_opt == SB) ? 3'b000 : 3'b010;

assign M_AXI_AWBURST = 2'b00;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign wstrb =  (store_opt == SB) ? 4'b0001 :
                (store_opt == SH) ? 4'b0011 :
                (store_opt == SW) ? 4'b1111 : 4'b0000;

assign M_AXI_WSTRB = wstrb << shift;

//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR	= alu_res;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARLEN = 'b0;
assign M_AXI_ARSIZE =   (load_opt == LW ) ? 3'b010 :
                        (load_opt == LH ) ? 3'b001 :
                        (load_opt == LB ) ? 3'b000 : 3'b010;

assign M_AXI_ARBURST = 2'b00;
assign M_AXI_ARID = 0;
//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
//Example design I/O
assign init_txn_pulse	= ~i_rst_n ? 1'b1 : (!init_txn_ff2) && init_txn_ff;
assign INIT_AXI_TXN = ~i_rst_n ? 1'b1 : (o_pre_ready_d1 && is_ls ? 1'b1 : 1'b0);
assign is_ls = |load_opt || |store_opt;
assign not_ls = ~is_ls;
wire txn_pulse_load;
wire txn_pulse_store;
assign txn_pulse_load = |load_opt&& init_txn_pulse;
assign txn_pulse_store = |store_opt && init_txn_pulse;  

assign shift = alu_res[1:0];

always @(posedge clock)begin
    if(i_rst_n == 1'b0)begin
      o_pre_ready_d1 <= 1'b0; 
    end
    else begin
      o_pre_ready_d1 <= o_pre_ready;
    end
end

always @(posedge clock)begin
    if(i_rst_n == 1'b0)begin
      o_post_valid <= 1'b0; 
    end
    else begin
      if(is_ls && (M_AXI_BREADY || M_AXI_RREADY))begin
        o_post_valid <= 1'b1;
      end
      else if(not_ls && o_pre_ready_d1)begin
        o_post_valid <= 1'b1;
      end
      else begin
        o_post_valid <= 1'b0;
      end
    end
end

//Generate a pulse to initiate AXI transaction.
always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        init_txn_ff <= 1'b0;                                                   
        init_txn_ff2 <= 1'b0;                                                   
        end                                                                               
    else                                                                       
        begin  
        init_txn_ff <= INIT_AXI_TXN;
        init_txn_ff2 <= init_txn_ff;                                                                 
        end                                                                      
    end     
	//--------------------
	//Write Address Channel
	//--------------------
	  always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    //Only VALID signals must be deasserted during reset per AXI spec          
	    //Consider inverting then registering active-low reset for higher fmax     
	    if (M_AXI_ARESETN == 0)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	      //Signal a new address/data command is available by user logic           
	    else                                                                       
	      begin                                                                    
	        if (txn_pulse_store == 1'b1)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;                                               
	          end                                                                  
	     //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end      

	//--------------------
	//Write Data Channel
	//--------------------

	//The write data channel is for transfering the actual data.
	//The data generation is speific to the example design, and 
	//so only the WVALID/WREADY handshake is shown here

	   always @(posedge M_AXI_ACLK)                                        
	   begin                                                                         
	     if (M_AXI_ARESETN == 0)                                                    
	       begin                                                                     
	         axi_wvalid <= 1'b0;                                                     
	       end                                                                       
	     //Signal a new address/data command is available by user logic              
	     else if (txn_pulse_store == 1'b1)                                                
	       begin                                                                     
	         axi_wvalid <= 1'b1;                                                     
	       end                                                                       
	     //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)      
	     else if (M_AXI_WREADY && axi_wvalid)                                        
	       begin                                                                     
	        axi_wvalid <= 1'b0;                                                      
	       end                                                                       
	   end                                                                           

	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	  always @(posedge M_AXI_ACLK)                                    
	  begin                                                                
	    if (M_AXI_ARESETN == 0)                                           
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // accept/acknowledge bresp with axi_bready by the master          
	    // when M_AXI_BVALID is asserted by slave                          
	    else if (M_AXI_BVALID && ~axi_bready)                              
	      begin                                                            
	        axi_bready <= 1'b1;                                            
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // retain the previous value                                       
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                       

//----------------------------
//Read Address Channel
//----------------------------
    // A new axi_arvalid is asserted when there is a valid read address              
    // available by the master. start_single_read triggers a new read                
    // transaction                                                                   
    always @(posedge M_AXI_ACLK)                                                     
    begin                                                                            
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if (txn_pulse_load == 1'b1)                                                    
        begin                                                                        
        axi_arvalid <= 1'b1;                                                       
        end                                                                          
    //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)    
    else if (axi_arvalid && M_AXI_ARREADY)                                         
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    // retain the previous value                                                   
    end                                                                              
                     
//--------------------------------
//Read Data (and Response) Channel
//--------------------------------

//The Read Data channel returns the results of the read request 
//The master will accept the read data by asserting axi_rready
//when there is a valid read data available.
//While not necessary per spec, it is advisable to reset READY signals in
//case of differing reset latencies between master/slave.

    always @(posedge M_AXI_ACLK)                                    
    begin                                                                 
    // if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)    
    if (M_AXI_ARESETN == 0)                                                                                    
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                               
    // accept/acknowledge rdata/rresp with axi_rready by the master     
    // when M_AXI_RVALID is asserted by slave                           
    else if (M_AXI_RVALID && ~axi_rready)                               
        begin                                                             
        axi_rready <= 1'b1;                                             
        end                                                               
    // deassert after one clock cycle                                   
    else if (axi_rready)                                                
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                               
    // retain the previous value                                        
    end 
                                
// wire mst_reg_rden;
// assign mst_reg_rden = M_AXI_RVALID && ~axi_rready;

    always @( posedge M_AXI_ACLK )
    begin
        if ( M_AXI_ARESETN == 1'b0 )
        begin
            axi_rdata  <= 0;
        end 
        else
        begin    
            if (M_AXI_RVALID && ~axi_rready)
            begin
                axi_rdata <= M_AXI_RDATA;     // register read data
            end   
        end
    end

assign read_res = axi_rdata >> 8 * shift;

always @(posedge clock) begin
    case(load_opt)
    LB: begin 
      lsu_res <= {{24{read_res[7]}}, read_res[7:0]}; 
    end
    LH: begin 
      lsu_res <= {{16{read_res[15]}}, read_res[15:0]}; 
      end
    LW: begin 
      lsu_res <= read_res[31:0]; 
    end
    LBU: begin 
        lsu_res <= {24'b0, read_res[7:0]};
      end
    LHU: begin 
        lsu_res <= {{16'b0}, read_res[15:0]};
      end
    default: begin lsu_res <= 32'b0; end
    endcase
end

endmodule
