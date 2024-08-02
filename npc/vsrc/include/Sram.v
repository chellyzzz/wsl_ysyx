`include "para_defines.v"

module SRAM (
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

import "DPI-C" function void npc_pmem_read (input int raddr, output int rdata, input bit ren, input int len);
import "DPI-C" function void npc_pmem_write (input int waddr, input int wdata, input bit wen, input int len);

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
reg  	axi_rlast;
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
// The axi_awv_awr_flag flag marks the presence of write address valid
reg axi_awv_awr_flag;
//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
reg [7:0] axi_arlen_cntr;
reg [1:0] axi_arburst;
reg [1:0] axi_awburst;
reg [7:0] axi_arlen;
reg [7:0] axi_awlen;

	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)

	localparam integer ADDR_LSB = (`ysyx_23060124_ISA_ADDR_WIDTH/32)+ 1;
// I/O Connections assignments

assign S_AXI_AWREADY    = axi_awready;
assign S_AXI_WREADY    = axi_wready;
assign S_AXI_BRESP    = axi_bresp;
assign S_AXI_BVALID    = axi_bvalid;
assign S_AXI_ARREADY    = axi_arready;
assign S_AXI_RDATA    = axi_rdata;
assign S_AXI_RRESP    = axi_rresp;
assign S_AXI_RVALID    = axi_rvalid;

assign S_AXI_BID = S_AXI_AWID;
assign S_AXI_RID = S_AXI_ARID;

assign  aw_wrap_size = (`ysyx_23060124_ISA_WIDTH/8 * (axi_awlen)); 
assign  ar_wrap_size = (`ysyx_23060124_ISA_WIDTH/8 * (axi_arlen)); 
assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;


// Implement axi_awready generation

// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always @( posedge S_AXI_ACLK)
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

always @(posedge S_AXI_ACLK) begin
    case(S_AXI_WSTRB)
    `ysyx_23060124_OPT_LSU_SB: begin  npc_pmem_write(axi_awaddr, S_AXI_WDATA, slv_reg_wren, 1); end
    `ysyx_23060124_OPT_LSU_SH: begin  npc_pmem_write(axi_awaddr, S_AXI_WDATA, slv_reg_wren, 2); end
    `ysyx_23060124_OPT_LSU_SW: begin  npc_pmem_write(axi_awaddr, S_AXI_WDATA, slv_reg_wren, 4); end
    default: begin 
        if(slv_reg_wren) begin
            $display("SRAM WIRTE ERROR: should not reach here");
            $finish;
        end
     end
    endcase
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


// Implement axi_arready generation

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

// Implement axi_araddr latching
//This process is used to latch the address when both 
//S_AXI_ARVALID and S_AXI_RVALID are valid. 

// always @( posedge S_AXI_ACLK )
// begin
//     if ( S_AXI_ARESETN == 1'b0 )
//     begin
//         axi_araddr <= 0;
//         axi_arlen_cntr <= 0;
//         axi_arburst <= 0;
//         axi_arlen <= 0;
//         axi_rlast <= 1'b0;
//         axi_ruser <= 0;
//     end 
//     else
//     begin    
//         if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
//         begin
//             // address latching 
//             axi_araddr <= S_AXI_ARADDR[`ysyx_23060124_ISA_ADDR_WIDTH - 1:0]; 
//             axi_arburst <= S_AXI_ARBURST; 
//             axi_arlen <= S_AXI_ARLEN;     
//             // start address of transfer
//             axi_arlen_cntr <= 0;
//             axi_rlast <= 1'b0;
//         end   
//         else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
//         begin
            
//             axi_arlen_cntr <= axi_arlen_cntr + 1;
//             axi_rlast <= 1'b0;
        
//             case (axi_arburst)
//             2'b00: // fixed burst
//                 // The read address for all the beats in the transaction are fixed
//                 begin
//                 axi_araddr       <= axi_araddr;        
//                 //for arsize = 4 bytes (010)
//                 end   
//             2'b01: //incremental burst
//             // The read address for all the beats in the transaction are increments by awsize
//                 begin
//                 axi_araddr[32 - 1:ADDR_LSB] <= axi_araddr[32 - 1:ADDR_LSB] + 1; 
//                 //araddr aligned to 4 byte boundary
//                 axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
//                 //for awsize = 4 bytes (010)
//                 end   
//             2'b10: //Wrapping burst
//             // The read address wraps when the address reaches wrap boundary 
//                 if (ar_wrap_en) 
//                 begin
//                     axi_araddr <= (axi_araddr - ar_wrap_size); 
//                 end
//                 else 
//                 begin
//                 axi_araddr[32 - 1:ADDR_LSB] <= axi_araddr[32 - 1:ADDR_LSB] + 1; 
//                 //araddr aligned to 4 byte boundary
//                 axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
//                 end                      
//             default: //reserved (incremental burst for example)
//                 begin
//                 axi_araddr <= axi_araddr[32 - 1:ADDR_LSB]+1;
//                 //for arsize = 4 bytes (010)
//                 end
//             endcase              
//         end
//         else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
//         begin
//             axi_rlast <= 1'b1;
//         end          
//         else if (S_AXI_RREADY)   
//         begin
//             axi_rlast <= 1'b0;
//         end          
//     end 
// end       
// Implement axi_arvalid generation

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
assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

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

endmodule