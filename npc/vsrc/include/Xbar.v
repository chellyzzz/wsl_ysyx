 

module ysyx_23060124_Xbar(
    input                               CLK                        ,
    input                               RESETN                     ,
    // IFU AXI-FULL Interface
    output             [32-1 : 0]       IFU_RDATA                  ,
    output             [   1:0]         IFU_RRESP                  ,
    output                              IFU_RVALID                 ,
    input                               IFU_RREADY                 ,
    output                              IFU_RLAST                  ,
    output             [4-1 : 0]        IFU_RID                    ,
    input              [32-1 : 0]       IFU_ARADDR                 ,
    input                               IFU_ARVALID                ,
    output                              IFU_ARREADY                ,
    input              [4-1 : 0]        IFU_ARID                   ,
    input              [   7:0]         IFU_ARLEN                  ,
    input              [   2:0]         IFU_ARSIZE                 ,
    input              [   1:0]         IFU_ARBURST                ,
    output             [   1:0]         IFU_BRESP                  ,
    output                              IFU_BVALID                 ,
    input                               IFU_BREADY                 ,
    output             [4-1 : 0]        IFU_BID                    ,
    input              [32-1 : 0]       IFU_AWADDR                 ,
    input                               IFU_AWVALID                ,
    output                              IFU_AWREADY                ,
    input              [4-1 : 0]        IFU_AWID                   ,
    input              [   7:0]         IFU_AWLEN                  ,
    input              [   2:0]         IFU_AWSIZE                 ,
    input              [   1:0]         IFU_AWBURST                ,
    input              [32-1 : 0]       IFU_WDATA                  ,
    input              [4-1 : 0]        IFU_WSTRB                  ,
    input                               IFU_WVALID                 ,
    input                               IFU_WLAST                  ,
    output                              IFU_WREADY                 ,
    
    // LSU AXI-FULL Interface
    output             [32-1 : 0]       LSU_RDATA                  ,
    output             [   1:0]         LSU_RRESP                  ,
    output                              LSU_RVALID                 ,
    input                               LSU_RREADY                 ,
    output                              LSU_RLAST                  ,
    output             [4-1 : 0]        LSU_RID                    ,
    input              [32-1 : 0]       LSU_ARADDR                 ,
    input                               LSU_ARVALID                ,
    output                              LSU_ARREADY                ,
    input              [4-1 : 0]        LSU_ARID                   ,
    input              [   7:0]         LSU_ARLEN                  ,
    input              [   2:0]         LSU_ARSIZE                 ,
    input              [   1:0]         LSU_ARBURST                ,
    output             [   1:0]         LSU_BRESP                  ,
    output                              LSU_BVALID                 ,
    input                               LSU_BREADY                 ,
    output             [4-1 : 0]        LSU_BID                    ,
    input              [32-1 : 0]       LSU_AWADDR                 ,
    input                               LSU_AWVALID                ,
    output                              LSU_AWREADY                ,
    input              [4-1 : 0]        LSU_AWID                   ,
    input              [   7:0]         LSU_AWLEN                  ,
    input              [   2:0]         LSU_AWSIZE                 ,
    input              [   1:0]         LSU_AWBURST                ,
    input              [32-1 : 0]       LSU_WDATA                  ,
    input              [4-1 : 0]        LSU_WSTRB                  ,
    input                               LSU_WVALID                 ,
    input                               LSU_WLAST                  ,
    output                              LSU_WREADY                 ,


        //clint
    output             [  32-1:0]       CLINT_AWADDR               ,
    output                              CLINT_AWVALID              ,
    input                               CLINT_AWREADY              ,
    output             [4-1 : 0]        CLINT_AWID                 ,
    output             [   7:0]         CLINT_AWLEN                ,
    output             [   2:0]         CLINT_AWSIZE               ,
    output             [   1:0]         CLINT_AWBURST              ,
    output             [  32-1:0]       CLINT_WDATA                ,
    output             [  4-1:0]        CLINT_WSTRB                ,
    output                              CLINT_WVALID               ,
    input                               CLINT_WREADY               ,
    input                               CLINT_WLAST                ,
    input              [   1:0]         CLINT_BRESP                ,
    input                               CLINT_BVALID               ,
    output                              CLINT_BREADY               ,
    input              [4-1 : 0]        CLINT_BID                  ,
    output             [  32-1:0]       CLINT_ARADDR               ,
    output             [4-1 : 0]        CLINT_ARID                 ,
    output                              CLINT_ARVALID              ,
    input                               CLINT_ARREADY              ,
    output             [   7:0]         CLINT_ARLEN                ,
    output             [   2:0]         CLINT_ARSIZE               ,
    output             [   1:0]         CLINT_ARBURST              ,
    input              [  32-1:0]       CLINT_RDATA                ,
    input              [   1:0]         CLINT_RRESP                ,
    input                               CLINT_RVALID               ,
    output                              CLINT_RREADY               ,
    input              [4-1 : 0]        CLINT_RID                  ,
    input                               CLINT_RLAST                ,

    // SRAM AXI-Lite Interface
    output             [  32-1:0]       SRAM_AWADDR                ,
    output                              SRAM_AWVALID               ,
    input                               SRAM_AWREADY               ,
    output             [4-1 : 0]        SRAM_AWID                  ,
    output             [   7:0]         SRAM_AWLEN                 ,
    output             [   2:0]         SRAM_AWSIZE                ,
    output             [   1:0]         SRAM_AWBURST               ,
    output             [  32-1:0]       SRAM_WDATA                 ,
    output             [  4-1:0]        SRAM_WSTRB                 ,
    output                              SRAM_WVALID                ,
    input                               SRAM_WREADY                ,
    input                               SRAM_WLAST                 ,
    input              [   1:0]         SRAM_BRESP                 ,
    input                               SRAM_BVALID                ,
    output                              SRAM_BREADY                ,
    input              [4-1 : 0]        SRAM_BID                   ,
    output             [  32-1:0]       SRAM_ARADDR                ,
    output             [4-1 : 0]        SRAM_ARID                  ,
    output                              SRAM_ARVALID               ,
    input                               SRAM_ARREADY               ,
    output             [   7:0]         SRAM_ARLEN                 ,
    output             [   2:0]         SRAM_ARSIZE                ,
    output             [   1:0]         SRAM_ARBURST               ,
    input              [  32-1:0]       SRAM_RDATA                 ,
    input              [   1:0]         SRAM_RRESP                 ,
    input                               SRAM_RVALID                ,
    output                              SRAM_RREADY                ,
    input              [4-1 : 0]        SRAM_RID                   ,
    input                               SRAM_RLAST                  

);

    // Arbitration state machine
    reg [1:0] IN_STATE;
    localparam IFU_ACCESS = 2'b10;
    localparam LSU_ACCESS = 2'b01;
    localparam IN_IDLE       = 2'b00;

    reg [2:0] OUT_STATE;
    // Address range definitions
    localparam CLINT_ADDR_START = 32'h0200_0000;
    localparam CLINT_ADDR_END   = 32'h0200_ffff;
    localparam OUT_IDLE       = 3'b000;
    localparam CLINT_ACCESS = 3'b010;
    localparam SRAM_ACCESS = 3'b001;
