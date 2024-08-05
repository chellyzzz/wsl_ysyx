module ysyx_23060124
(
    input                               clock                        ,
    input                               reset                      ,
    input                               io_interrupt               ,
  //     | AXI4 Master总线 |
    input                               io_master_awready          ,
    output                              io_master_awvalid          ,
    output             [  31:0]         io_master_awaddr           ,
    output             [   3:0]         io_master_awid             ,
    output             [   7:0]         io_master_awlen            ,
    output             [   2:0]         io_master_awsize           ,
    output             [   1:0]         io_master_awburst          ,
    input                               io_master_wready           ,
    output                              io_master_wvalid           ,
    output             [  31:0]         io_master_wdata            ,
    output             [   3:0]         io_master_wstrb            ,
    output                              io_master_wlast            ,
    output                              io_master_bready           ,
    input                               io_master_bvalid           ,
    input              [   1:0]         io_master_bresp            ,
    input              [   3:0]         io_master_bid              ,
    input                               io_master_arready          ,
    output                              io_master_arvalid          ,
    output             [  31:0]         io_master_araddr           ,
    output             [   3:0]         io_master_arid             ,
    output             [   7:0]         io_master_arlen            ,
    output             [   2:0]         io_master_arsize           ,
    output             [   1:0]         io_master_arburst          ,
    output                              io_master_rready           ,
    input                               io_master_rvalid           ,
    input              [   1:0]         io_master_rresp            ,
    input              [  31:0]         io_master_rdata            ,
    input                               io_master_rlast            ,
    input              [   3:0]         io_master_rid              ,
    //    | AXI4 Slave总线 |                   
    output                              io_slave_awready           ,
    input                               io_slave_awvalid           ,
    input              [  31:0]         io_slave_awaddr            ,
    input              [   3:0]         io_slave_awid              ,
    input              [   7:0]         io_slave_awlen             ,
    input              [   2:0]         io_slave_awsize            ,
    input              [   1:0]         io_slave_awburst           ,
    output                              io_slave_wready            ,
    input                               io_slave_wvalid            ,
    input              [  31:0]         io_slave_wdata             ,
    input              [   3:0]         io_slave_wstrb             ,
    input                               io_slave_wlast             ,
    input                               io_slave_bready            ,
    output                              io_slave_bvalid            ,
    output             [   1:0]         io_slave_bresp             ,
    output             [   3:0]         io_slave_bid               ,
    output                              io_slave_arready           ,
    input                               io_slave_arvalid           ,
    input              [  31:0]         io_slave_araddr            ,
    input              [   3:0]         io_slave_arid              ,
    input              [   7:0]         io_slave_arlen             ,
    input              [   2:0]         io_slave_arsize            ,
    input              [   1:0]         io_slave_arburst           ,
    input                               io_slave_rready            ,
    output                              io_slave_rvalid            ,
    output             [   1:0]         io_slave_rresp             ,
    output             [  31:0]         io_slave_rdata             ,
    output                              io_slave_rlast             ,
    output             [   3:0]         io_slave_rid                

);
/*****************para************************/
localparam                              ISA_WIDTH = 32             ;
localparam                              REG_ADDR = 5               ;
localparam                              CSR_ADDR=12                ;

/******************global wires****************/
wire                                    rst_n_sync                 ;

wire                   [ISA_WIDTH-1:0]  imm,ins                    ;
wire                   [REG_ADDR-1:0]   addr_rs1,addr_rs2,addr_rd  ;
wire                   [CSR_ADDR-1:0]   csr_addr                   ;
wire                   [ISA_WIDTH-1:0]  rs1, rs2, rd               ;
//csr wdata rd
wire                   [ISA_WIDTH-1:0]  csr_rd                     ;

wire                   [ISA_WIDTH-1:0]  res                        ;
//mret ecall
wire                   [ISA_WIDTH-1:0]  csr_rs2                    ;
wire                   [ISA_WIDTH-1:0]  mcause, mstatus, mepc, mtvec, mret_a5;

//load store
wire [3-1:0] exu_opt, brch_opt;
wire [3-1:0] load_opt, store_opt;

