`include "para_defines.v"

module top
(
  input clk,
  input i_rst_n
);

wire rst_n_sync;
//write address channel  
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] SRAM_AXI_AWADDR;
wire  SRAM_AXI_AWVALID;
wire  SRAM_AXI_AWREADY;
//write data channel
wire  SRAM_AXI_WVALID;
wire  SRAM_AXI_WREADY;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] SRAM_AXI_WDATA;
wire [`ysyx_23060124_OPT_WIDTH-1 : 0] SRAM_AXI_WSTRB;
//read data channel
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] SRAM_AXI_RDATA;
wire [1 : 0] SRAM_AXI_RRESP;
wire  SRAM_AXI_RVALID;
wire  SRAM_AXI_RREADY;
//read adress channel
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] SRAM_AXI_ARADDR;
wire  SRAM_AXI_ARVALID;
wire  SRAM_AXI_ARREADY;
//write back channel
wire [1 : 0] SRAM_AXI_BRESP;
wire  SRAM_AXI_BVALID;
wire  SRAM_AXI_BREADY;

//write address channel  
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] UART_AXI_AWADDR;
wire  UART_AXI_AWVALID;
wire  UART_AXI_AWREADY;
//write data channel
wire  UART_AXI_WVALID;
wire  UART_AXI_WREADY;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] UART_AXI_WDATA;
wire [`ysyx_23060124_OPT_WIDTH-1 : 0] UART_AXI_WSTRB;
//read data channel
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] UART_AXI_RDATA;
wire [1 : 0] UART_AXI_RRESP;
wire  UART_AXI_RVALID;
wire  UART_AXI_RREADY;
//read adress channel
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] UART_AXI_ARADDR;
wire  UART_AXI_ARVALID;
wire  UART_AXI_ARREADY;
//write back channel
wire [1 : 0] UART_AXI_BRESP;
wire  UART_AXI_BVALID;
wire  UART_AXI_BREADY;

ysyx_23060124_stdrst u_stdrst(
  .i_clk        (clk        ),
  .i_rst_n      (i_rst_n      ),
  .o_rst_n_sync (rst_n_sync   )
);

ysyx_23060124_CPU CPU
(
    .AXI_ACLK                          (clk                       ),
    .AXI_ARESETN                       (rst_n_sync                ),
    .M_CPU_AXI_AWADDR                  (CPU_AXI_AWADDR            ),
    .M_CPU_AXI_AWVALID                 (CPU_AXI_AWVALID           ),
    .M_CPU_AXI_AWREADY                 (CPU_AXI_AWREADY           ),
    .M_CPU_AXI_WDATA                   (CPU_AXI_WDATA             ),
    .M_CPU_AXI_WSTRB                   (CPU_AXI_WSTRB             ),
    .M_CPU_AXI_WVALID                  (CPU_AXI_WVALID            ),
    .M_CPU_AXI_WREADY                  (CPU_AXI_WREADY            ),
    .M_CPU_AXI_BRESP                   (CPU_AXI_BRESP             ),
    .M_CPU_AXI_BVALID                  (CPU_AXI_BVALID            ),
    .M_CPU_AXI_BREADY                  (CPU_AXI_BREADY            ),
    .M_CPU_AXI_ARADDR                  (CPU_AXI_ARADDR            ),
    .M_CPU_AXI_ARVALID                 (CPU_AXI_ARVALID           ),
    .M_CPU_AXI_ARREADY                 (CPU_AXI_ARREADY           ),
    .M_CPU_AXI_RDATA                   (CPU_AXI_RDATA             ),
    .M_CPU_AXI_RRESP                   (CPU_AXI_RRESP             ),
    .M_CPU_AXI_RVALID                  (CPU_AXI_RVALID            ),
    .M_CPU_AXI_RREADY                  (CPU_AXI_RREADY            ) 
);

//write address channel  
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] CPU_AXI_AWADDR;
wire  CPU_AXI_AWVALID;
wire  CPU_AXI_AWREADY;
//write data channel
wire  CPU_AXI_WVALID;
wire  CPU_AXI_WREADY;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] CPU_AXI_WDATA;
wire [`ysyx_23060124_OPT_WIDTH-1 : 0] CPU_AXI_WSTRB;
//read data channel
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] CPU_AXI_RDATA;
wire [1 : 0] CPU_AXI_RRESP;
wire  CPU_AXI_RVALID;
wire  CPU_AXI_RREADY;
//read adress channel
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] CPU_AXI_ARADDR;
wire  CPU_AXI_ARVALID;
wire  CPU_AXI_ARREADY;
//write back channel
wire [1 : 0] CPU_AXI_BRESP;
wire  CPU_AXI_BVALID;
wire  CPU_AXI_BREADY;