/*************      wires   *********************/
//write address channel  
wire                   [32-1 : 0]       CPU_AWADDR                 ;
wire                                    CPU_AWVALID                ;
wire                                    CPU_AWREADY                ;
wire                   [   7:0]         CPU_AWLEN                  ;
wire                   [   2:0]         CPU_AWSIZE                 ;
wire                   [   1:0]         CPU_AWBURST                ;
wire                   [   3:0]         CPU_AWID                   ;
//write data channel,
wire                                    CPU_WVALID                 ;
wire                                    CPU_WREADY                 ;
wire                   [32-1 : 0]       CPU_WDATA                  ;
wire                   [4-1 : 0]        CPU_WSTRB                  ;
wire                                    CPU_WLAST                  ;
//read data channel
wire                   [32-1 : 0]       CPU_RDATA                  ;
wire                   [   1:0]         CPU_RRESP                  ;
wire                                    CPU_RVALID                 ;
wire                                    CPU_RREADY                 ;
wire                   [4-1 : 0]        CPU_RID                    ;
wire                                    CPU_RLAST                  ;
    
//read adress channel
wire                   [32-1 : 0]       CPU_ARADDR                 ;
wire                                    CPU_ARVALID                ;
wire                                    CPU_ARREADY                ;
wire                   [4-1 : 0]        CPU_ARID                   ;
wire                   [   7:0]         CPU_ARLEN                  ;
wire                   [   2:0]         CPU_ARSIZE                 ;
wire                   [   1:0]         CPU_ARBURST                ;
//write back channel
wire                   [   1:0]         CPU_BRESP                  ;
wire                                    CPU_BVALID                 ;
wire                                    CPU_BREADY                 ;
wire                   [4-1 : 0]        CPU_BID                    ;