wire                                    idu_wen, csr_wen, wbu_wen, wbu_csr_wen;
wire                   [ISA_WIDTH-1:0]  pc_next, ifu_pc_next       ;
wire                   [2-1:0]          i_src_sel                  ;
wire                                    brch,jal,jalr              ;// idu -> pcu.
wire                                    if_store,if_load           ;// idu -> exu.
wire                                    ecall,mret                 ;// idu -> pcu.
wire                                    zero                       ;// exu -> pcu.
wire                                    a0_zero                    ;//  if a0 is zero, a0_zero == 1
wire                                    if_unsigned                ;// if_unsigned == 1, unsigned; else signed.
wire                                    pc_update_en               ;
//
wire                                    ifu2idu_valid, idu2ifu_ready;
wire                                    idu2exu_valid, exu2idu_ready;
wire                                    exu2wbu_valid, wbu2exu_ready;



//write address channel  
wire                   [32-1 : 0]       IFU_SRAM_AXI_AWADDR,LSU_SRAM_AXI_AWADDR;
wire                                    IFU_SRAM_AXI_AWVALID, LSU_SRAM_AXI_AWVALID;
wire                                    IFU_SRAM_AXI_AWREADY, LSU_SRAM_AXI_AWREADY;
wire                   [   7:0]         IFU_SRAM_AXI_AWLEN    ,LSU_SRAM_AXI_AWLEN;
wire                   [   2:0]         IFU_SRAM_AXI_AWSIZE   ,LSU_SRAM_AXI_AWSIZE;
wire                   [   1:0]         IFU_SRAM_AXI_AWBURST  ,LSU_SRAM_AXI_AWBURST;
wire                   [   3:0]         IFU_SRAM_AXI_AWID,  LSU_SRAM_AXI_AWID;
//write data channel,
wire                                    IFU_SRAM_AXI_WVALID, LSU_SRAM_AXI_WVALID;
wire                                    IFU_SRAM_AXI_WREADY, LSU_SRAM_AXI_WREADY;
wire                   [32-1 : 0]       IFU_SRAM_AXI_WDATA         ;
wire                   [32-1 : 0]       LSU_SRAM_AXI_WDATA         ;
wire                   [4-1 : 0]        IFU_SRAM_AXI_WSTRB, LSU_SRAM_AXI_WSTRB;
wire                                    IFU_SRAM_AXI_WLAST,LSU_SRAM_AXI_WLAST;
//read data channel
wire                   [32-1 : 0]       IFU_SRAM_AXI_RDATA         ;
wire                   [32-1 : 0]       LSU_SRAM_AXI_RDATA         ;
wire                   [   1:0]         IFU_SRAM_AXI_RRESP, LSU_SRAM_AXI_RRESP;
wire                                    IFU_SRAM_AXI_RVALID, LSU_SRAM_AXI_RVALID;
wire                                    IFU_SRAM_AXI_RREADY, LSU_SRAM_AXI_RREADY;
wire                   [4-1 : 0]        IFU_SRAM_AXI_RID,LSU_SRAM_AXI_RID;
wire                                    IFU_SRAM_AXI_RLAST,LSU_SRAM_AXI_RLAST;
    
//read adress channel
wire                   [32-1 : 0]       IFU_SRAM_AXI_ARADDR, LSU_SRAM_AXI_ARADDR;
wire                                    IFU_SRAM_AXI_ARVALID, LSU_SRAM_AXI_ARVALID;
wire                                    IFU_SRAM_AXI_ARREADY, LSU_SRAM_AXI_ARREADY;
wire                   [4-1 : 0]        IFU_SRAM_AXI_ARID,LSU_SRAM_AXI_ARID;
wire                   [   7:0]         IFU_SRAM_AXI_ARLEN   ,LSU_SRAM_AXI_ARLEN;
wire                   [   2:0]         IFU_SRAM_AXI_ARSIZE  ,LSU_SRAM_AXI_ARSIZE;
wire                   [   1:0]         IFU_SRAM_AXI_ARBURST ,LSU_SRAM_AXI_ARBURST;
//write back channel
wire                   [   1:0]         IFU_SRAM_AXI_BRESP, LSU_SRAM_AXI_BRESP;
wire                                    IFU_SRAM_AXI_BVALID, LSU_SRAM_AXI_BVALID;
wire                                    IFU_SRAM_AXI_BREADY, LSU_SRAM_AXI_BREADY;
wire                   [4-1 : 0]        IFU_SRAM_AXI_BID,LSU_SRAM_AXI_BID;