AXI_LITE_XBAR xbar
(
    .AXI_ACLK                          (clk                       ),
    .AXI_ARESETN                       (rst_n_sync                ),
    .M_AXI_AWADDR                      (CPU_AXI_AWADDR            ),
    .M_AXI_AWVALID                     (CPU_AXI_AWVALID           ),
    .M_AXI_AWREADY                     (CPU_AXI_AWREADY           ),
    .M_AXI_WDATA                       (CPU_AXI_WDATA             ),
    .M_AXI_WSTRB                       (CPU_AXI_WSTRB             ),
    .M_AXI_WVALID                      (CPU_AXI_WVALID            ),
    .M_AXI_WREADY                      (CPU_AXI_WREADY            ),
    .M_AXI_BRESP                       (CPU_AXI_BRESP             ),
    .M_AXI_BVALID                      (CPU_AXI_BVALID            ),
    .M_AXI_BREADY                      (CPU_AXI_BREADY            ),
    .M_AXI_ARADDR                      (CPU_AXI_ARADDR            ),
    .M_AXI_ARVALID                     (CPU_AXI_ARVALID           ),
    .M_AXI_ARREADY                     (CPU_AXI_ARREADY           ),
    .M_AXI_RDATA                       (CPU_AXI_RDATA             ),
    .M_AXI_RRESP                       (CPU_AXI_RRESP             ),
    .M_AXI_RVALID                      (CPU_AXI_RVALID            ),
    .M_AXI_RREADY                      (CPU_AXI_RREADY            ),

    .UART_AWADDR                       (UART_AXI_AWADDR           ),
    .UART_AWVALID                      (UART_AXI_AWVALID          ),
    .UART_AWREADY                      (UART_AXI_AWREADY          ),
    .UART_WDATA                        (UART_AXI_WDATA            ),
    .UART_WSTRB                        (UART_AXI_WSTRB            ),
    .UART_WVALID                       (UART_AXI_WVALID           ),
    .UART_WREADY                       (UART_AXI_WREADY           ),
    .UART_BRESP                        (UART_AXI_BRESP            ),
    .UART_BVALID                       (UART_AXI_BVALID           ),
    .UART_BREADY                       (UART_AXI_BREADY           ),
    .UART_ARADDR                       (UART_AXI_ARADDR           ),
    .UART_ARVALID                      (UART_AXI_ARVALID          ),
    .UART_ARREADY                      (UART_AXI_ARREADY          ),
    .UART_RDATA                        (UART_AXI_RDATA            ),
    .UART_RRESP                        (UART_AXI_RRESP            ),
    .UART_RVALID                       (UART_AXI_RVALID           ),
    .UART_RREADY                       (UART_AXI_RREADY           ),

    .CLINT_AWADDR                       (CLINT_AXI_AWADDR           ),
    .CLINT_AWVALID                      (CLINT_AXI_AWVALID          ),
    .CLINT_AWREADY                      (CLINT_AXI_AWREADY          ),
    .CLINT_WDATA                        (CLINT_AXI_WDATA            ),
    .CLINT_WSTRB                        (CLINT_AXI_WSTRB            ),
    .CLINT_WVALID                       (CLINT_AXI_WVALID           ),
    .CLINT_WREADY                       (CLINT_AXI_WREADY           ),
    .CLINT_BRESP                        (CLINT_AXI_BRESP            ),
    .CLINT_BVALID                       (CLINT_AXI_BVALID           ),
    .CLINT_BREADY                       (CLINT_AXI_BREADY           ),
    .CLINT_ARADDR                       (CLINT_AXI_ARADDR           ),
    .CLINT_ARVALID                      (CLINT_AXI_ARVALID          ),
    .CLINT_ARREADY                      (CLINT_AXI_ARREADY          ),
    .CLINT_RDATA                        (CLINT_AXI_RDATA            ),
    .CLINT_RRESP                        (CLINT_AXI_RRESP            ),
    .CLINT_RVALID                       (CLINT_AXI_RVALID           ),
    .CLINT_RREADY                       (CLINT_AXI_RREADY           ),

    .SRAM_AWADDR                       (SRAM_AXI_AWADDR           ),
    .SRAM_AWVALID                      (SRAM_AXI_AWVALID          ),
    .SRAM_AWREADY                      (SRAM_AXI_AWREADY          ),
    .SRAM_WDATA                        (SRAM_AXI_WDATA            ),
    .SRAM_WSTRB                        (SRAM_AXI_WSTRB            ),
    .SRAM_WVALID                       (SRAM_AXI_WVALID           ),
    .SRAM_WREADY                       (SRAM_AXI_WREADY           ),
    .SRAM_BRESP                        (SRAM_AXI_BRESP            ),
    .SRAM_BVALID                       (SRAM_AXI_BVALID           ),
    .SRAM_BREADY                       (SRAM_AXI_BREADY           ),
    .SRAM_ARADDR                       (SRAM_AXI_ARADDR           ),
    .SRAM_ARVALID                      (SRAM_AXI_ARVALID          ),
    .SRAM_ARREADY                      (SRAM_AXI_ARREADY          ),
    .SRAM_RDATA                        (SRAM_AXI_RDATA            ),
    .SRAM_RRESP                        (SRAM_AXI_RRESP            ),
    .SRAM_RVALID                       (SRAM_AXI_RVALID           ),
    .SRAM_RREADY                       (SRAM_AXI_RREADY           ) 
);

