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

ysyx_23060124_stdrst u_stdrst(
  .i_clk        (clk        ),
  .i_rst_n      (i_rst_n      ),
  .o_rst_n_sync (rst_n_sync   )
);

ysyx_23060124_CPU CPU
(
    .S_AXI_ACLK                        (clk                       ),
    .S_AXI_ARESETN                     (rst_n_sync                ),
    .M_CPU_AXI_AWADDR                  (SRAM_AXI_AWADDR           ),
    .M_CPU_AXI_AWVALID                 (SRAM_AXI_AWVALID          ),
    .M_CPU_AXI_AWREADY                 (SRAM_AXI_AWREADY          ),
    .M_CPU_AXI_WDATA                   (SRAM_AXI_WDATA            ),
    .M_CPU_AXI_WSTRB                   (SRAM_AXI_WSTRB            ),
    .M_CPU_AXI_WVALID                  (SRAM_AXI_WVALID           ),
    .M_CPU_AXI_WREADY                  (SRAM_AXI_WREADY           ),
    .M_CPU_AXI_BRESP                   (SRAM_AXI_BRESP            ),
    .M_CPU_AXI_BVALID                  (SRAM_AXI_BVALID           ),
    .M_CPU_AXI_BREADY                  (SRAM_AXI_BREADY           ),
    .M_CPU_AXI_ARADDR                  (SRAM_AXI_ARADDR           ),
    .M_CPU_AXI_ARVALID                 (SRAM_AXI_ARVALID          ),
    .M_CPU_AXI_ARREADY                 (SRAM_AXI_ARREADY          ),
    .M_CPU_AXI_RDATA                   (SRAM_AXI_RDATA            ),
    .M_CPU_AXI_RRESP                   (SRAM_AXI_RRESP            ),
    .M_CPU_AXI_RVALID                  (SRAM_AXI_RVALID           ),
    .M_CPU_AXI_RREADY                  (SRAM_AXI_RREADY           ) 
);
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

endmodule