//write address channel  
wire                   [32-1 : 0]       CLINT_AXI_AWADDR           ;
wire                                    CLINT_AXI_AWVALID          ;
wire                                    CLINT_AXI_AWREADY          ;
wire                   [   7:0]         CLINT_AXI_AWLEN            ;
wire                   [   2:0]         CLINT_AXI_AWSIZE           ;
wire                   [   1:0]         CLINT_AXI_AWBURST          ;
wire                   [   3:0]         CLINT_AXI_AWID             ;
//write data channel,
wire                                    CLINT_AXI_WVALID           ;
wire                                    CLINT_AXI_WREADY           ;
wire                   [32-1 : 0]       CLINT_AXI_WDATA            ;
wire                   [4-1 : 0]        CLINT_AXI_WSTRB            ;
wire                                    CLINT_AXI_WLAST            ;
//read data channel
wire                   [32-1 : 0]       CLINT_AXI_RDATA            ;
wire                   [   1:0]         CLINT_AXI_RRESP            ;
wire                                    CLINT_AXI_RVALID           ;
wire                                    CLINT_AXI_RREADY           ;
wire                   [4-1 : 0]        CLINT_AXI_RID              ;
wire                                    CLINT_AXI_RLAST            ;
    
//read adress channel
wire                   [32-1 : 0]       CLINT_AXI_ARADDR           ;
wire                                    CLINT_AXI_ARVALID          ;
wire                                    CLINT_AXI_ARREADY          ;
wire                   [4-1 : 0]        CLINT_AXI_ARID             ;
wire                   [   7:0]         CLINT_AXI_ARLEN            ;
wire                   [   2:0]         CLINT_AXI_ARSIZE           ;
wire                   [   1:0]         CLINT_AXI_ARBURST          ;
//write back channel
wire                   [   1:0]         CLINT_AXI_BRESP            ;
wire                                    CLINT_AXI_BVALID           ;
wire                                    CLINT_AXI_BREADY           ;
wire                   [4-1 : 0]        CLINT_AXI_BID              ;


/******************combinational logic****************/
// stdrst

ysyx_23060124_stdrst u_stdrst(
    .clock                             (clock                     ),
    .i_rst_n                           (reset                     ),
    .o_rst_n_sync                      (rst_n_sync                ) 
);


ysyx_23060124_RegisterFile regfile1(
    .clock                             (clock                     ),
    .i_ecall                           (ecall                     ),
    .waddr                             (addr_rd                   ),
    .wdata                             (rd                        ),
    .raddr1                            (addr_rs1                  ),
    .raddr2                            (addr_rs2                  ),
    .rdata1                            (rs1                       ),
    .rdata2                            (rs2                       ),
    .o_mret_a5                         (mret_a5                   ),
    .wen                               (wbu_wen                   ),
    .a0_zero                           (a0_zero                   ) 
);

