`include "para_defines.v"

module ysyx_23060124_LSU #(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h80000000,
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
		parameter integer C_M_AXI_BURST_LEN	= 1,
		// Thread ID Width
		parameter integer C_M_AXI_ID_WIDTH	= `ysyx_23060124_AXI_ID_WIDTH,
		// Width of Address Bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of Data Bus
		parameter integer C_M_AXI_DATA_WIDTH	= `ysyx_23060124_BUS_WIDTH,
		// Width of User Write Address Bus
		parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
		// Width of User Read Address Bus
		parameter integer C_M_AXI_ARUSER_WIDTH	= 0,
		// Width of User Write Data Bus
		parameter integer C_M_AXI_WUSER_WIDTH	= 0,
		// Width of User Read Data Bus
		parameter integer C_M_AXI_RUSER_WIDTH	= 0,
		// Width of User Response Bus
		parameter integer C_M_AXI_BUSER_WIDTH	= 0
	)
  (
  input                               i_clk   ,
  input                               i_rst_n , 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_src2,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] alu_res,
  input [`ysyx_23060124_MASK_LENTH - 1:0] load_opt,
  input [`ysyx_23060124_MASK_LENTH - 1:0] store_opt,
  input if_unsigned,

  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_res,
  //axi interface
    //write address channel  
    output             [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0]M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [C_M_AXI_DATA_WIDTH-1 : 0]M_AXI_WDATA                ,
    output             [`ysyx_23060124_MASK_LENTH-1 : 0]M_AXI_WSTRB                ,
    input                               M_AXI_WLAST                ,

    //read data channel
    input              [C_M_AXI_DATA_WIDTH-1 : 0]M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [C_M_AXI_ID_WIDTH-1 : 0]M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0]M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [C_M_AXI_ID_WIDTH-1 : 0]M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [C_M_AXI_ID_WIDTH-1 : 0]M_AXI_BID                  ,
  //lsu -> wbu handshake
  input o_pre_ready,
  input i_pre_valid,
  output reg o_post_valid
);
assign M_AXI_ARESETN = i_rst_n; 
assign M_AXI_ACLK = i_clk;

import "DPI-C" function void store_skip (input int addr);
 
reg [`ysyx_23060124_ISA_WIDTH - 1 : 0] store_addr, store_src2;
reg [`ysyx_23060124_MASK_LENTH - 1 : 0] store_opt_next;

// always @(*) begin
//   if(|store_opt) begin 
//       store_skip(alu_res);
//   end
// end

// Initiate AXI transactions
wire  INIT_AXI_TXN;
wire  M_AXI_ACLK;
wire  M_AXI_ARESETN;

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
reg o_pre_ready_d1;

wire  init_txn_pulse;
wire  is_ls, not_ls;
wire  in_sram, in_uart, in_mrom, in_flash, in_spi, in_psram, in_sdram;
wire [2:0] shift_sram, shift_uart, shift_mrom, shift_flash, shift_spi, shift_psram, shitf_sdram, shift;
wire [`ysyx_23060124_BUS_WIDTH-1:0] read_res;
// I/O Connections assignments
reg [`ysyx_23060124_BUS_WIDTH-1:0] axi_rdata;

//Adding the offset address to the base addr of the slave
assign M_AXI_AWADDR	= alu_res;
//AXI 4 write data
// assign M_AXI_WDATA = in_spi ? {lsu_src2, 32'b0} << 8*shift : {32'b0, lsu_src2} << 8*shift;
assign M_AXI_WDATA = lsu_src2 << 8*shift;

