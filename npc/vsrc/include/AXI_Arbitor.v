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

    // CPU AXI-Lite Interface
    output reg         [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]CPU_AWADDR                ,
    output reg                          CPU_AWVALID               ,
    input                               CPU_AWREADY               ,
    output reg         [`ysyx_23060124_ISA_WIDTH-1:0]CPU_WDATA                 ,
    output reg                          CPU_WVALID                ,
    output reg         [`ysyx_23060124_OPT_WIDTH-1:0]CPU_WSTRB                 ,
    input                               CPU_WREADY                ,
    input              [   1:0]         CPU_BRESP                 ,
    input                               CPU_BVALID                ,
    output reg                          CPU_BREADY                ,
    output reg         [`ysyx_23060124_ISA_ADDR_WIDTH-1:0]CPU_ARADDR                ,
    output reg                          CPU_ARVALID               ,
    input                               CPU_ARREADY               ,
    input              [`ysyx_23060124_ISA_WIDTH-1:0]CPU_RDATA                 ,
    input              [   1:0]         CPU_RRESP                 ,
    input                               CPU_RVALID                ,
    output reg                          CPU_RREADY                 
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
                    if (CPU_BREADY || CPU_RREADY) begin
                        STATE <= IDLE;
                    end
                end
                LSU_ACCESS: begin
                    if (CPU_BREADY || CPU_RREADY) begin
                        STATE <= IDLE;
                    end
                end
                default: begin
                    $display("ARBITOR ERROR: should not reach here");
                    $finish;
                    STATE <= IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        CPU_AWADDR = 0;
        CPU_AWVALID = 0;
        CPU_WDATA = 0;
        CPU_WVALID = 0;
        CPU_WSTRB = 0;
        CPU_BREADY = 0;
        CPU_ARADDR = 0;
        CPU_ARVALID = 0;
        CPU_RREADY = 0;
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
        case (STATE)
            IDLE: begin
                // Already set default values above
                // Default values
            end
            IFU_ACCESS: begin
                CPU_AWADDR = IFU_AWADDR;
                CPU_AWVALID = IFU_AWVALID;
                CPU_WDATA = IFU_WDATA;
                CPU_WVALID = IFU_WVALID;
                CPU_WSTRB = IFU_WSTRB;
                CPU_BREADY = IFU_BREADY;
                CPU_ARADDR = IFU_ARADDR;
                CPU_ARVALID = IFU_ARVALID;
                CPU_RREADY = IFU_RREADY;

                IFU_AWREADY = CPU_AWREADY;
                IFU_WREADY = CPU_WREADY;
                IFU_BRESP = CPU_BRESP;
                IFU_BVALID = CPU_BVALID;
                IFU_ARREADY = CPU_ARREADY;
                IFU_RDATA = CPU_RDATA;
                IFU_RRESP = CPU_RRESP;
                IFU_RVALID = CPU_RVALID;
            end
            LSU_ACCESS: begin
                CPU_AWADDR = LSU_AWADDR;
                CPU_AWVALID = LSU_AWVALID;
                CPU_WDATA = LSU_WDATA;
                CPU_WVALID = LSU_WVALID;
                CPU_WSTRB = LSU_WSTRB;
                CPU_BREADY = LSU_BREADY;
                CPU_ARADDR = LSU_ARADDR;
                CPU_ARVALID = LSU_ARVALID;
                CPU_RREADY = LSU_RREADY;

                LSU_AWREADY = CPU_AWREADY;
                LSU_WREADY = CPU_WREADY;
                LSU_BRESP = CPU_BRESP;
                LSU_BVALID = CPU_BVALID;
                LSU_ARREADY = CPU_ARREADY;
                LSU_RDATA = CPU_RDATA;
                LSU_RRESP = CPU_RRESP;
                LSU_RVALID = CPU_RVALID;
            end
            default:begin
                $display("ARBITOR ERROR: should not reach here");
                $finish;
            end
        endcase
    end
endmodule