ysyx_23060124_CSR_RegisterFile Csrs(
    .clock                             (clock                     ),
    .rst                               (rst_n_sync                ),
    .csr_wen                           (wbu_csr_wen               ),
    .i_ecall                           (ecall                     ),
    .i_mret                            (mret                      ),
    .i_pc                              (ifu_pc_next               ),
    .csr_addr                          (csr_addr                  ),
    .csr_wdata                         (csr_rd                    ),
    .i_mret_a5                         (mret_a5                   ),
    .o_mcause                          (mcause                    ),
    .o_mstatus                         (mstatus                   ),
    .o_mepc                            (mepc                      ),
    .o_mtvec                           (mtvec                     ),
    .csr_rdata                         (csr_rs2                   ) 
);
ysyx_23060124_IFU ifu1
(
    .i_pc_next                         (pc_next                   ),
    .clock                             (clock                     ),
    .ifu_rst                           (rst_n_sync                ),
    .i_pc_update                       (pc_update_en              ),
    .o_ins                             (ins                       ),
  //ifu -> sram axi
  //write address channel  
    .M_AXI_AWADDR                      (IFU_SRAM_AXI_AWADDR       ),
    .M_AXI_AWVALID                     (IFU_SRAM_AXI_AWVALID      ),
    .M_AXI_AWREADY                     (IFU_SRAM_AXI_AWREADY      ),
    .M_AXI_AWLEN                       (IFU_SRAM_AXI_AWLEN        ),
    .M_AXI_AWSIZE                      (IFU_SRAM_AXI_AWSIZE       ),
    .M_AXI_AWBURST                     (IFU_SRAM_AXI_AWBURST      ),
    .M_AXI_AWID                        (IFU_SRAM_AXI_AWID         ),
  //write data channel
    .M_AXI_WVALID                      (IFU_SRAM_AXI_WVALID       ),
    .M_AXI_WREADY                      (IFU_SRAM_AXI_WREADY       ),
    .M_AXI_WDATA                       (IFU_SRAM_AXI_WDATA        ),
    .M_AXI_WSTRB                       (IFU_SRAM_AXI_WSTRB        ),
    .M_AXI_WLAST                       (IFU_SRAM_AXI_WLAST        ),

  //read data channel
    .M_AXI_RDATA                       (IFU_SRAM_AXI_RDATA        ),
    .M_AXI_RRESP                       (IFU_SRAM_AXI_RRESP        ),
    .M_AXI_RVALID                      (IFU_SRAM_AXI_RVALID       ),
    .M_AXI_RREADY                      (IFU_SRAM_AXI_RREADY       ),
    .M_AXI_RID                         (IFU_SRAM_AXI_RID          ),
    .M_AXI_RLAST                       (IFU_SRAM_AXI_RLAST        ),
  //read adress channel
    .M_AXI_ARADDR                      (IFU_SRAM_AXI_ARADDR       ),
    .M_AXI_ARVALID                     (IFU_SRAM_AXI_ARVALID      ),
    .M_AXI_ARREADY                     (IFU_SRAM_AXI_ARREADY      ),
    .M_AXI_ARID                        (IFU_SRAM_AXI_ARID         ),
    .M_AXI_ARLEN                       (IFU_SRAM_AXI_ARLEN        ),
    .M_AXI_ARSIZE                      (IFU_SRAM_AXI_ARSIZE       ),
    .M_AXI_ARBURST                     (IFU_SRAM_AXI_ARBURST      ),
  //write back channel
    .M_AXI_BRESP                       (IFU_SRAM_AXI_BRESP        ),
    .M_AXI_BVALID                      (IFU_SRAM_AXI_BVALID       ),
    .M_AXI_BREADY                      (IFU_SRAM_AXI_BREADY       ),
    .M_AXI_BID                         (IFU_SRAM_AXI_BID          ),

  //ifu -> idu handshake
    .i_post_ready                      (idu2ifu_ready             ),
    .o_post_valid                      (ifu2idu_valid             ),
    .o_pc_next                         (ifu_pc_next               ) 
);

ysyx_23060124_IDU idu1(
    .clock                             (clock                     ),
    .ins                               (ins                       ),
    .reset                             (reset                     ),
    .i_pre_valid                       (ifu2idu_valid             ),
    .i_post_ready                      (exu2idu_ready             ),
    .o_imm                             (imm                       ),
    .o_rd                              (addr_rd                   ),
    .o_rs1                             (addr_rs1                  ),
    .o_rs2                             (addr_rs2                  ),
    .o_csr_addr                        (csr_addr                  ),
    .o_exu_opt                         (exu_opt                   ),
    .o_load_opt                        (load_opt                  ),
    .o_store_opt                       (store_opt                 ),
    .o_brch_opt                        (brch_opt                  ),
    .o_wen                             (idu_wen                   ),
    .o_csr_wen                         (csr_wen                   ),
    .o_src_sel                         (i_src_sel                 ),
    .o_if_unsigned                     (if_unsigned               ),
    .o_ecall                           (ecall                     ),
    .o_mret                            (mret                      ),
    .o_load                            (if_load                   ),
    .o_store                           (if_store                  ),
    .o_brch                            (brch                      ),
    .o_jal                             (jal                       ),
    .o_jalr                            (jalr                      ),
    .o_pre_ready                       (idu2ifu_ready             ),
    .o_post_valid                      (idu2exu_valid             ) 
);

