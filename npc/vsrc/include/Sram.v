`include "para_defines.v"

module SRAM (
    input S_AXI_ACLK,
    input S_AXI_ARESETN,
    //read data channel
    output wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] out_ins,
    output wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY,

    //read adress channel
    input wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,

    //write back channel
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,

    //write address channel  
    input wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,

    //write data channel
    input wire [`ysyx_23060124_ISA_WIDTH-1:0] S_AXI_WDATA,
    input wire [`ysyx_23060124_ISA_WIDTH/8-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,  
);

wire [`ysyx_23060124_ISA_ADDR_WIDTH - 1 : 0] raddr, waddr;
wire [`ysyx_23060124_ISA_WIDTH - 1 : 0] read_data;
reg [`ysyx_23060124_ISA_WIDTH - 1:0] rdata;
reg [`ysyx_23060124_ISA_WIDTH - 1 : 0] store_addr, store_src2;
reg [`ysyx_23060124_OPT_WIDTH - 1 : 0] store_opt_next;

assign clk = S_AXI_ACLK;
assign rst_n = S_AXI_ARESETN;
assign raddr = S_AXI_ARADDR;
assign waddr = S_AXI_AWADDR;
assign wdata = S_AXI_WDATA;
///*******
assign ren = S_AXI_ARESETN; 
///*******
assign wen = S_AXI_WVALID;
assign out_ins = rdata;
assign store_opt = 0;


import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int len);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);
import "DPI-C" function void store_skip (input int addr);

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rdata <= read_data;
        store_opt_next <= 0;
        store_addr <= 0;
        store_src2 <= 0;
    end else begin
        if(ren) begin
            rdata <= read_data;
        end
        else begin
            rdata <= rdata;
        end
        if(wen) begin
            store_addr <= waddr;
            store_src2 <= wdata;
            store_opt_next <= store_opt;
        end
        else begin
            store_addr <= store_addr;
            store_src2 <= store_src2;
            store_opt_next <= store_opt_next;
        end
    end
end

always @(posedge clk) begin
    npc_pmem_read (raddr, read_data, ren, 4);
end

always @(*) begin
    case(store_opt_next)
    `ysyx_23060124_OPT_LSU_SB: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 1); end
    `ysyx_23060124_OPT_LSU_SH: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 2); end
    `ysyx_23060124_OPT_LSU_SW: begin  npc_pmem_write(store_addr, store_src2, |store_opt_next, 4); end
    endcase
end


// AXI4LITE signals
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

//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 4
reg [`ysyx_23060124_ISA_WIDTH-1:0]	slv_reg0;

wire	 slv_reg_rden;
wire	 slv_reg_wren;
wire [`ysyx_23060124_ISA_WIDTH-1:0]	 reg_data_out;
integer	 byte_index;
reg	 aw_en;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;

// Implement axi_arready generation
// axi_arready is asserted for one S_AXI_ACLK clock cycle when
// S_AXI_ARVALID is asserted. axi_awready is 
// de-asserted when reset (active low) is asserted. 
// The read address is also latched when S_AXI_ARVALID is 
// asserted. axi_araddr is reset to zero on reset assertion.

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

// Implement axi_arvalid generation
// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
// data are available on the axi_rdata bus at this instance. The 
// assertion of axi_rvalid marks the validity of read data on the 
// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
// is deasserted on reset (active low). axi_rresp and axi_rdata are 
// cleared to zero on reset (active low).  
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

// Implement memory mapped register select and read logic generation
// Slave register read enable is asserted when valid address is available
// and the slave is ready to accept the read address.
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
always @(*)
begin
    npc_pmem_read (raddr, reg_data_out, ren, 4);
end

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
        if (slv_reg_rden)
        begin
            axi_rdata <= reg_data_out;     // register read data
            // axi_rresp  <= 2'b1; // 'OKAY' response
        end
            // axi_rresp <= 2'b0; // 'IDLE' response
    end
end    

// Add user logic here

// User logic ends

// AXI4Lite_SLAVE #(
//     .C_M_AXI_ADDR_WIDTH(`ysyx_23060124_ISA_WIDTH),
//     .C_M_AXI_DATA_WIDTH(`ysyx_23060124_ISA_ADDR_WIDTH)
// )
// cpu_to_sram_slave
// (
//     .S_AXI_ACLK(clk),
//     .S_AXI_ARESETN(i_rst_n),
//     .S_AXI_AWADDR(CPU.o_addr),
//     .S_AXI_AWVALID(CPU.o_awvalid),

// );

endmodule