`include "para_defines.v"

module ysyx_23060124_lsu(
  input                               i_clk   ,
  input                               i_rst_n , 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_src2,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] alu_res,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] load_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] store_opt,
  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_res,
    //axi interface
    //write address channel  
    output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output  M_AXI_AWVALID,
    input  M_AXI_AWREADY,
    //write data channel
    output  M_AXI_WVALID,
    input  M_AXI_WREADY,
    output [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_WDATA,
    output [`ysyx_23060124_OPT_WIDTH-1 : 0] M_AXI_WSTRB,
    //read data channel
    input [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_RDATA,
    input [1 : 0] M_AXI_RRESP,
    input  M_AXI_RVALID,
    output  M_AXI_RREADY,
    //read adress channel
    output [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output  M_AXI_ARVALID,
    input  M_AXI_ARREADY,
    //write back channel
    input [1 : 0] M_AXI_BRESP,
    input  M_AXI_BVALID,
    output  M_AXI_BREADY,
  //lsu -> wbu handshake
  input i_pre_valid,
  output reg o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_res, store_res;


import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int len);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);
import "DPI-C" function void store_skip (input int addr);
 
reg [`ysyx_23060124_ISA_WIDTH - 1 : 0] store_addr, store_src2;
reg [`ysyx_23060124_OPT_WIDTH - 1 : 0] store_opt_next;

always @(*) begin
  if(|store_opt) begin 
      store_skip(alu_res);
  end
end

// Initiate AXI transactions
wire  INIT_AXI_TXN;
wire  M_AXI_ACLK;
wire  M_AXI_ARESETN;

assign M_AXI_ARESETN = i_rst_n; 
assign M_AXI_ACLK = i_clk;

// AXI4LITE signals
reg  	axi_awvalid;
reg  	axi_wvalid;
reg  	axi_arvalid;
reg  	axi_rready;
reg  	axi_bready;
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_araddr;

reg  	init_txn_ff;
reg  	init_txn_ff2;
reg  	init_txn_edge;
wire  	init_txn_pulse;

// I/O Connections assignments
reg [`ysyx_23060124_ISA_WIDTH-1:0] axi_rdata;

//Adding the offset address to the base addr of the slave
assign M_AXI_AWADDR	= alu_res;
//AXI 4 write data
assign M_AXI_WDATA	= lsu_src2;
assign M_AXI_AWVALID	= axi_awvalid;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign M_AXI_WSTRB	= store_opt;
//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR	= alu_res;
assign M_AXI_ARVALID	= axi_arvalid;
//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
//Example design I/O
assign init_txn_pulse	= ~i_rst_n ? 1'b1 : (!init_txn_ff2) && init_txn_ff;
assign INIT_AXI_TXN = ~i_rst_n ? 1'b1 : (i_pre_valid && is_ls ? 1'b1 : 1'b0);
assign is_ls = |load_opt || |store_opt;
assign not_ls = ~is_ls;
wire txn_pulse_load;
wire txn_pulse_store;

assign txn_pulse_load = |load_opt&& init_txn_pulse;
assign txn_pulse_store = |store_opt && init_txn_pulse;  

always @(posedge i_clk)begin
    if(i_rst_n == 1'b0)begin
      o_post_valid <= 1'b0; 
    end
    else begin
      if( is_ls && (M_AXI_BREADY || M_AXI_RREADY))begin
        o_post_valid <= 1'b1;
      end
      else if(not_ls && i_pre_valid)begin
        o_post_valid <= 1'b1;
      end
      else begin
        o_post_valid <= 1'b0;
      end
    end
end

// always @(posedge M_AXI_ACLK)										      
//     begin                                                                        
//     // Initiates AXI transaction delay    
//     if (M_AXI_ARESETN == 0 )                                                   
//         begin                                                                    
//         INIT_AXI_TXN <= 1'b1;                                            
//         end                                                                               
//     else                                                                       
//         begin  
//         if(i_pre_valid)begin
//             INIT_AXI_TXN <= 1'b1;
//         end
//         else INIT_AXI_TXN <= 1'b0;                                                          
//         end                                                                      
//     end     

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

always @(posedge i_clk) begin
    case(load_opt)
    `ysyx_23060124_OPT_LSU_LB: begin lsu_res <= {{24{axi_rdata[7]}}, axi_rdata[7:0]}; end
    `ysyx_23060124_OPT_LSU_LH: begin lsu_res <= {{16{axi_rdata[15]}}, axi_rdata[15:0]}; end
    `ysyx_23060124_OPT_LSU_LW: begin lsu_res <= axi_rdata; end
    `ysyx_23060124_OPT_LSU_LBU: begin lsu_res <= {24'b0, axi_rdata[7:0]}; end
    `ysyx_23060124_OPT_LSU_LHU: begin lsu_res <= {{16'b0}, axi_rdata[15:0]}; end
    default: begin lsu_res <= `ysyx_23060124_ISA_WIDTH'b0; end
    endcase
end

endmodule
