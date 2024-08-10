module ysyx_23060124__icache #(
    parameter                           ADDR_WIDTH = 32            ,
    parameter                           DATA_WIDTH = 32            ,
    parameter                           CACHE_SIZE = 16            ,// Number of cache blocks 
    parameter                           WAY_NUMS = 4               ,// Block size in bytes
    parameter                           BYTES_NUMS = 4             ,
    parameter                           BLOCK_SIZE = 4*BYTES_NUMS   // Block size in bytes e.g 4bytes
)
(
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

    input  wire                         clk                        ,
    input  wire                         rst_n_sync                 ,
    input  wire        [ADDR_WIDTH-1:0] addr                       ,
    input  wire                         req                        ,// 请求信号
    output wire        [DATA_WIDTH-1:0] data                       ,

    input  wire                         fence_i                    ,
    output                              valid                       
);

localparam RINDEX_BITS = $clog2(BYTES_NUMS); //index = log2(CACHE_SIZE) = 4 = n
localparam INDEX_BITS = $clog2(WAY_NUMS); //index = log2(CACHE_SIZE) = 2 = n
localparam OFFSET_BITS = $clog2(BLOCK_SIZE); //offset = log2(BLOCK_SIZE) = 4 = m
localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS; //tag = 32 - 4 - 2 = 26

//ifu->icache
wire                                    hit                        ;
// AXI
/******************************regs*****************************/
    // Initiate AXI transactions
reg                                     INIT_AXI_TXN               ;
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                    [   RINDEX_BITS-1:0]read_index                 ;
reg                    [  31:0]         araddr                     ;
/******************************nets*****************************/
    // AXI clock signal
wire                                    M_AXI_ACLK                 ;
    // AXI active low reset signal
wire                                    M_AXI_ARESETN              ;
/******************************combinational logic*****************************/

    assign M_AXI_ARESETN = rst_n_sync;
    assign M_AXI_ACLK =  clk;
    
    //should not send write signal
    //Write Address (AW)
    assign M_AXI_AWVALID = 1'b0;
    assign M_AXI_AWADDR = 32'b0;
    assign M_AXI_AWLEN  = 'b0;
    assign M_AXI_AWSIZE = 'b0;
    assign M_AXI_AWBURST = 'b0;
    assign M_AXI_AWID = 'b0;
    //Write Data(W)
    assign M_AXI_WVALID = 1'b0;
    assign M_AXI_WDATA = 32'b0;
    assign M_AXI_WSTRB = 4'b0;
    assign M_AXI_WLAST = 1'b0;
    
    //Write Response (B)
    assign M_AXI_BREADY = 1'b0;

    //Read Address (AR)
    assign M_AXI_ARADDR = {addr[31:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    assign M_AXI_ARVALID    = axi_arvalid;
    assign M_AXI_ARID = 'b0;
    assign M_AXI_ARLEN = BLOCK_SIZE/4 - 1;
    assign M_AXI_ARSIZE = 3'b010;
    assign M_AXI_ARBURST = 2'b01; //incrementing burst
    //Read and Read Response (R)
    assign M_AXI_RREADY    = axi_rready;
    //Example design I/O

// Next address after ARREADY indicates previous address acceptance  
	  always @(posedge M_AXI_ACLK)                                       
	  begin                                                              
	    if (M_AXI_ARESETN == 0)                                          
	      begin                                                          
	        araddr <= 32'b0;                                           
	      end
        else if(req) begin
            araddr <= addr;
        end
        else if(M_AXI_RVALID && ~M_AXI_RREADY) begin
            araddr <= araddr + 4;
        end
        else if(M_AXI_RLAST) begin
            araddr <= addr;
        end                                                                                 
	    else                                                             
	      araddr <= araddr;                                      
	  end                                                                


//----------------------------
//Read Address Channel
//----------------------------       
    // A new axi_arvalid is asserted when there is a valid read address              
    // available by the master. start_single_read triggers a new read                
    // transaction                                                                   
    always @(posedge M_AXI_ACLK)                                                     
    begin                                                                            
    if (M_AXI_ARESETN == 0)                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if ((!hit) && req)                                                    
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

    // read index
    always @(posedge M_AXI_ACLK)                                                     
    begin                                                                            
    if ((!hit) && req)                                                   
        begin                                                                        
        read_index <= 'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if(M_AXI_RVALID && ~M_AXI_RREADY) begin
        read_index <= read_index + 1;   
    end                                        
    else read_index <= read_index;          
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

    //icache 


    // Cache storage arrays
reg                    [DATA_WIDTH-1:0] cache_data  [WAY_NUMS-1:0][BYTES_NUMS-1:0]                           ;
reg                    [TAG_BITS-1:0]   cache_tag   [WAY_NUMS-1:0]                           ;
reg                    [WAY_NUMS-1:0]   cache_valid                ;

    wire [TAG_BITS-1:0]   tag = M_AXI_ARADDR[ADDR_WIDTH-1:INDEX_BITS+OFFSET_BITS]; // tag = M_AXI_ARADDR[31:6]
    wire [INDEX_BITS-1:0] index = M_AXI_ARADDR[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]; // index = M_AXI_ARADDR[4+2:4]
    // wire [OFFSET_BITS-1:0] offset = M_AXI_ARADDR[OFFSET_BITS-1:0]; // offset = M_AXI_ARADDR[3:0]
    wire [OFFSET_BITS-3:0] offset = addr[OFFSET_BITS-1:2];
// Cache control logic 
always @(posedge clk)
begin
    if(~rst_n_sync) 
        begin
            cache_valid <= 'b0;
        end
    
    else if(M_AXI_RLAST && ~M_AXI_RREADY) begin
        cache_tag[index] <= tag;
        cache_valid[index] <= 1'b1;
    end
    else if(fence_i) begin
        cache_valid <= 'b0;
    end
end


always @(posedge clk) begin
    if(M_AXI_RVALID && ~axi_rready) begin
            cache_data [index][read_index] <= M_AXI_RDATA;
        end
end

assign valid =  hit || (M_AXI_RLAST && ~M_AXI_RREADY);
// assign data =   valid ? ( (offset == 2'b11) ? M_AXI_RDATA : cache_data[index][offset]) :32'b0;
assign data = hit ? cache_data[index][offset] : ((M_AXI_RLAST && ~M_AXI_RREADY) ? ( (offset == {{OFFSET_BITS-2}{1'b1}}) ? M_AXI_RDATA : cache_data[index][offset]) :32'b0);

assign hit  = (req && cache_valid[index] && cache_tag[index] == tag);


import "DPI-C" function void cache_hit ();
import "DPI-C" function void cache_miss ();

always @(posedge clk) begin
  if(hit && req) begin
    cache_hit();
  end
  else if(~hit && req) begin
    cache_miss();
  end
end

endmodule
