`include "para_defines.v"

module ysyx_23060124_IFU #(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Base address of targeted slave
    parameter                           C_M_TARGET_SLAVE_BASE_ADDR	= 32'h80000000,
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
    parameter                           integer C_M_AXI_BURST_LEN	= 1,
		// Width of Address Bus
    parameter                           integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of Data Bus
    parameter                           integer C_M_AXI_DATA_WIDTH	= 32,
		// Width of User Write Address Bus
    parameter                           integer C_M_AXI_AWUSER_WIDTH	= 0,
		// Width of User Read Address Bus
    parameter                           integer C_M_AXI_ARUSER_WIDTH	= 0,
		// Width of User Write Data Bus
    parameter                           integer C_M_AXI_WUSER_WIDTH	= 0,
		// Width of User Read Data Bus
    parameter                           integer C_M_AXI_RUSER_WIDTH	= 0,
		// Width of User Response Bus
    parameter                           integer C_M_AXI_BUSER_WIDTH	= 0 
    )
    (
    input              [`ysyx_23060124_ISA_WIDTH-1:0]i_pc_next                  ,
    input                               clk                        ,
    input                               ifu_rst                    ,
    input                               i_pc_update                ,
    input                               i_post_ready               ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]o_ins                      ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]o_pc_next                  ,

    //write address channel  
    output             [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0]M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [`ysyx_23060124_AXI_ID_WIDTH-1 : 0]M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [`ysyx_23060124_ISA_WIDTH-1 : 0]M_AXI_WDATA                ,
    output             [`ysyx_23060124_MASK_LENTH-1 : 0]M_AXI_WSTRB                ,
    input                               M_AXI_WLAST                ,

    //read data channel
    input              [`ysyx_23060124_BUS_WIDTH - 1 : 0]M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [`ysyx_23060124_AXI_ID_WIDTH-1 : 0]M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0]M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [`ysyx_23060124_AXI_ID_WIDTH-1 : 0]M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [`ysyx_23060124_AXI_ID_WIDTH-1 : 0]M_AXI_BID                  ,

    //ifu_to_idu valid
    output reg                          o_post_valid                
);

/******************************regs*****************************/
    // Initiate AXI transactions
    reg  INIT_AXI_TXN;
    // AXI4LITE signals
    reg  	axi_awvalid;
    reg  	axi_wvalid;
    reg  	axi_arvalid;
    reg  	axi_rready;
    reg  	axi_bready;
    reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg [`ysyx_23060124_ISA_WIDTH-1 : 0] 	axi_wdata;
    reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg [`ysyx_23060124_BUS_WIDTH-1:0] axi_rdata;

    //Flag is asserted when the read index reaches the last read transction number
    reg  	init_txn_ff;
    reg  	init_txn_ff2;
    reg  	init_txn_edge;
    wire  init_txn_pulse;


wire  in_sram, in_mrom;
//for shift

/******************************nets*****************************/
    // AXI clock signal
    wire  M_AXI_ACLK;
    // AXI active low reset signal
    wire  M_AXI_ARESETN;
/******************************combinational logic*****************************/
    assign M_AXI_ARESETN = ifu_rst; 
    assign M_AXI_ACLK = clk;
    
    //should not send write signal
        //Write Address (AW)
        assign M_AXI_AWVALID = 1'b0;
        assign M_AXI_AWADDR = `ysyx_23060124_ISA_ADDR_WIDTH'b0;
        // assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr;
        assign M_AXI_WDATA	= axi_wdata;
        assign M_AXI_AWVALID	= axi_awvalid;

        //Write Data(W)
        assign M_AXI_WVALID	= axi_wvalid;
        assign M_AXI_WVALID = 1'b0;
        assign M_AXI_WDATA = `ysyx_23060124_ISA_WIDTH'b0;
        assign M_AXI_WSTRB = `ysyx_23060124_MASK_LENTH'b0;   
        //Write Response (B)
        assign M_AXI_BREADY = 1'b0;
        assign M_AXI_BREADY	= axi_bready;
        //Read Address (AR)
        assign M_AXI_ARADDR = pc_next;
        assign M_AXI_ARVALID	= axi_arvalid;
        assign M_AXI_ARID = 'b0;
        assign M_AXI_ARLEN = 'b0;
        assign M_AXI_ARSIZE = 3'b010;
        assign M_AXI_ARBURST = 2'b00;

        //Read and Read Response (R)
        assign M_AXI_RREADY	= axi_rready;
         
        //Example design I/O
        assign init_txn_pulse	= ~ifu_rst ? 1'b1 : (!init_txn_ff2) && init_txn_ff;

        assign in_mrom = (M_AXI_ARADDR >= `ysyx_23060124_MROM_ADDR) && (M_AXI_ARADDR < `ysyx_23060124_MROM_ADDR + `ysyx_23060124_MROM_SIZE);
        assign in_sram = (M_AXI_ARADDR >= `ysyx_23060124_SRAM_ADDR) && (M_AXI_ARADDR < `ysyx_23060124_SRAM_ADDR + `ysyx_23060124_SRAM_SIZE);

/******************************sequential logic*****************************/



always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        INIT_AXI_TXN <= 1'b1;                                            
        end                                                                               
    else                                                                       
        begin  
        if(i_pc_update)begin
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
                axi_rdata <=  M_AXI_RDATA;     // register read data
            end   
        end
    end    

//----------------------------
// only for ifu
//----------------------------

reg [`ysyx_23060124_ISA_WIDTH-1:0] pc_next;

ysyx_23060124_Reg #(`ysyx_23060124_ISA_WIDTH, `ysyx_23060124_RESET_PC) next_pc_reg(
  .clk(clk),
  .rst(ifu_rst),
  .din(i_pc_next),
  .dout(pc_next),
  .wen(i_pc_update)
);

always @(posedge clk or negedge ifu_rst) begin
  if(~ifu_rst) begin
    o_post_valid <= 1'b0;
  end
  else if(M_AXI_RREADY) begin
    o_post_valid <= 1'b1;
  end
  else if(o_post_valid && i_post_ready) begin
    o_post_valid <= 1'b0;
  end
  else o_post_valid <= o_post_valid;
end

always @(posedge clk or negedge ifu_rst) begin
  if(~ifu_rst) begin
    o_ins <= 32'h0;
    o_pc_next <= `ysyx_23060124_RESET_PC;
  end
  else if(i_post_ready && o_post_valid) begin
    o_ins <= axi_rdata[`ysyx_23060124_ISA_WIDTH-1:0];
    o_pc_next <= pc_next;
  end
end

endmodule
