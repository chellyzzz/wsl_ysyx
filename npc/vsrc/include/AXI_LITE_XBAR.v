`include "para_defines.v"

module AXI_LITE_XBAR (
    input                               AXI_ACLK                   ,
    input                               AXI_ARESETN                ,
    // Master AXI-Lite Interface (from CPU or other master)
    input              [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]M_AXI_AWADDR               ,
    input                               M_AXI_AWVALID              ,
    output reg                          M_AXI_AWREADY              ,
    input              [  `ysyx_23060124_ISA_WIDTH-1:0]M_AXI_WDATA                ,
    input              [  `ysyx_23060124_OPT_WIDTH-1:0]M_AXI_WSTRB                ,
    input                               M_AXI_WVALID               ,
    output reg                          M_AXI_WREADY               ,
    output reg         [   1:0]         M_AXI_BRESP                ,
    output reg                          M_AXI_BVALID               ,
    input                               M_AXI_BREADY               ,
    input              [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]M_AXI_ARADDR               ,
    input                               M_AXI_ARVALID              ,
    output reg                          M_AXI_ARREADY              ,
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]M_AXI_RDATA                ,
    output reg         [   1:0]         M_AXI_RRESP                ,
    output reg                          M_AXI_RVALID               ,
    input                               M_AXI_RREADY               ,

    // UART AXI-Lite Interface
    output reg         [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]UART_AWADDR                ,
    output reg                          UART_AWVALID               ,
    input                               UART_AWREADY               ,
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]UART_WDATA                 ,
    output reg         [  `ysyx_23060124_OPT_WIDTH-1:0]UART_WSTRB                 ,
    output reg                          UART_WVALID                ,
    input                               UART_WREADY                ,
    input              [   1:0]         UART_BRESP                 ,
    input                               UART_BVALID                ,
    output reg                          UART_BREADY                ,
    output reg         [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]UART_ARADDR                ,
    output reg                          UART_ARVALID               ,
    input                               UART_ARREADY               ,
    input              [  `ysyx_23060124_ISA_WIDTH-1:0]UART_RDATA                 ,
    input              [   1:0]         UART_RRESP                 ,
    input                               UART_RVALID                ,
    output reg                          UART_RREADY                ,

    // UART AXI-Lite Interface
    output reg         [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]CLINT_AWADDR                ,
    output reg                          CLINT_AWVALID               ,
    input                               CLINT_AWREADY               ,
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]CLINT_WDATA                 ,
    output reg         [  `ysyx_23060124_OPT_WIDTH-1:0]CLINT_WSTRB                 ,
    output reg                          CLINT_WVALID                ,
    input                               CLINT_WREADY                ,
    input              [   1:0]         CLINT_BRESP                 ,
    input                               CLINT_BVALID                ,
    output reg                          CLINT_BREADY                ,
    output reg         [  `ysyx_23060124_ISA_ADDR_WIDTH-1:0]CLINT_ARADDR                ,
    output reg                          CLINT_ARVALID               ,
    input                               CLINT_ARREADY               ,
    input              [  `ysyx_23060124_ISA_WIDTH-1:0]CLINT_RDATA                 ,
    input              [   1:0]         CLINT_RRESP                 ,
    input                               CLINT_RVALID                ,
    output reg                          CLINT_RREADY                ,

    // SRAM AXI-Lite Interface
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]SRAM_AWADDR                ,
    output reg                          SRAM_AWVALID               ,
    input                               SRAM_AWREADY               ,
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]SRAM_WDATA                 ,
    output reg         [  `ysyx_23060124_OPT_WIDTH-1:0]SRAM_WSTRB                 ,
    output reg                          SRAM_WVALID                ,
    input                               SRAM_WREADY                ,
    input              [   1:0]         SRAM_BRESP                 ,
    input                               SRAM_BVALID                ,
    output reg                          SRAM_BREADY                ,
    output reg         [  `ysyx_23060124_ISA_WIDTH-1:0]SRAM_ARADDR                ,
    output reg                          SRAM_ARVALID               ,
    input                               SRAM_ARREADY               ,
    input              [  `ysyx_23060124_ISA_WIDTH-1:0]SRAM_RDATA                 ,
    input              [   1:0]         SRAM_RRESP                 ,
    input                               SRAM_RVALID                ,
    output reg                          SRAM_RREADY                 
);

    // Address range definitions
    localparam UART_ADDR_START = 32'ha000_03f8;
    localparam UART_ADDR_END   = 32'ha000_03ff;
    localparam CLINT_ADDR_START = 32'ha000_0048;
    localparam CLINT_ADDR_END   = 32'ha000_004f;
    localparam SRAM_ADDR_START = 32'h8000_0000;
    localparam SRAM_ADDR_END   = 32'h8FFF_FFFF;

    // state machine states
    localparam IDLE       = 3'b000;
    localparam UART_ACCESS = 3'b001;
    localparam CLINT_ACCESS = 3'b010;
    localparam SRAM_ACCESS = 3'b011;
    localparam ERROR      = 3'b111;

    reg [2:0] STATE;

    always @(posedge AXI_ACLK or negedge AXI_ARESETN) begin
        if (AXI_ARESETN == 1'b0) begin
            STATE <= IDLE;
        end else begin
            case (STATE)
                IDLE: begin
                    if (M_AXI_AWVALID || M_AXI_WVALID) begin
                        if (M_AXI_AWADDR >= UART_ADDR_START && M_AXI_AWADDR <= UART_ADDR_END) begin
                            STATE <= UART_ACCESS;
                        end 
                        else if (M_AXI_AWADDR >= SRAM_ADDR_START && M_AXI_AWADDR <= SRAM_ADDR_END) begin
                            STATE <= SRAM_ACCESS;
                        end 
                        else if(M_AXI_AWADDR >= CLINT_ADDR_START && M_AXI_AWADDR <= CLINT_ADDR_END) begin
                            STATE <= CLINT_ACCESS;
                        end
                        else begin
                            STATE <= ERROR;
                        end
                    end else if (M_AXI_ARVALID) begin
                        if (M_AXI_ARADDR >= UART_ADDR_START && M_AXI_ARADDR <= UART_ADDR_END) begin
                            STATE <= UART_ACCESS;
                        end 
                        else if (M_AXI_ARADDR >= SRAM_ADDR_START && M_AXI_ARADDR <= SRAM_ADDR_END) begin
                            STATE <= SRAM_ACCESS;
                        end 
                        else if (M_AXI_ARADDR >= CLINT_ADDR_START && M_AXI_ARADDR <= CLINT_ADDR_END) begin
                            STATE <= CLINT_ACCESS;
                        end 
                        else begin
                            STATE <= ERROR;
                        end
                    end
                end
                UART_ACCESS: begin
                    if (UART_BREADY || UART_RREADY) begin
                            STATE <= IDLE;
                    end
                end
                SRAM_ACCESS: begin
                    if (SRAM_BREADY || SRAM_RREADY) begin
                            STATE <= IDLE;
                    end
                end
                CLINT_ACCESS: begin
                    if (CLINT_BREADY || CLINT_RREADY) begin
                            STATE <= IDLE;
                    end
                end
                ERROR: begin
                    $display("XBAR ERROR: Invalid address");
                    $finish;
                    STATE <= IDLE;
                end
                default: begin
                    $display("XBAR ERROR: Invalid address");
                    $finish;
                    STATE <= IDLE;
                end
            endcase
        end
    end
    always @(*) begin
        SRAM_AWADDR = 0;
        SRAM_AWVALID = 0;
        SRAM_WDATA = 0;
        SRAM_WVALID = 0;
        SRAM_WSTRB = 0;
        SRAM_BREADY = 0;
        SRAM_ARADDR = 0;
        SRAM_ARVALID = 0;
        SRAM_RREADY = 0;

        UART_AWADDR = 0;
        UART_AWVALID = 0;
        UART_WDATA = 0;
        UART_WVALID = 0;
        UART_WSTRB = 0;
        UART_BREADY = 0;
        UART_ARADDR = 0;
        UART_ARVALID = 0;
        UART_RREADY = 0;

        CLINT_AWADDR = 0;
        CLINT_AWVALID = 0;
        CLINT_WDATA = 0;
        CLINT_WVALID = 0;
        CLINT_WSTRB = 0;
        CLINT_BREADY = 0;
        CLINT_ARADDR = 0;
        CLINT_ARVALID = 0;
        CLINT_RREADY = 0;

        M_AXI_AWREADY = 0;
        M_AXI_WREADY = 0;
        M_AXI_BVALID = 0;
        M_AXI_ARREADY = 0;
        M_AXI_RVALID = 0;
        M_AXI_BRESP = 0;
        M_AXI_RDATA = 0;
        M_AXI_RRESP = 0;
        case (STATE)
            IDLE: begin
                // Already set default values above
                // Default values
            end
            UART_ACCESS: begin
                UART_AWADDR = M_AXI_AWADDR;
                UART_AWVALID = M_AXI_AWVALID;
                UART_WDATA = M_AXI_WDATA;
                UART_WVALID = M_AXI_WVALID;
                UART_WSTRB = M_AXI_WSTRB;
                UART_BREADY = M_AXI_BREADY;
                UART_ARADDR = M_AXI_ARADDR;
                UART_ARVALID = M_AXI_ARVALID;
                UART_RREADY = M_AXI_RREADY;

                M_AXI_AWREADY = UART_AWREADY;
                M_AXI_WREADY = UART_WREADY;
                M_AXI_BRESP = UART_BRESP;
                M_AXI_BVALID = UART_BVALID;
                M_AXI_ARREADY = UART_ARREADY;
                M_AXI_RDATA = UART_RDATA;
                M_AXI_RRESP = UART_RRESP;
                M_AXI_RVALID = UART_RVALID;
            end
            SRAM_ACCESS: begin
                SRAM_AWADDR = M_AXI_AWADDR;
                SRAM_AWVALID = M_AXI_AWVALID;
                SRAM_WDATA = M_AXI_WDATA;
                SRAM_WVALID = M_AXI_WVALID;
                SRAM_WSTRB = M_AXI_WSTRB;
                SRAM_BREADY = M_AXI_BREADY;
                SRAM_ARADDR = M_AXI_ARADDR;
                SRAM_ARVALID = M_AXI_ARVALID;
                SRAM_RREADY = M_AXI_RREADY;

                M_AXI_AWREADY = SRAM_AWREADY;
                M_AXI_WREADY = SRAM_WREADY;
                M_AXI_BRESP = SRAM_BRESP;
                M_AXI_BVALID = SRAM_BVALID;
                M_AXI_ARREADY = SRAM_ARREADY;
                M_AXI_RDATA = SRAM_RDATA;
                M_AXI_RRESP = SRAM_RRESP;
                M_AXI_RVALID = SRAM_RVALID;
            end
            CLINT_ACCESS: begin
                CLINT_AWADDR = M_AXI_AWADDR;
                CLINT_AWVALID = M_AXI_AWVALID;
                CLINT_WDATA = M_AXI_WDATA;
                CLINT_WVALID = M_AXI_WVALID;
                CLINT_WSTRB = M_AXI_WSTRB;
                CLINT_BREADY = M_AXI_BREADY;
                CLINT_ARADDR = M_AXI_ARADDR;
                CLINT_ARVALID = M_AXI_ARVALID;
                CLINT_RREADY = M_AXI_RREADY;

                M_AXI_AWREADY = CLINT_AWREADY;
                M_AXI_WREADY = CLINT_WREADY;
                M_AXI_BRESP = CLINT_BRESP;
                M_AXI_BVALID = CLINT_BVALID;
                M_AXI_ARREADY = CLINT_ARREADY;
                M_AXI_RDATA = CLINT_RDATA;
                M_AXI_RRESP = CLINT_RRESP;
                M_AXI_RVALID = CLINT_RVALID;
            end
            ERROR: begin
                M_AXI_BRESP = 2'b11;  // DECERR
                M_AXI_RRESP = 2'b11;  // DECERR
            end 
            default:begin
                $display("XBAR ERROR: should not reach here");
                $finish;
            end
        endcase
    end
endmodule
