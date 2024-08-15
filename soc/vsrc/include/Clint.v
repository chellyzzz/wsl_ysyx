module CLINT(
    input                               clock                      ,
    input                               S_AXI_ARESETN              ,
    //read data channel
    output             [  31:0]         S_AXI_RDATA                ,
    output             [   1:0]         S_AXI_RRESP                ,
    output                              S_AXI_RVALID               ,
    input                               S_AXI_RREADY               ,
    output                              S_AXI_RLAST                ,
    output             [   3:0]         S_AXI_RID                  ,

    //read adress channel
    input              [  31:0]         S_AXI_ARADDR               ,
    input                               S_AXI_ARVALID              ,
    output                              S_AXI_ARREADY              ,
    input              [   3:0]         S_AXI_ARID                 ,
    input              [   7:0]         S_AXI_ARLEN                ,
    input              [   2:0]         S_AXI_ARSIZE               ,
    input              [   1:0]         S_AXI_ARBURST              ,

    //write back channel
    output             [   1:0]         S_AXI_BRESP                ,
    output                              S_AXI_BVALID               ,
    input                               S_AXI_BREADY               ,
    output             [   3:0]         S_AXI_BID                  ,

    //write address channel  
    input              [  31:0]         S_AXI_AWADDR               ,
    input                               S_AXI_AWVALID              ,
    output                              S_AXI_AWREADY              ,
    input              [   3:0]         S_AXI_AWID                 ,
    input              [   7:0]         S_AXI_AWLEN                ,
    input              [   2:0]         S_AXI_AWSIZE               ,
    input              [   1:0]         S_AXI_AWBURST              ,

    //write data channel
    input              [  31:0]         S_AXI_WDATA                ,
    input              [   3:0]         S_AXI_WSTRB                ,
    input                               S_AXI_WVALID               ,
    input                               S_AXI_WLAST                ,
    output                              S_AXI_WREADY                
);

/**********************regs******************************/
reg                                     axi_araddr                 ;
reg                                     axi_arready                ;
//rdata?
reg                    [  31:0]         axi_rdata                  ;
reg                                     axi_rvalid                 ;
// clint 
reg                    [  63:0]         reg_mtime                  ;

/**********************wire******************************/
wire                                    slv_reg_rden               ;

// I/O Connections assignments

assign S_AXI_AWREADY    = 'b0;
assign S_AXI_WREADY     = 'b0;
assign S_AXI_BRESP      = 'b0;
assign S_AXI_BVALID     = 'b0;
assign S_AXI_ARREADY    = axi_arready;
assign S_AXI_RDATA      = axi_rdata;
assign S_AXI_RRESP      = 2'b0;
assign S_AXI_RVALID     = axi_rvalid;
assign S_AXI_RLAST      = 1'b1;
assign S_AXI_RID        = 4'b0;
assign S_AXI_BID        = 4'b0;

//mtime ++ per clock cycle
always @( posedge clock or negedge S_AXI_ARESETN)
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        reg_mtime <= 0;
    end 
    else
    begin    
        reg_mtime <= reg_mtime + 1'b1;
    end 
end  

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_arready <= 1'b0;
    end 
    else
    begin    
        if (~axi_arready && S_AXI_ARVALID)
        begin
            // indicates that the slave has acceped the valid read address
            axi_arready <= 1'b1;
            axi_araddr  <= S_AXI_ARADDR[2];
            // Read address latching
        end
        else
        begin
            axi_arready <= 1'b0;
        end
    end 
end       

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_rvalid <= 0;
    end 
    else
    begin    
        if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
            // Valid read data is available at the read data bus
            axi_rvalid <= 1'b1;
        end   
        else if (axi_rvalid && S_AXI_RREADY)
        begin
            // Read data is accepted by the master
            axi_rvalid <= 1'b0;
        end                
    end
end    

assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

// Output register or memory read data
always @( posedge clock )
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
        if (slv_reg_rden && ~axi_araddr)
        begin
            axi_rdata <= reg_mtime[31 : 0];     // register read data
        end
        else if (slv_reg_rden && axi_araddr)
        begin
            axi_rdata <= reg_mtime[63 : 32];     // register read data
        end
    end
end    

endmodule