ysyx_23060124_EXU exu1(
    .clock                             (clock                     ),
    .i_rst_n                           (rst_n_sync                ),
    .csr_src_sel                       (csr_wen                   ),
    .src1                              (rs1                       ),
    .src2                              (rs2                       ),
    .csr_rs2                           (csr_rs2                   ),
    .if_unsigned                       (if_unsigned               ),
    //control signal
    .i_load                            (if_load                   ),
    .i_store                           (if_store                  ),
    .i_brch                            (brch                      ),

    .i_pc                              (ifu_pc_next               ),
    .imm                               (imm                       ),
    .exu_opt                           (exu_opt                   ),
    .load_opt                          (load_opt                  ),
    .store_opt                         (store_opt                 ),
    .brch_opt                          (brch_opt                  ),
    .i_src_sel                         (i_src_sel                 ),
    .o_res                             (res                       ),
    .o_zero                            (zero                      ),
  //lsu -> sram axi
  //write address channel  
    .M_AXI_AWADDR                      (LSU_SRAM_AXI_AWADDR       ),
    .M_AXI_AWVALID                     (LSU_SRAM_AXI_AWVALID      ),
    .M_AXI_AWREADY                     (LSU_SRAM_AXI_AWREADY      ),
    .M_AXI_AWLEN                       (LSU_SRAM_AXI_AWLEN        ),
    .M_AXI_AWSIZE                      (LSU_SRAM_AXI_AWSIZE       ),
    .M_AXI_AWBURST                     (LSU_SRAM_AXI_AWBURST      ),
    .M_AXI_AWID                        (LSU_SRAM_AXI_AWID         ),
  //write data channel
    .M_AXI_WVALID                      (LSU_SRAM_AXI_WVALID       ),
    .M_AXI_WREADY                      (LSU_SRAM_AXI_WREADY       ),
    .M_AXI_WDATA                       (LSU_SRAM_AXI_WDATA        ),
    .M_AXI_WSTRB                       (LSU_SRAM_AXI_WSTRB        ),
    .M_AXI_WLAST                       (LSU_SRAM_AXI_WLAST        ),
  //read data channel
    .M_AXI_RDATA                       (LSU_SRAM_AXI_RDATA        ),
    .M_AXI_RRESP                       (LSU_SRAM_AXI_RRESP        ),
    .M_AXI_RVALID                      (LSU_SRAM_AXI_RVALID       ),
    .M_AXI_RREADY                      (LSU_SRAM_AXI_RREADY       ),
    .M_AXI_RID                         (LSU_SRAM_AXI_RID          ),
    .M_AXI_RLAST                       (LSU_SRAM_AXI_RLAST        ),
  //read adress channel
    .M_AXI_ARADDR                      (LSU_SRAM_AXI_ARADDR       ),
    .M_AXI_ARVALID                     (LSU_SRAM_AXI_ARVALID      ),
    .M_AXI_ARREADY                     (LSU_SRAM_AXI_ARREADY      ),
    .M_AXI_ARID                        (LSU_SRAM_AXI_ARID         ),
    .M_AXI_ARLEN                       (LSU_SRAM_AXI_ARLEN        ),
    .M_AXI_ARSIZE                      (LSU_SRAM_AXI_ARSIZE       ),
    .M_AXI_ARBURST                     (LSU_SRAM_AXI_ARBURST      ),
  //write back channel
    .M_AXI_BRESP                       (LSU_SRAM_AXI_BRESP        ),
    .M_AXI_BVALID                      (LSU_SRAM_AXI_BVALID       ),
    .M_AXI_BREADY                      (LSU_SRAM_AXI_BREADY       ),
    .M_AXI_BID                         (LSU_SRAM_AXI_BID          ),
  //exu -> wbu handshake
    .i_pre_valid                       (idu2exu_valid             ),
    .i_post_ready                      (wbu2exu_ready             ),
    .o_post_valid                      (exu2wbu_valid             ),
    .o_pre_ready                       (exu2idu_ready             ) 
);

ysyx_23060124_WBU wbu1(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .i_pre_valid                       (exu2wbu_valid             ),
    .i_brch                            (brch                      ),
    .i_jal                             (jal                       ),
    .i_wen                             (idu_wen                   ),
    .i_csr_wen                         (csr_wen                   ),
    .i_jalr                            (jalr                      ),
    .i_mret                            (mret                      ),
    .i_ecall                           (ecall                     ),
    .i_mepc                            (mepc                      ),
    .i_mtvec                           (mtvec                     ),
    .i_rs1                             (rs1                       ),
    .i_pc                              (ifu_pc_next               ),
    .i_imm                             (imm                       ),
    .i_res                             (res                       ),
    .o_pc_next                         (pc_next                   ),
    .o_pc_update                       (pc_update_en              ),
    .o_rd_wdata                        (rd                        ),
    .o_csr_rd                          (csr_rd                    ),
    .o_wbu_wen                         (wbu_wen                   ),
    .o_wbu_csr_wen                     (wbu_csr_wen               ),
    .o_pre_ready                       (wbu2exu_ready             ) 
);