assign M_AXI_AWVALID	= axi_awvalid;
assign M_AXI_AWLEN = 'b0;
assign M_AXI_AWSIZE =   (in_sram || in_mrom || in_sdram) ? 3'b010 :
                        (in_spi) ? 3'b010 :
                        (store_opt == `ysyx_23060124_OPT_LSU_SW) ? 3'b010 :
                        (store_opt == `ysyx_23060124_OPT_LSU_SH) ? 3'b001 :
                        (store_opt == `ysyx_23060124_OPT_LSU_SB) ? 3'b000 : 3'b010;

assign M_AXI_AWBURST = 2'b00;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign M_AXI_WSTRB = store_opt[3:0] << shift;
// assign M_AXI_WSTRB = {store_opt[3:0], 4'b0000} >> shift;
//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR	= alu_res;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARLEN = 'b0;
assign M_AXI_ARSIZE =   (in_sram || in_mrom || in_sdram) ? 3'b010 :
                        (in_flash) ? 3'b010 :
                        (load_opt == `ysyx_23060124_OPT_LSU_LW ) ? 3'b010 :
                        (load_opt == `ysyx_23060124_OPT_LSU_LH ) ? 3'b001 :
                        (load_opt == `ysyx_23060124_OPT_LSU_LB ) ? 3'b000 : 3'b010;

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

// shift
assign in_mrom = (alu_res >= `ysyx_23060124_MROM_ADDR) && (alu_res < `ysyx_23060124_MROM_ADDR + `ysyx_23060124_MROM_SIZE);
assign in_uart = (alu_res >= `ysyx_23060124_UART_ADDR) && (alu_res < `ysyx_23060124_UART_ADDR + `ysyx_23060124_UART_SIZE);
assign in_sram = (alu_res >= `ysyx_23060124_SRAM_ADDR) && (alu_res < `ysyx_23060124_SRAM_ADDR + `ysyx_23060124_SRAM_SIZE);
assign in_flash = (alu_res >= `ysyx_23060124_FLASH_ADDR) && (alu_res < `ysyx_23060124_FLASH_ADDR + `ysyx_23060124_FLASH_SIZE);
assign in_spi = (alu_res >= `ysyx_23060124_SPI_ADDR) && (alu_res < `ysyx_23060124_SPI_ADDR + `ysyx_23060124_SPI_SIZE);
assign in_psram = (alu_res >= `ysyx_23060124_PSRAM_ADDR) && (alu_res < `ysyx_23060124_PSRAM_ADDR + `ysyx_23060124_PSRAM_SIZE);
assign in_sdram = (alu_res >= `ysyx_23060124_SDRAM_ADDR) && (alu_res < `ysyx_23060124_SDRAM_ADDR + `ysyx_23060124_SDRAM_SIZE);

assign shift_uart = {1'b0, alu_res[1:0]};
assign shift_flash = alu_res[1:0];
assign shift_sram = alu_res[1:0];
assign shift_mrom = alu_res[1:0];
assign shift_spi =  alu_res[1:0];
assign shift_psram = alu_res[1:0];
assign shitf_sdram = alu_res[1:0];

assign shift =  in_sram ? shift_sram  :
                in_psram ? shift_psram  :
                in_mrom ? shift_mrom  :
                in_uart ? shift_uart  : 
                in_flash ? shift_flash:
                in_spi ?  shift_spi :
                in_sdram ? shitf_sdram :
                alu_res[1:0];

always @(posedge i_clk)begin
    if(i_rst_n == 1'b0)begin
      o_pre_ready_d1 <= 1'b0; 
    end
    else begin
      o_pre_ready_d1 <= o_pre_ready;
    end
end

always @(posedge i_clk)begin
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

assign read_res = in_psram ? axi_rdata >> 8 * alu_res[1:0] :
                  axi_rdata >> 8 * shift;

always @(posedge i_clk) begin
    case(load_opt)
    `ysyx_23060124_OPT_LSU_LB: begin 
      if(if_unsigned)begin
        lsu_res <= {24'b0, read_res[7:0]};
      end
      else lsu_res <= {{24{read_res[7]}}, read_res[7:0]}; 
    end
    `ysyx_23060124_OPT_LSU_LH: begin 
      if(if_unsigned)begin
        lsu_res <= {{16'b0}, read_res[15:0]};
      end
      else lsu_res <= {{16{read_res[15]}}, read_res[15:0]}; 
      end
    `ysyx_23060124_OPT_LSU_LW: begin 
      lsu_res <= read_res[31:0]; 
    end
    default: begin lsu_res <= `ysyx_23060124_ISA_WIDTH'b0; end
    endcase
end

endmodule