UART uart
(
    .S_AXI_ACLK                        (clk                       ),
    .S_AXI_ARESETN                     (rst_n_sync                ),
//read data channel
    .S_AXI_RDATA                       (UART_AXI_RDATA            ),
    .S_AXI_RRESP                       (UART_AXI_RRESP            ),
    .S_AXI_RVALID                      (UART_AXI_RVALID           ),
    .S_AXI_RREADY                      (UART_AXI_RREADY           ),
//read adress channel
    .S_AXI_ARADDR                      (UART_AXI_ARADDR           ),
    .S_AXI_ARVALID                     (UART_AXI_ARVALID          ),
    .S_AXI_ARREADY                     (UART_AXI_ARREADY          ),
//write back channel
    .S_AXI_BRESP                       (UART_AXI_BRESP            ),
    .S_AXI_BVALID                      (UART_AXI_BVALID           ),
    .S_AXI_BREADY                      (UART_AXI_BREADY           ),
//write address channel  
    .S_AXI_AWADDR                      (UART_AXI_AWADDR           ),
    .S_AXI_AWVALID                     (UART_AXI_AWVALID          ),
    .S_AXI_AWREADY                     (UART_AXI_AWREADY          ),
//write data channel
    .S_AXI_WDATA                       (UART_AXI_WDATA            ),
    .S_AXI_WSTRB                       (UART_AXI_WSTRB            ),
    .S_AXI_WVALID                      (UART_AXI_WVALID           ),
    .S_AXI_WREADY                      (UART_AXI_WREADY           ) 
);