ysyx_23060124_Xbar xbar
(
    .clock                             (clock                     ),
    .RESETN                            (rst_n_sync                ),
  // IFU AXI-FULL Interface
    .IFU_AWADDR                        (IFU_SRAM_AXI_AWADDR       ),
    .IFU_AWVALID                       (IFU_SRAM_AXI_AWVALID      ),
    .IFU_AWREADY                       (IFU_SRAM_AXI_AWREADY      ),
    .IFU_AWLEN                         (IFU_SRAM_AXI_AWLEN        ),
    .IFU_AWSIZE                        (IFU_SRAM_AXI_AWSIZE       ),
    .IFU_AWBURST                       (IFU_SRAM_AXI_AWBURST      ),
    .IFU_AWID                          (IFU_SRAM_AXI_AWID         ),
    .IFU_WVALID                        (IFU_SRAM_AXI_WVALID       ),
    .IFU_WREADY                        (IFU_SRAM_AXI_WREADY       ),
    .IFU_WDATA                         (IFU_SRAM_AXI_WDATA        ),
    .IFU_WSTRB                         (IFU_SRAM_AXI_WSTRB        ),
    .IFU_WLAST                         (IFU_SRAM_AXI_WLAST        ),
    .IFU_RDATA                         (IFU_SRAM_AXI_RDATA        ),
    .IFU_RRESP                         (IFU_SRAM_AXI_RRESP        ),
    .IFU_RVALID                        (IFU_SRAM_AXI_RVALID       ),
    .IFU_RREADY                        (IFU_SRAM_AXI_RREADY       ),
    .IFU_RID                           (IFU_SRAM_AXI_RID          ),
    .IFU_RLAST                         (IFU_SRAM_AXI_RLAST        ),
    .IFU_ARADDR                        (IFU_SRAM_AXI_ARADDR       ),
    .IFU_ARVALID                       (IFU_SRAM_AXI_ARVALID      ),
    .IFU_ARREADY                       (IFU_SRAM_AXI_ARREADY      ),
    .IFU_ARID                          (IFU_SRAM_AXI_ARID         ),
    .IFU_ARLEN                         (IFU_SRAM_AXI_ARLEN        ),
    .IFU_ARSIZE                        (IFU_SRAM_AXI_ARSIZE       ),
    .IFU_ARBURST                       (IFU_SRAM_AXI_ARBURST      ),
    .IFU_BRESP                         (IFU_SRAM_AXI_BRESP        ),
    .IFU_BVALID                        (IFU_SRAM_AXI_BVALID       ),
    .IFU_BREADY                        (IFU_SRAM_AXI_BREADY       ),
    .IFU_BID                           (IFU_SRAM_AXI_BID          ),

  // LSU AXI-FULL Interface
    .LSU_AWADDR                        (LSU_SRAM_AXI_AWADDR       ),
    .LSU_AWVALID                       (LSU_SRAM_AXI_AWVALID      ),
    .LSU_AWREADY                       (LSU_SRAM_AXI_AWREADY      ),
    .LSU_AWLEN                         (LSU_SRAM_AXI_AWLEN        ),
    .LSU_AWSIZE                        (LSU_SRAM_AXI_AWSIZE       ),
    .LSU_AWBURST                       (LSU_SRAM_AXI_AWBURST      ),
    .LSU_AWID                          (LSU_SRAM_AXI_AWID         ),
    .LSU_WVALID                        (LSU_SRAM_AXI_WVALID       ),
    .LSU_WREADY                        (LSU_SRAM_AXI_WREADY       ),
    .LSU_WDATA                         (LSU_SRAM_AXI_WDATA        ),
    .LSU_WSTRB                         (LSU_SRAM_AXI_WSTRB        ),
    .LSU_WLAST                         (LSU_SRAM_AXI_WLAST        ),
    .LSU_RDATA                         (LSU_SRAM_AXI_RDATA        ),
    .LSU_RRESP                         (LSU_SRAM_AXI_RRESP        ),
    .LSU_RVALID                        (LSU_SRAM_AXI_RVALID       ),
    .LSU_RREADY                        (LSU_SRAM_AXI_RREADY       ),
    .LSU_RID                           (LSU_SRAM_AXI_RID          ),
    .LSU_RLAST                         (LSU_SRAM_AXI_RLAST        ),
    .LSU_ARADDR                        (LSU_SRAM_AXI_ARADDR       ),
    .LSU_ARVALID                       (LSU_SRAM_AXI_ARVALID      ),
    .LSU_ARREADY                       (LSU_SRAM_AXI_ARREADY      ),
    .LSU_ARID                          (LSU_SRAM_AXI_ARID         ),
    .LSU_ARLEN                         (LSU_SRAM_AXI_ARLEN        ),
    .LSU_ARSIZE                        (LSU_SRAM_AXI_ARSIZE       ),
    .LSU_ARBURST                       (LSU_SRAM_AXI_ARBURST      ),
    .LSU_BRESP                         (LSU_SRAM_AXI_BRESP        ),
    .LSU_BVALID                        (LSU_SRAM_AXI_BVALID       ),
    .LSU_BREADY                        (LSU_SRAM_AXI_BREADY       ),
    .LSU_BID                           (LSU_SRAM_AXI_BID          ),

    .CLINT_AWADDR                      (CLINT_AXI_AWADDR          ),
    .CLINT_AWVALID                     (CLINT_AXI_AWVALID         ),
    .CLINT_AWREADY                     (CLINT_AXI_AWREADY         ),
    .CLINT_AWID                        (CLINT_AXI_AWID            ),
    .CLINT_AWLEN                       (CLINT_AXI_AWLEN           ),
    .CLINT_AWSIZE                      (CLINT_AXI_AWSIZE          ),
    .CLINT_AWBURST                     (CLINT_AXI_AWBURST         ),
    .CLINT_WDATA                       (CLINT_AXI_WDATA           ),
    .CLINT_WSTRB                       (CLINT_AXI_WSTRB           ),
    .CLINT_WVALID                      (CLINT_AXI_WVALID          ),
    .CLINT_WREADY                      (CLINT_AXI_WREADY          ),
    .CLINT_WLAST                       (CLINT_AXI_WLAST           ),
    .CLINT_BRESP                       (CLINT_AXI_BRESP           ),
    .CLINT_BVALID                      (CLINT_AXI_BVALID          ),
    .CLINT_BREADY                      (CLINT_AXI_BREADY          ),
    .CLINT_BID                         (CLINT_AXI_BID             ),
    .CLINT_ARADDR                      (CLINT_AXI_ARADDR          ),
    .CLINT_ARVALID                     (CLINT_AXI_ARVALID         ),
    .CLINT_ARREADY                     (CLINT_AXI_ARREADY         ),
    .CLINT_ARID                        (CLINT_AXI_ARID            ),
    .CLINT_ARLEN                       (CLINT_AXI_ARLEN           ),
    .CLINT_ARSIZE                      (CLINT_AXI_ARSIZE          ),
    .CLINT_ARBURST                     (CLINT_AXI_ARBURST         ),
    .CLINT_RDATA                       (CLINT_AXI_RDATA           ),
    .CLINT_RRESP                       (CLINT_AXI_RRESP           ),
    .CLINT_RVALID                      (CLINT_AXI_RVALID          ),
    .CLINT_RREADY                      (CLINT_AXI_RREADY          ),
    .CLINT_RLAST                       (CLINT_AXI_RLAST           ),
    .CLINT_RID                         (CLINT_AXI_RID             ),

    .SRAM_AWADDR                       (io_master_awaddr          ),
    .SRAM_AWVALID                      (io_master_awvalid         ),
    .SRAM_AWREADY                      (io_master_awready         ),
    .SRAM_AWID                         (io_master_awid            ),
    .SRAM_AWLEN                        (io_master_awlen           ),
    .SRAM_AWSIZE                       (io_master_awsize          ),
    .SRAM_AWBURST                      (io_master_awburst         ),
    .SRAM_WDATA                        (io_master_wdata           ),
    .SRAM_WSTRB                        (io_master_wstrb           ),
    .SRAM_WVALID                       (io_master_wvalid          ),
    .SRAM_WREADY                       (io_master_wready          ),
    .SRAM_WLAST                        (io_master_wlast           ),
    .SRAM_BRESP                        (io_master_bresp           ),
    .SRAM_BVALID                       (io_master_bvalid          ),
    .SRAM_BREADY                       (io_master_bready          ),
    .SRAM_BID                          (io_master_bid             ),
    .SRAM_ARADDR                       (io_master_araddr          ),
    .SRAM_ARVALID                      (io_master_arvalid         ),
    .SRAM_ARREADY                      (io_master_arready         ),
    .SRAM_ARID                         (io_master_arid            ),
    .SRAM_ARLEN                        (io_master_arlen           ),
    .SRAM_ARSIZE                       (io_master_arsize          ),
    .SRAM_ARBURST                      (io_master_arburst         ),
    .SRAM_RDATA                        (io_master_rdata           ),
    .SRAM_RRESP                        (io_master_rresp           ),
    .SRAM_RVALID                       (io_master_rvalid          ),
    .SRAM_RREADY                       (io_master_rready         ),
    .SRAM_RLAST                        (io_master_rlast           ),
    .SRAM_RID                          (io_master_rid             ) 
);


