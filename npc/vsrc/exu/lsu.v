`include "para_defines.v"

module ysyx_23060124_lsu(
  input                               i_clk   ,
  input                               i_rst_n , 
  input [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_src2,
  input [`ysyx_23060124_ISA_WIDTH - 1:0] alu_res,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] load_opt,
  input [`ysyx_23060124_OPT_WIDTH - 1:0] store_opt,
  input i_pre_valid,
  output reg [`ysyx_23060124_ISA_WIDTH - 1:0] lsu_res,
  output reg o_post_valid
);

reg [`ysyx_23060124_ISA_WIDTH - 1:0] read_res, store_res;


import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int len);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);
import "DPI-C" function void store_skip (input int addr);
 
reg [`ysyx_23060124_ISA_WIDTH - 1 : 0] store_addr, store_src2;
reg [`ysyx_23060124_OPT_WIDTH - 1 : 0] store_opt_next;

always @(posedge i_clk) begin
// always @(read_res or load_opt) begin
    case(load_opt)
    `ysyx_23060124_OPT_LSU_LB: begin lsu_res = {{24{read_res[7]}}, read_res[7:0]}; end
    `ysyx_23060124_OPT_LSU_LH: begin lsu_res = {{16{read_res[15]}}, read_res[15:0]}; end
    `ysyx_23060124_OPT_LSU_LW: begin lsu_res = read_res; end
    `ysyx_23060124_OPT_LSU_LBU: begin lsu_res = {24'b0, read_res[7:0]}; end
    `ysyx_23060124_OPT_LSU_LHU: begin lsu_res = {{16'b0}, read_res[15:0]}; end
    default: begin lsu_res = `ysyx_23060124_ISA_WIDTH'b0; end
    endcase
end

always @(*) begin
  if(|store_opt) begin 
      store_skip(alu_res);
  end
end

SRAM_lsu LSU_SRAM(
    .S_AXI_ACLK(i_clk),
    .S_AXI_ARESETN(i_rst_n),
    .raddr(alu_res),
    .waddr(alu_res),
    .wdata(lsu_src2),
    .ren(|load_opt & i_pre_valid),
    .wen(|store_opt & i_pre_valid),
    .store_opt(store_opt),
    .rdata(read_res),
    .i_pre_valid(i_pre_valid),
    .o_post_valid(o_post_valid)
);


    // Initiate AXI transactions
    reg  INIT_AXI_TXN;
    // Asserts when ERROR is detected
    reg  ERROR;
    // Asserts when AXI transactions is complete
    wire  TXN_DONE;
    // AXI clock signal
    wire  M_AXI_ACLK;
    // AXI active low reset signal
    wire  M_AXI_ARESETN;
    // Master Interface Write Address Channel ports. Write address (issued by master)
    wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_AWADDR;
    // Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction;
    // and whether the transaction is a data access or an instruction access.
    wire [2 : 0] M_AXI_AWPROT;
    // Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
    wire  M_AXI_AWVALID;
    // Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
    wire  M_AXI_AWREADY;
    // Master Interface Write Data Channel ports. Write data (issued by master)
    wire [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_WDATA;
    // Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
    wire [`ysyx_23060124_ISA_WIDTH/8-1 : 0] M_AXI_WSTRB;
    // Write valid. This signal indicates that valid write data and strobes are available.
    wire  M_AXI_WVALID;
    // Write ready. This signal indicates that the slave can accept the write data.
    wire  M_AXI_WREADY;
    // Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
    wire [1 : 0] M_AXI_BRESP;
    // Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
    wire  M_AXI_BVALID;
    // Response ready. This signal indicates that the master can accept a write response.
    wire  M_AXI_BREADY;
    // Master Interface Read Address Channel ports. Read address (issued by master)
    wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] M_AXI_ARADDR;
    // Protection type. 
    // This signal indicates the privilege and security level of the transaction; 
    // and whether the transaction is a data access or an instruction access.
    wire [2 : 0] M_AXI_ARPROT;
    // Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
    wire  M_AXI_ARVALID;
    // Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
    wire  M_AXI_ARREADY;
    // Master Interface Read Data Channel ports. Read data (issued by slave)
    wire [`ysyx_23060124_ISA_WIDTH-1 : 0] M_AXI_RDATA;
    // Read response. This signal indicates the status of the read transfer.
    wire [1 : 0] M_AXI_RRESP;
    // Read valid. This signal indicates that the channel is signaling the required read data.
    wire  M_AXI_RVALID;
    // Read ready. This signal indicates that the master can accept the read data and response information.
    wire  M_AXI_RREADY;

assign M_AXI_ARESETN = i_rst_n; 
assign M_AXI_ACLK = i_clk;
// AXI4LITE signals
reg  	axi_awvalid;
reg  	axi_wvalid;
reg  	axi_arvalid;
reg  	axi_rready;
reg  	axi_bready;
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg [`ysyx_23060124_ISA_WIDTH-1 : 0] 	axi_wdata;
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_araddr;
//Asserts when there is a write response error
wire  	write_resp_error;
//Asserts when there is a read response error
wire  	read_resp_error;
//A pulse to initiate a write transaction
reg  	start_single_write;
//A pulse to initiate a read transaction
reg  	start_single_read;
//Asserts when a single beat write transaction is issued and remains asserted till the completion of write trasaction.
reg  	write_issued;
//Asserts when a single beat read transaction is issued and remains asserted till the completion of read trasaction.
reg  	read_issued;
//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
reg  	writes_done;
//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
reg  	reads_done;
//The error register is asserted when any of the write response error, read response error or the data mismatch flags are asserted.
reg  	error_reg;
//Flag marks the completion of comparison of the read data with the expected read data
reg  	compare_done;
//This flag is asserted when there is a mismatch of the read data with the expected read data.
reg  	read_mismatch;
//Flag is asserted when the write index reaches the last write transction number
reg  	last_write;
//Flag is asserted when the read index reaches the last read transction number
reg  	last_read;
reg  	init_txn_ff;
reg  	init_txn_ff2;
reg  	init_txn_edge;
wire  	init_txn_pulse;

// I/O Connections assignments
wire s_axi_rvalid, s_axi_rready, s_axi_bvalid, s_axi_bready,s_axi_arready;
wire s_axi_awready, s_axi_wready;
wire [1:0] s_axi_rresp, s_axi_bresp;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] s_axi_rdata;
reg [`ysyx_23060124_ISA_WIDTH-1:0] axi_rdata;

//Adding the offset address to the base addr of the slave
// assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr;
//AXI 4 write data
assign M_AXI_WDATA	= axi_wdata;
assign M_AXI_AWPROT	= 3'b000;
assign M_AXI_AWVALID	= axi_awvalid;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign M_AXI_WSTRB	= load_opt;
//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
// assign M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_araddr;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARREADY = s_axi_arready;
assign M_AXI_ARPROT	= 3'b001;
//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
assign M_AXI_RDATA = axi_rdata;
//Example design I/O
assign init_txn_pulse	= ~i_rst_n ? 1'b1 : (!init_txn_ff2) && init_txn_ff;
// assign INIT_AXI_TXN = ~i_rst_n ? 1'b1 : i_pc_update;

always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        INIT_AXI_TXN <= 1'b1;                                            
        end                                                                               
    else                                                                       
        begin  
        if(i_pre_valid)begin
            INIT_AXI_TXN <= 1'b1;
        end
        else INIT_AXI_TXN <= 1'b0;                                                          
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
	        if (init_txn_pulse == 1'b1)                                                
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
	     else if (init_txn_pulse == 1'b1)                                                
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
	                                                                       
	//Flag write errors                                                    
	assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);


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
    else if (init_txn_pulse == 1'b1)                                                    
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
                axi_rdata <= s_axi_rdata;     // register read data
            end   
        end
    end    

//Flag write errors                                                     
assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]); 


//----------------------------
//Reserved Read Address Channel
//----------------------------
// // I/O Connections assignments
// wire s_axi_rvalid, s_axi_rready, s_axi_bvalid, s_axi_bready,s_axi_arready;
// wire s_axi_awready, s_axi_wready;
// wire [1:0] s_axi_rresp, s_axi_bresp;
// wire [`ysyx_23060124_ISA_WIDTH-1 : 0] s_axi_rdata;
// reg [`ysyx_23060124_ISA_WIDTH-1:0] axi_rdata;