/*************  state machine  ******************/
    always @(posedge CLK or negedge RESETN) begin
        if (RESETN == 1'b0) begin
            IN_STATE <= IN_IDLE;
        end else begin
            case (IN_STATE)
                IN_IDLE: begin
                    if (IFU_AWVALID || IFU_ARVALID) begin
                        IN_STATE <= IFU_ACCESS;
                    end else if (LSU_AWVALID || LSU_ARVALID) begin
                        IN_STATE <= LSU_ACCESS;
                    end
                end
                IFU_ACCESS: begin
                    if (CPU_BREADY || CPU_RREADY) begin
                        IN_STATE <= IN_IDLE;
                    end
                end
                LSU_ACCESS: begin
                    if (CPU_BREADY || CPU_RREADY) begin
                        IN_STATE <= IN_IDLE;
                    end
                end
                default: begin
                    IN_STATE <= IN_IDLE;
                end
            endcase
        end
    end
    
    always @(posedge CLK or negedge RESETN) begin
        if (RESETN == 1'b0) begin
            OUT_STATE <= OUT_IDLE;
        end else begin
            case (OUT_STATE)
                OUT_IDLE: begin
                    if (CPU_AWVALID || CPU_WVALID) begin
                        if(CPU_AWADDR >= CLINT_ADDR_START && CPU_AWADDR <= CLINT_ADDR_END) begin
                            OUT_STATE <= CLINT_ACCESS;
                        end
                        else begin
                            OUT_STATE <= SRAM_ACCESS;
                        end
                    end else if (CPU_ARVALID) begin
                        if (CPU_ARADDR >= CLINT_ADDR_START && CPU_ARADDR <= CLINT_ADDR_END) begin
                            OUT_STATE <= CLINT_ACCESS;
                        end 
                        else begin
                            OUT_STATE <= SRAM_ACCESS;
                        end
                    end
                end
                SRAM_ACCESS: begin
                    if (SRAM_BREADY || SRAM_RREADY) begin
                            OUT_STATE <= OUT_IDLE;
                    end
                end
                CLINT_ACCESS: begin
                    if (CLINT_BREADY || CLINT_RREADY) begin
                            OUT_STATE <= OUT_IDLE;
                    end
                end
                default: begin
                    OUT_STATE <= OUT_IDLE;
                end
            endcase
        end
    end


// CPU signals
assign CPU_AWADDR  = (IN_STATE == IFU_ACCESS) ? IFU_AWADDR  : (IN_STATE == LSU_ACCESS) ? LSU_AWADDR  : 0;
assign CPU_AWVALID = (IN_STATE == IFU_ACCESS) ? IFU_AWVALID : (IN_STATE == LSU_ACCESS) ? LSU_AWVALID : 0;
assign CPU_AWLEN   = (IN_STATE == IFU_ACCESS) ? IFU_AWLEN   : (IN_STATE == LSU_ACCESS) ? LSU_AWLEN   : 0;
assign CPU_AWSIZE  = (IN_STATE == IFU_ACCESS) ? IFU_AWSIZE  : (IN_STATE == LSU_ACCESS) ? LSU_AWSIZE  : 0;
assign CPU_AWBURST = (IN_STATE == IFU_ACCESS) ? IFU_AWBURST : (IN_STATE == LSU_ACCESS) ? LSU_AWBURST : 0;
assign CPU_AWID    = (IN_STATE == IFU_ACCESS) ? IFU_AWID    : (IN_STATE == LSU_ACCESS) ? LSU_AWID    : 0;
assign CPU_WDATA   = (IN_STATE == IFU_ACCESS) ? IFU_WDATA   : (IN_STATE == LSU_ACCESS) ? LSU_WDATA   : 0;
assign CPU_WVALID  = (IN_STATE == IFU_ACCESS) ? IFU_WVALID  : (IN_STATE == LSU_ACCESS) ? LSU_WVALID  : 0;
assign CPU_WSTRB   = (IN_STATE == IFU_ACCESS) ? IFU_WSTRB   : (IN_STATE == LSU_ACCESS) ? LSU_WSTRB   : 0;
assign CPU_BREADY  = (IN_STATE == IFU_ACCESS) ? IFU_BREADY  : (IN_STATE == LSU_ACCESS) ? LSU_BREADY  : 0;
assign CPU_ARADDR  = (IN_STATE == IFU_ACCESS) ? IFU_ARADDR  : (IN_STATE == LSU_ACCESS) ? LSU_ARADDR  : 0;
assign CPU_ARVALID = (IN_STATE == IFU_ACCESS) ? IFU_ARVALID : (IN_STATE == LSU_ACCESS) ? LSU_ARVALID : 0;
assign CPU_ARLEN   = (IN_STATE == IFU_ACCESS) ? IFU_ARLEN   : (IN_STATE == LSU_ACCESS) ? LSU_ARLEN   : 0;
assign CPU_ARSIZE  = (IN_STATE == IFU_ACCESS) ? IFU_ARSIZE  : (IN_STATE == LSU_ACCESS) ? LSU_ARSIZE  : 0;
assign CPU_ARBURST = (IN_STATE == IFU_ACCESS) ? IFU_ARBURST : (IN_STATE == LSU_ACCESS) ? LSU_ARBURST : 0;
assign CPU_ARID    = (IN_STATE == IFU_ACCESS) ? IFU_ARID    : (IN_STATE == LSU_ACCESS) ? LSU_ARID    : 0;
assign CPU_RREADY  = (IN_STATE == IFU_ACCESS) ? IFU_RREADY  : (IN_STATE == LSU_ACCESS) ? LSU_RREADY  : 0;

// IFU signals
assign IFU_AWREADY = (IN_STATE == IFU_ACCESS) ? CPU_AWREADY : 0;
assign IFU_WREADY  = (IN_STATE == IFU_ACCESS) ? CPU_WREADY  : 0;
assign IFU_BVALID  = (IN_STATE == IFU_ACCESS) ? CPU_BVALID  : 0;
assign IFU_ARREADY = (IN_STATE == IFU_ACCESS) ? CPU_ARREADY : 0;
assign IFU_RVALID  = (IN_STATE == IFU_ACCESS) ? CPU_RVALID  : 0;
assign IFU_BRESP   = (IN_STATE == IFU_ACCESS) ? CPU_BRESP   : 0;
assign IFU_BID     = (IN_STATE == IFU_ACCESS) ? CPU_BID     : 0;
assign IFU_RDATA   = (IN_STATE == IFU_ACCESS) ? CPU_RDATA   : 0;
assign IFU_RRESP   = (IN_STATE == IFU_ACCESS) ? CPU_RRESP   : 0;
assign IFU_RLAST   = (IN_STATE == IFU_ACCESS) ? CPU_RLAST   : 0;
assign IFU_RID     = (IN_STATE == IFU_ACCESS) ? CPU_RID     : 0;

// LSU signals
assign LSU_AWREADY = (IN_STATE == LSU_ACCESS) ? CPU_AWREADY : 0;
assign LSU_WREADY  = (IN_STATE == LSU_ACCESS) ? CPU_WREADY  : 0;
assign LSU_BVALID  = (IN_STATE == LSU_ACCESS) ? CPU_BVALID  : 0;
assign LSU_ARREADY = (IN_STATE == LSU_ACCESS) ? CPU_ARREADY : 0;
assign LSU_RVALID  = (IN_STATE == LSU_ACCESS) ? CPU_RVALID  : 0;
assign LSU_BRESP   = (IN_STATE == LSU_ACCESS) ? CPU_BRESP   : 0;
assign LSU_BID     = (IN_STATE == LSU_ACCESS) ? CPU_BID     : 0;
assign LSU_RDATA   = (IN_STATE == LSU_ACCESS) ? CPU_RDATA   : 0;
assign LSU_RRESP   = (IN_STATE == LSU_ACCESS) ? CPU_RRESP   : 0;
assign LSU_RLAST   = (IN_STATE == LSU_ACCESS) ? CPU_RLAST   : 0;
assign LSU_RID     = (IN_STATE == LSU_ACCESS) ? CPU_RID     : 0;

// SRAM signals
assign SRAM_AWADDR  = (OUT_STATE == SRAM_ACCESS) ? CPU_AWADDR  : 0;
assign SRAM_AWVALID = (OUT_STATE == SRAM_ACCESS) ? CPU_AWVALID : 0;
assign SRAM_AWID    = (OUT_STATE == SRAM_ACCESS) ? CPU_AWID    : 0;
assign SRAM_WDATA   = (OUT_STATE == SRAM_ACCESS) ? CPU_WDATA   : 0;
assign SRAM_WVALID  = (OUT_STATE == SRAM_ACCESS) ? CPU_WVALID  : 0;
assign SRAM_WSTRB   = (OUT_STATE == SRAM_ACCESS) ? CPU_WSTRB   : 0;
assign SRAM_BREADY  = (OUT_STATE == SRAM_ACCESS) ? CPU_BREADY  : 0;
assign SRAM_ARADDR  = (OUT_STATE == SRAM_ACCESS) ? CPU_ARADDR  : 0;
assign SRAM_ARID    = (OUT_STATE == SRAM_ACCESS) ? CPU_ARID    : 0;
assign SRAM_ARVALID = (OUT_STATE == SRAM_ACCESS) ? CPU_ARVALID : 0;
assign SRAM_RREADY  = (OUT_STATE == SRAM_ACCESS) ? CPU_RREADY  : 0;
assign SRAM_AWLEN   = (OUT_STATE == SRAM_ACCESS) ? CPU_AWLEN   : 0;
assign SRAM_AWSIZE  = (OUT_STATE == SRAM_ACCESS) ? CPU_AWSIZE  : 0;
assign SRAM_AWBURST = (OUT_STATE == SRAM_ACCESS) ? CPU_AWBURST : 0;
assign SRAM_ARLEN   = (OUT_STATE == SRAM_ACCESS) ? CPU_ARLEN   : 0;
assign SRAM_ARSIZE  = (OUT_STATE == SRAM_ACCESS) ? CPU_ARSIZE  : 0;
assign SRAM_ARBURST = (OUT_STATE == SRAM_ACCESS) ? CPU_ARBURST : 0;

// CLINT signals
assign CLINT_AWADDR  = (OUT_STATE == CLINT_ACCESS) ? CPU_AWADDR  : 0;
assign CLINT_AWVALID = (OUT_STATE == CLINT_ACCESS) ? CPU_AWVALID : 0;
assign CLINT_AWID    = (OUT_STATE == CLINT_ACCESS) ? CPU_AWID    : 0;
assign CLINT_WDATA   = (OUT_STATE == CLINT_ACCESS) ? CPU_WDATA   : 0;
assign CLINT_WVALID  = (OUT_STATE == CLINT_ACCESS) ? CPU_WVALID  : 0;
assign CLINT_WSTRB   = (OUT_STATE == CLINT_ACCESS) ? CPU_WSTRB   : 0;
assign CLINT_BREADY  = (OUT_STATE == CLINT_ACCESS) ? CPU_BREADY  : 0;
assign CLINT_ARADDR  = (OUT_STATE == CLINT_ACCESS) ? CPU_ARADDR  : 0;
assign CLINT_ARVALID = (OUT_STATE == CLINT_ACCESS) ? CPU_ARVALID : 0;
assign CLINT_ARID    = (OUT_STATE == CLINT_ACCESS) ? CPU_ARID    : 0;
assign CLINT_RREADY  = (OUT_STATE == CLINT_ACCESS) ? CPU_RREADY  : 0;
assign CLINT_AWLEN   = (OUT_STATE == CLINT_ACCESS) ? CPU_AWLEN   : 0;
assign CLINT_AWSIZE  = (OUT_STATE == CLINT_ACCESS) ? CPU_AWSIZE  : 0;
assign CLINT_AWBURST = (OUT_STATE == CLINT_ACCESS) ? CPU_AWBURST : 0;
assign CLINT_ARLEN   = (OUT_STATE == CLINT_ACCESS) ? CPU_ARLEN   : 0;
assign CLINT_ARSIZE  = (OUT_STATE == CLINT_ACCESS) ? CPU_ARSIZE  : 0;
assign CLINT_ARBURST = (OUT_STATE == CLINT_ACCESS) ? CPU_ARBURST : 0;

// CPU signals
assign CPU_AWREADY = (OUT_STATE == SRAM_ACCESS) ? SRAM_AWREADY : (OUT_STATE == CLINT_ACCESS) ? CLINT_AWREADY : 0;
assign CPU_WREADY  = (OUT_STATE == SRAM_ACCESS) ? SRAM_WREADY  : (OUT_STATE == CLINT_ACCESS) ? CLINT_WREADY  : 0;
assign CPU_BVALID  = (OUT_STATE == SRAM_ACCESS) ? SRAM_BVALID  : (OUT_STATE == CLINT_ACCESS) ? CLINT_BVALID  : 0;
assign CPU_ARREADY = (OUT_STATE == SRAM_ACCESS) ? SRAM_ARREADY : (OUT_STATE == CLINT_ACCESS) ? CLINT_ARREADY : 0;
assign CPU_RVALID  = (OUT_STATE == SRAM_ACCESS) ? SRAM_RVALID  : (OUT_STATE == CLINT_ACCESS) ? CLINT_RVALID  : 0;
assign CPU_BRESP   = (OUT_STATE == SRAM_ACCESS) ? SRAM_BRESP   : (OUT_STATE == CLINT_ACCESS) ? CLINT_BRESP   : 0;
assign CPU_RDATA   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RDATA   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RDATA   : 0;
assign CPU_RRESP   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RRESP   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RRESP   : 0;
assign CPU_BID     = (OUT_STATE == SRAM_ACCESS) ? SRAM_BID     : (OUT_STATE == CLINT_ACCESS) ? CLINT_BID     : 0;
assign CPU_RLAST   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RLAST   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RLAST   : 0;
assign CPU_RID     = (OUT_STATE == SRAM_ACCESS) ? SRAM_RID     : (OUT_STATE == CLINT_ACCESS) ? CLINT_RID     : 0;

endmodule