CLINT clint
(
    .clock                             (clock                     ),
    .S_AXI_ARESETN                     (rst_n_sync                ),
    //read data channel
    .S_AXI_RDATA                       (CLINT_AXI_RDATA           ),
    .S_AXI_RRESP                       (CLINT_AXI_RRESP           ),
    .S_AXI_RVALID                      (CLINT_AXI_RVALID          ),
    .S_AXI_RREADY                      (CLINT_AXI_RREADY          ),
    .S_AXI_RLAST                       (CLINT_AXI_RLAST           ),
    .S_AXI_RID                         (CLINT_AXI_RID             ),
    //read adress channel
    .S_AXI_ARADDR                      (CLINT_AXI_ARADDR          ),
    .S_AXI_ARVALID                     (CLINT_AXI_ARVALID         ),
    .S_AXI_ARREADY                     (CLINT_AXI_ARREADY         ),
    .S_AXI_ARID                        (CLINT_AXI_ARID            ),
    .S_AXI_ARLEN                       (CLINT_AXI_ARLEN           ),
    .S_AXI_ARSIZE                      (CLINT_AXI_ARSIZE          ),
    .S_AXI_ARBURST                     (CLINT_AXI_ARBURST         ),
    //write back channel
    .S_AXI_BRESP                       (CLINT_AXI_BRESP           ),
    .S_AXI_BVALID                      (CLINT_AXI_BVALID          ),
    .S_AXI_BREADY                      (CLINT_AXI_BREADY          ),
    .S_AXI_BID                         (CLINT_AXI_BID             ),

    //write address channel  
    .S_AXI_AWADDR                      (CLINT_AXI_AWADDR          ),
    .S_AXI_AWVALID                     (CLINT_AXI_AWVALID         ),
    .S_AXI_AWREADY                     (CLINT_AXI_AWREADY         ),
    .S_AXI_AWID                        (CLINT_AXI_AWID            ),
    .S_AXI_AWLEN                       (CLINT_AXI_AWLEN           ),
    .S_AXI_AWSIZE                      (CLINT_AXI_AWSIZE          ),
    .S_AXI_AWBURST                     (CLINT_AXI_AWBURST         ),

    //write data channel
    .S_AXI_WDATA                       (CLINT_AXI_WDATA           ),
    .S_AXI_WSTRB                       (CLINT_AXI_WSTRB           ),
    .S_AXI_WVALID                      (CLINT_AXI_WVALID          ),
    .S_AXI_WREADY                      (CLINT_AXI_WREADY          ),
    .S_AXI_WLAST                       (CLINT_AXI_WLAST           ) 
);