SRAM sram(
    .S_AXI_ACLK                        (clk                       ),
    .S_AXI_ARESETN                     (rst_n_sync                ),
    //read data channel
    .S_AXI_RDATA                       (SRAM_AXI_RDATA            ),
    .S_AXI_RRESP                       (SRAM_AXI_RRESP            ),
    .S_AXI_RVALID                      (SRAM_AXI_RVALID           ),
    .S_AXI_RREADY                      (SRAM_AXI_RREADY           ),
    //read adress channel
    .S_AXI_ARADDR                      (SRAM_AXI_ARADDR           ),
    .S_AXI_ARVALID                     (SRAM_AXI_ARVALID          ),
    .S_AXI_ARREADY                     (SRAM_AXI_ARREADY          ),
    //write back channel
    .S_AXI_BRESP                       (SRAM_AXI_BRESP            ),
    .S_AXI_BVALID                      (SRAM_AXI_BVALID           ),
    .S_AXI_BREADY                      (SRAM_AXI_BREADY           ),
    //write address channel  
    .S_AXI_AWADDR                      (SRAM_AXI_AWADDR           ),
    .S_AXI_AWVALID                     (SRAM_AXI_AWVALID          ),
    .S_AXI_AWREADY                     (SRAM_AXI_AWREADY          ),
    //write data channel
    .S_AXI_WDATA                       (SRAM_AXI_WDATA            ),
    .S_AXI_WSTRB                       (SRAM_AXI_WSTRB            ),
    .S_AXI_WVALID                      (SRAM_AXI_WVALID           ),
    .S_AXI_WREADY                      (SRAM_AXI_WREADY           ) 
);

//write address channel  
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] CLINT_AXI_AWADDR;
wire  CLINT_AXI_AWVALID;
wire  CLINT_AXI_AWREADY;
//write data channel
wire  CLINT_AXI_WVALID;
wire  CLINT_AXI_WREADY;
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] CLINT_AXI_WDATA;
wire [`ysyx_23060124_OPT_WIDTH-1 : 0] CLINT_AXI_WSTRB;
//read data channel
wire [`ysyx_23060124_ISA_WIDTH-1 : 0] CLINT_AXI_RDATA;
wire [1 : 0] CLINT_AXI_RRESP;
wire  CLINT_AXI_RVALID;
wire  CLINT_AXI_RREADY;
//read adress channel
wire [`ysyx_23060124_ISA_ADDR_WIDTH-1 : 0] CLINT_AXI_ARADDR;
wire  CLINT_AXI_ARVALID;
wire  CLINT_AXI_ARREADY;
//write back channel
wire [1 : 0] CLINT_AXI_BRESP;
wire  CLINT_AXI_BVALID;
wire  CLINT_AXI_BREADY;
CLINT clint
(
    .S_AXI_ACLK                        (clk                       ),
    .S_AXI_ARESETN                     (rst_n_sync                ),
//read data channel
    .S_AXI_RDATA                       (CLINT_AXI_RDATA            ),
    .S_AXI_RRESP                       (CLINT_AXI_RRESP            ),
    .S_AXI_RVALID                      (CLINT_AXI_RVALID           ),
    .S_AXI_RREADY                      (CLINT_AXI_RREADY           ),
//read adress channel
    .S_AXI_ARADDR                      (CLINT_AXI_ARADDR           ),
    .S_AXI_ARVALID                     (CLINT_AXI_ARVALID          ),
    .S_AXI_ARREADY                     (CLINT_AXI_ARREADY          ),
//write back channel
    .S_AXI_BRESP                       (CLINT_AXI_BRESP            ),
    .S_AXI_BVALID                      (CLINT_AXI_BVALID           ),
    .S_AXI_BREADY                      (CLINT_AXI_BREADY           ),
//write address channel  
    .S_AXI_AWADDR                      (CLINT_AXI_AWADDR           ),
    .S_AXI_AWVALID                     (CLINT_AXI_AWVALID          ),
    .S_AXI_AWREADY                     (CLINT_AXI_AWREADY          ),
//write data channel
    .S_AXI_WDATA                       (CLINT_AXI_WDATA            ),
    .S_AXI_WSTRB                       (CLINT_AXI_WSTRB            ),
    .S_AXI_WVALID                      (CLINT_AXI_WVALID           ),
    .S_AXI_WREADY                      (CLINT_AXI_WREADY           ) 
);


endmodule