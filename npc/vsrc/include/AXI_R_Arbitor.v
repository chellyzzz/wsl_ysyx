module AXI_LITE_ARBITRATOR (
    input CLK,
    input RESETN,
    // IFU AXI-Lite Interface
    input IFU_AWVALID,
    input [31:0] IFU_AWADDR,
    output reg IFU_AWREADY,
    input IFU_WVALID,
    input [31:0] IFU_WDATA,
    output reg IFU_WREADY,
    output reg [1:0] IFU_BRESP,
    output reg IFU_BVALID,
    input IFU_BREADY,
    input IFU_ARVALID,
    input [31:0] IFU_ARADDR,
    output reg IFU_ARREADY,
    output reg [31:0] IFU_RDATA,
    output reg [1:0] IFU_RRESP,
    output reg IFU_RVALID,
    input IFU_RREADY,

    // LSU AXI-Lite Interface
    input LSU_AWVALID,
    input [31:0] LSU_AWADDR,
    output reg LSU_AWREADY,
    input LSU_WVALID,
    input [31:0] LSU_WDATA,
    output reg LSU_WREADY,
    output reg [1:0] LSU_BRESP,
    output reg LSU_BVALID,
    input LSU_BREADY,
    input LSU_ARVALID,
    input [31:0] LSU_ARADDR,
    output reg LSU_ARREADY,
    output reg [31:0] LSU_RDATA,
    output reg [1:0] LSU_RRESP,
    output reg LSU_RVALID,
    input LSU_RREADY,

    // SRAM AXI-Lite Interface
    output reg [31:0] SRAM_AWADDR,
    output reg SRAM_AWVALID,
    input SRAM_AWREADY,
    output reg [31:0] SRAM_WDATA,
    output reg SRAM_WVALID,
    input SRAM_WREADY,
    input [1:0] SRAM_BRESP,
    input SRAM_BVALID,
    output reg SRAM_BREADY,
    output reg [31:0] SRAM_ARADDR,
    output reg SRAM_ARVALID,
    input SRAM_ARREADY,
    input [31:0] SRAM_RDATA,
    input [1:0] SRAM_RRESP,
    input SRAM_RVALID,
    output reg SRAM_RREADY
);
    // Arbitration state machine
    reg [1:0] STATE;
    localparam IFU_ACCESS = 2'b00;
    localparam LSU_ACCESS = 2'b01;
    localparam IDLE       = 2'b10;

    always @(posedge CLK or posedge RESETN) begin
        if (RESETN) begin
            STATE <= IDLE;
            SRAM_AWVALID <= 0;
            SRAM_WVALID <= 0;
            SRAM_ARVALID <= 0;
            SRAM_BREADY <= 0;
            SRAM_RREADY <= 0;
            IFU_AWREADY <= 0;
            IFU_WREADY <= 0;
            IFU_BVALID <= 0;
            IFU_ARREADY <= 0;
            IFU_RVALID <= 0;
            LSU_AWREADY <= 0;
            LSU_WREADY <= 0;
            LSU_BVALID <= 0;
            LSU_ARREADY <= 0;
            LSU_RVALID <= 0;
        end else begin
            case (STATE)
                IDLE: begin
                    if (IFU_AWVALID || IFU_ARVALID) begin
                        STATE <= IFU_ACCESS;
                        SRAM_AWVALID <= IFU_AWVALID;
                        SRAM_AWADDR <= IFU_AWADDR;
                        SRAM_WVALID <= IFU_WVALID;
                        SRAM_WDATA <= IFU_WDATA;
                        SRAM_ARVALID <= IFU_ARVALID;
                        SRAM_ARADDR <= IFU_ARADDR;
                        SRAM_RREADY <= IFU_RREADY;
                        SRAM_BREADY <= IFU_BREADY;
                    end else if (LSU_AWVALID || LSU_ARVALID) begin
                        STATE <= LSU_ACCESS;
                        SRAM_AWVALID <= LSU_AWVALID;
                        SRAM_AWADDR <= LSU_AWADDR;
                        SRAM_WVALID <= LSU_WVALID;
                        SRAM_WDATA <= LSU_WDATA;
                        SRAM_ARVALID <= LSU_ARVALID;
                        SRAM_ARADDR <= LSU_ARADDR;
                        SRAM_RREADY <= LSU_RREADY;
                        SRAM_BREADY <= LSU_BREADY;
                    end
                end
                IFU_ACCESS: begin
                    if (!IFU_AWVALID && !IFU_ARVALID) begin
                        STATE <= IDLE;
                    end
                    IFU_AWREADY <= SRAM_AWREADY;
                    IFU_WREADY <= SRAM_WREADY;
                    IFU_BRESP <= SRAM_BRESP;
                    IFU_BVALID <= SRAM_BVALID;
                    IFU_ARREADY <= SRAM_ARREADY;
                    IFU_RDATA <= SRAM_RDATA;
                    IFU_RRESP <= SRAM_RRESP;
                    IFU_RVALID <= SRAM_RVALID;
                end
                LSU_ACCESS: begin
                    if (!LSU_AWVALID && !LSU_ARVALID) begin
                        STATE <= IDLE;
                    end
                    LSU_AWREADY <= SRAM_AWREADY;
                    LSU_WREADY <= SRAM_WREADY;
                    LSU_BRESP <= SRAM_BRESP;
                    LSU_BVALID <= SRAM_BVALID;
                    LSU_ARREADY <= SRAM_ARREADY;
                    LSU_RDATA <= SRAM_RDATA;
                    LSU_RRESP <= SRAM_RRESP;
                    LSU_RVALID <= SRAM_RVALID;
                end
            endcase
        end
    end
endmodule