import "DPI-C" function void load_cnt_dpic   ();
import "DPI-C" function void csr_cnt_dpic    ();
import "DPI-C" function void brch_cnt_dpic   ();
import "DPI-C" function void jal_cnt_dpic    ();
import "DPI-C" function void store_cnt_dpic  ();
import "DPI-C" function void ifu_start  ();
import "DPI-C" function void ifu_end  ();
import "DPI-C" function void load_start  ();
import "DPI-C" function void load_end  ();
import "DPI-C" function void store_start  ();
import "DPI-C" function void store_end  ();

always @(posedge clock) begin
  if(if_load && exu2idu_ready) begin
    load_cnt_dpic();
  end
  if(if_store && exu2idu_ready) begin
    store_cnt_dpic();
  end
  if(brch && exu2idu_ready) begin
    brch_cnt_dpic();
  end
  if((jal || jalr) && exu2idu_ready) begin
    jal_cnt_dpic();
  end
  if(csr_wen && exu2idu_ready) begin
    csr_cnt_dpic();
  end
end

always @(posedge clock) begin
  if(IFU_SRAM_AXI_ARREADY && IFU_SRAM_AXI_ARVALID) begin
    ifu_start();
  end
  else if(IFU_SRAM_AXI_RREADY && IFU_SRAM_AXI_RVALID) begin
    ifu_end();
  end

  if(LSU_SRAM_AXI_ARREADY && LSU_SRAM_AXI_ARVALID) begin
    load_start();
  end
  else if(LSU_SRAM_AXI_RREADY && LSU_SRAM_AXI_RVALID) begin
    load_end();
  end

  if(LSU_SRAM_AXI_AWREADY && LSU_SRAM_AXI_AWVALID) begin
    store_start();
  end
  else if(LSU_SRAM_AXI_BREADY && LSU_SRAM_AXI_BVALID) begin
    store_end();
  end
end

endmodule