SRAM_lsuaxi lsu_AXI_sram(
    .S_AXI_ACLK(i_clk),
    .S_AXI_ARESETN(i_rst_n),
    //read data channel
    .S_AXI_RDATA(M_AXI_RDATA),
    .S_AXI_RRESP(M_AXI_RRESP),
    .S_AXI_RVALID(M_AXI_RVALID),
    .S_AXI_RREADY(M_AXI_RREADY),
    //read adress channel
    .S_AXI_ARADDR(alu_res),
    .S_AXI_ARVALID(M_AXI_ARVALID),
    .S_AXI_ARREADY(s_axi_arready),
    //write back channel
    .S_AXI_BRESP(M_AXI_BRESP),
    .S_AXI_BVALID(M_AXI_BVALID),
    .S_AXI_BREADY(M_AXI_BREADY),
    //write address channel  
    .S_AXI_AWADDR(alu_res),
    .S_AXI_AWVALID(M_AXI_AWVALID),
    .S_AXI_AWREADY(M_AXI_AWREADY),
    //write data channel
    .S_AXI_WDATA(lsu_src2),
    .S_AXI_WSTRB(M_AXI_WSTRB),
    .S_AXI_WVALID(M_AXI_WVALID),
    .S_AXI_WREADY(M_AXI_WREADY)
);


// ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH + `ysyx_23060124_ISA_WIDTH + `ysyx_23060124_OPT_WIDTH,  0) lsu_reg(
//   .clk(i_clk),
//   .rst(i_rst_n),
//   .din({alu_res, store_opt, lsu_src2}),
//   .dout({store_addr, store_opt_next, store_src2}),
//   .wen(1)
// );

// always @(*) begin
//   // $display("\nREAD DATA at ADDR = 0x%h", alu_res);
//   npc_pmem_read(alu_res, read_res, |load_opt, 4);
// end

// always @(*) begin
//     case(store_opt_next)
//     `ysyx_23060124_OPT_LSU_SB: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 1); end
//     `ysyx_23060124_OPT_LSU_SH: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 2); end
//     `ysyx_23060124_OPT_LSU_SW: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 4); end
//     endcase
// end

endmodule
