`include "para_defines.v"

module AXI_LITE_ARBITRATOR (
    input                               CLK                        ,
    input                               RESETN                     ,
    // IFU AXI-Lite Interface
    input                               IFU_AWVALID                ,
    input              [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]IFU_AWADDR                 ,
    output reg                          IFU_AWREADY                ,
    input                               IFU_WVALID                 ,
    input              [`ysyx_23060124_ISA_WIDTH-1:0]IFU_WDATA                  ,
    input              [`ysyx_23060124_OPT_WIDTH-1:0]IFU_WSTRB                  ,
    output reg                          IFU_WREADY                 ,
    output reg         [   1:0]         IFU_BRESP                  ,
    output reg                          IFU_BVALID                 ,
    input                               IFU_BREADY                 ,
    input                               IFU_ARVALID                ,
    input              [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]IFU_ARADDR                 ,
    output reg                          IFU_ARREADY                ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]IFU_RDATA                  ,
    output reg         [   1:0]         IFU_RRESP                  ,
    output reg                          IFU_RVALID                 ,
    input                               IFU_RREADY                 ,

    // LSU AXI-Lite Interface
    input                               LSU_AWVALID                ,
    input              [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]LSU_AWADDR                 ,
    output reg                          LSU_AWREADY                ,
    input                               LSU_WVALID                 ,
    input              [`ysyx_23060124_ISA_WIDTH-1:0]LSU_WDATA                  ,
    input              [`ysyx_23060124_OPT_WIDTH-1:0]LSU_WSTRB                  ,
    output reg                          LSU_WREADY                 ,
    output reg         [   1:0]         LSU_BRESP                  ,
    output reg                          LSU_BVALID                 ,
    input                               LSU_BREADY                 ,
    input                               LSU_ARVALID                ,
    input              [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]LSU_ARADDR                 ,
    output reg                          LSU_ARREADY                ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]LSU_RDATA                  ,
    output reg         [   1:0]         LSU_RRESP                  ,
    output reg                          LSU_RVALID                 ,
    input                               LSU_RREADY                 ,

    // SRAM AXI-Lite Interface
    output reg         [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]SRAM_AWADDR                ,
    output reg                          SRAM_AWVALID               ,
    input                               SRAM_AWREADY               ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]SRAM_WDATA                 ,
    output reg                          SRAM_WVALID                ,
    output reg         [`ysyx_23060124_OPT_WIDTH-1:0]SRAM_WSTRB                 ,
    input                               SRAM_WREADY                ,
    input              [   1:0]         SRAM_BRESP                 ,
    input                               SRAM_BVALID                ,
    output reg                          SRAM_BREADY                ,
    output reg         [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]SRAM_ARADDR                ,
    output reg                          SRAM_ARVALID               ,
    input                               SRAM_ARREADY               ,
    input              [`ysyx_23060124_ISA_WIDTH-1:0]SRAM_RDATA                 ,
    input              [   1:0]         SRAM_RRESP                 ,
    input                               SRAM_RVALID                ,
    output reg                          SRAM_RREADY                 
);
    // Arbitration state machine
    reg [1:0] STATE;
    localparam IFU_ACCESS = 2'b10;
    localparam LSU_ACCESS = 2'b01;
    localparam IDLE       = 2'b00;

    always @(posedge CLK or negedge RESETN) begin
        if (RESETN == 1'b0) begin
            STATE <= IDLE;
        end else begin
            case (STATE)
                IDLE: begin
                    if (IFU_AWVALID || IFU_ARVALID) begin
                        STATE <= IFU_ACCESS;
                    end else if (LSU_AWVALID || LSU_ARVALID) begin
                        STATE <= LSU_ACCESS;
                    end
                end
                IFU_ACCESS: begin
                    if (SRAM_BREADY || SRAM_RREADY) begin
                        STATE <= IDLE;
                    end
                end
                LSU_ACCESS: begin
                    if (SRAM_BREADY || SRAM_RREADY) begin
                        STATE <= IDLE;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (STATE)
            IDLE: begin
                // Already set default values above
                // Default values
                SRAM_AWADDR = 0;
                SRAM_AWVALID = 0;
                SRAM_WDATA = 0;
                SRAM_WVALID = 0;
                SRAM_WSTRB = 0;
                SRAM_BREADY = 0;
                SRAM_ARADDR = 0;
                SRAM_ARVALID = 0;
                SRAM_RREADY = 0;
                IFU_AWREADY = 0;
                IFU_WREADY = 0;
                IFU_BVALID = 0;
                IFU_ARREADY = 0;
                IFU_RVALID = 0;
                IFU_BRESP = 0;
                IFU_RDATA = 0;
                IFU_RRESP = 0;
                LSU_AWREADY = 0;
                LSU_WREADY = 0;
                LSU_BVALID = 0;
                LSU_ARREADY = 0;
                LSU_RVALID = 0;
                LSU_BRESP = 0;
                LSU_RDATA = 0;
                LSU_RRESP = 0;
            end
            IFU_ACCESS: begin
                SRAM_AWADDR = IFU_AWADDR;
                SRAM_AWVALID = IFU_AWVALID;
                SRAM_WDATA = IFU_WDATA;
                SRAM_WVALID = IFU_WVALID;
                SRAM_WSTRB = IFU_WSTRB;
                SRAM_BREADY = IFU_BREADY;
                SRAM_ARADDR = IFU_ARADDR;
                SRAM_ARVALID = IFU_ARVALID;
                SRAM_RREADY = IFU_RREADY;

                IFU_AWREADY = SRAM_AWREADY;
                IFU_WREADY = SRAM_WREADY;
                IFU_BRESP = SRAM_BRESP;
                IFU_BVALID = SRAM_BVALID;
                IFU_ARREADY = SRAM_ARREADY;
                IFU_RDATA = SRAM_RDATA;
                IFU_RRESP = SRAM_RRESP;
                IFU_RVALID = SRAM_RVALID;
            end
            LSU_ACCESS: begin
                SRAM_AWADDR = LSU_AWADDR;
                SRAM_AWVALID = LSU_AWVALID;
                SRAM_WDATA = LSU_WDATA;
                SRAM_WVALID = LSU_WVALID;
                SRAM_WSTRB = LSU_WSTRB;
                SRAM_BREADY = LSU_BREADY;
                SRAM_ARADDR = LSU_ARADDR;
                SRAM_ARVALID = LSU_ARVALID;
                SRAM_RREADY = LSU_RREADY;

                LSU_AWREADY = SRAM_AWREADY;
                LSU_WREADY = SRAM_WREADY;
                LSU_BRESP = SRAM_BRESP;
                LSU_BVALID = SRAM_BVALID;
                LSU_ARREADY = SRAM_ARREADY;
                LSU_RDATA = SRAM_RDATA;
                LSU_RRESP = SRAM_RRESP;
                LSU_RVALID = SRAM_RVALID;
            end
        endcase
    end
endmodule
