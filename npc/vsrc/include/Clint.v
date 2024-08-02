`include "para_defines.v"

module CLINT(
    input S_AXI_ACLK,
    input S_AXI_ARESETN,
    //read data channel
    output  [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_RDATA,
    output  [1 : 0] S_AXI_RRESP,
    output   S_AXI_RVALID,
    input    S_AXI_RREADY,
    output  S_AXI_RLAST,
    output [`ysyx_23060124_AXI_ID_WIDTH-1 : 0] S_AXI_RID,

    //read adress channel
    input   [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input    S_AXI_ARVALID,
    output   S_AXI_ARREADY,
    input [`ysyx_23060124_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input [7 : 0] S_AXI_ARLEN,
    input [2 : 0] S_AXI_ARSIZE,
    input [1 : 0] S_AXI_ARBURST,

    //write back channel
    output  [1 : 0] S_AXI_BRESP,
    output   S_AXI_BVALID,
    input    S_AXI_BREADY,
    output [`ysyx_23060124_AXI_ID_WIDTH-1 : 0] S_AXI_BID,

    //write address channel  
    input   [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input    S_AXI_AWVALID,
    output   S_AXI_AWREADY,
    input   [`ysyx_23060124_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input   [7 : 0] S_AXI_AWLEN,
    input [2 : 0] S_AXI_AWSIZE,
    input [1 : 0] S_AXI_AWBURST,

    //write data channel
    input   [`ysyx_23060124_ISA_WIDTH-1 : 0] S_AXI_WDATA,
    input   [`ysyx_23060124_MASK_LENTH-1 : 0] S_AXI_WSTRB,
    input   S_AXI_WVALID,
    input   S_AXI_WLAST,
    output  S_AXI_WREADY
);
/**********************para******************************/
// mtime Register Address
localparam MTIME_REG_ADDR_LOW = 32'h0200_0000;
localparam MTIME_REG_ADDR_HIGH = 32'h0200_0004;

/**********************regs******************************/
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg  	axi_awready;
reg  	axi_wready;
reg [1 : 0] 	axi_bresp;
reg  	axi_bvalid;
reg [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] 	axi_araddr;
reg  	axi_arready;
reg [`ysyx_23060124_ISA_WIDTH-1 : 0] 	axi_rdata;
reg [1 : 0] 	axi_rresp;
reg  	axi_rvalid;
reg	 aw_en;

// clint 
reg [64-1:0]	reg_mtime;

/**********************wire******************************/
wire	 slv_reg_rden;
wire	 slv_reg_wren;
wire [`ysyx_23060124_ISA_WIDTH-1:0]	 reg_data_out;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;

//mtime ++ per clock cycle
always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        reg_mtime <= 0;
    end 
    else
    begin    
        reg_mtime <= reg_mtime + 1'b1;
        if (slv_reg_wren && S_AXI_AWADDR == MTIME_REG_ADDR_LOW) begin
            reg_mtime[`ysyx_23060124_ISA_WIDTH-1 : 0] <= S_AXI_WDATA;
            // $display("ERROR: Should not reach timer address");
        end
        else if (slv_reg_wren && S_AXI_AWADDR == MTIME_REG_ADDR_HIGH) begin
            reg_mtime[64-1 : `ysyx_23060124_ISA_WIDTH] <= S_AXI_WDATA;
            // $display("ERROR: Should not reach timer address");
        end
    end 
end  
// Implement axi_awready generation
// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_awready <= 1'b0;
        aw_en <= 1'b1;
    end 
    else
    begin    
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
            // slave is ready to accept write address when 
            // there is a valid write address and write data
            // on the write address and data bus. This design 
            // expects no outstanding transactions. 
            axi_awready <= 1'b1;
            aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end
        else           
        begin
            axi_awready <= 1'b0;
        end
    end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 
always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_awaddr <= 0;
    end 
    else
    begin    
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
            // Write Address latching 
            axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end      

// Implement axi_wready generation
// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 

always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_wready <= 1'b0;
    end 
    else
    begin    
        if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
            // slave is ready to accept write data when 
            // there is a valid write address and write data
            // on the write address and data bus. This design 
            // expects no outstanding transactions. 
            axi_wready <= 1'b1;
        end
        else
        begin
            axi_wready <= 1'b0;
        end
    end 
end       

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.

always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_bvalid  <= 0;
        axi_bresp   <= 2'b0;
    end 
    else
    begin    
        if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
            // indicates a valid write response is available
            axi_bvalid <= 1'b1;
            /*********/
            axi_bresp  <= 2'b1; // 'OKAY' response 
            /*********/
        end                   // work error responses in future
        else
        begin
            if (S_AXI_BREADY && axi_bvalid) 
            //check if bready is asserted while bvalid is high) 
            //(there is a possibility that bready is always asserted high)   
            begin
                axi_bvalid <= 1'b0; 
                /*********/
                axi_bresp  <= 2'b0; // 'OKAY' response 
                /*********/
            end  
        end
    end
end   

always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_arready <= 1'b0;
        axi_araddr  <= 32'b0;
    end 
    else
    begin    
        if (~axi_arready && S_AXI_ARVALID)
        begin
            // indicates that the slave has acceped the valid read address
            axi_arready <= 1'b1;
            // Read address latching
            axi_araddr  <= S_AXI_ARADDR;
        end
        else
        begin
            axi_arready <= 1'b0;
        end
    end 
end       

always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_rvalid <= 0;
        axi_rresp  <= 0;
    end 
    else
    begin    
        if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
            // Valid read data is available at the read data bus
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b1; // 'OKAY' response
        end   
        else if (axi_rvalid && S_AXI_RREADY)
        begin
            // Read data is accepted by the master
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b0; // 'IDLE' response
        end                
    end
end    

assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

// Output register or memory read data
always @( posedge S_AXI_ACLK )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_rdata  <= 0;
    end 
    else
    begin    
        // When there is a valid read address (S_AXI_ARVALID) with 
        // acceptance of read address by the slave (axi_arready), 
        // output the read dada 
        if (slv_reg_rden && S_AXI_ARADDR == MTIME_REG_ADDR_LOW)
        begin
            axi_rdata <= reg_mtime[`ysyx_23060124_ISA_WIDTH-1 : 0];     // register read data
        end
        else if (slv_reg_rden && S_AXI_AWADDR == MTIME_REG_ADDR_HIGH)
        begin
            axi_rdata <= reg_mtime[64-1 : `ysyx_23060124_ISA_WIDTH];     // register read data
        end
    end
end    

endmodule