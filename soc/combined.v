 

module ysyx_23060124_CSR_RegisterFile (
    input                               clock                      ,
    input                               rst                        ,
    input                               csr_wen                    ,
    input                               i_ecall                    ,
    input                               i_mret                     ,
    input              [32-1:0]         i_pc                       ,
    input              [12-1:0]         csr_addr                   ,
    input              [32-1:0]         csr_wdata                  ,
    input              [32 - 1:0]       i_mret_a5                  ,
    output             [32-1:0]         o_mcause                   ,
    output             [32-1:0]         o_mstatus                  ,
    output             [32-1:0]         o_mepc                     ,
    output             [32-1:0]         o_mtvec                    ,
    output             [32-1:0]         csr_rdata                   
);
// ysyx_23060124
wire [32-1:0] mvendorid , marchid;
assign mvendorid = 32'h79737978;
assign marchid = 32'h23060124;

reg [32-1:0] mcause, mstatus, mepc, mtvec;

always @(posedge  clock) begin
    if (csr_wen)begin 
        case (csr_addr)
            12'h300: mstatus <= csr_wdata;
            12'h341: mepc <= csr_wdata;
            12'h342: mcause <= csr_wdata;
            12'h305: mtvec <= csr_wdata;
            default: begin
                // $display("csr_addr %h not supported", csr_addr);
            end
        endcase
    end
    if(i_ecall)begin
        mepc <= i_pc;
        mcause <= i_mret_a5;
        mstatus <= {mstatus[31:13], 2'b11, mstatus[10:8],mstatus[3],mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[7] <= mstatus[3];
        // mstatus[12:11] <= 2'b11;
        // mstatus[3] <= 1'b0;
    end
    if(i_mret)begin
        mstatus <={mstatus[31:13], 2'b0, mstatus[10:8],1'b1,mstatus[6:4], 1'b0, mstatus[2:0]};
        // mstatus[3] <= mstatus[7];
        // mstatus[7] <= 1'b1;
        // mstatus[12:11] <= 2'b0;
    end
end

assign csr_rdata    = csr_addr == 12'hf11 ? mvendorid :
                      csr_addr == 12'hf12 ? marchid :
                      csr_addr == 12'h300 ? mstatus :
                      csr_addr == 12'h341 ? mepc :
                      csr_addr == 12'h342 ? mcause :
                      csr_addr == 12'h305 ? mtvec : 32'b0;

assign o_mcause     = i_ecall ? mcause              : 32'b0;
assign o_mstatus    = i_ecall || i_mret ? mstatus   : 32'b0;
assign o_mepc       = i_ecall || i_mret ? mepc      : 32'b0;
assign o_mtvec      = i_ecall ? mtvec               : 32'b0;

endmodule
module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               i_ecall                    ,
    input              [32-1:0]         wdata                      ,
    input              [5-1:0]          waddr                      ,
    input              [5-1:0]          raddr1                     ,
    input              [5-1:0]          raddr2                     ,
    output             [32-1:0]         rdata1                     ,
    output             [32-1:0]         rdata2                     ,
    output             [32-1:0]         o_mret_a5                  ,
    input                               wen                        ,
    output                              a0_zero                     
);
  reg [32-1:0] rf [16 - 1:1];
  always @(posedge  clock) begin
    if (wen && waddr != 0) rf[waddr[3:0]] <= wdata;
  end

  assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1[3:0]];
  assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2[3:0]];

  assign a0_zero = ~|rf[10]; 
  assign o_mret_a5 = i_ecall ? rf[15] : 0;

endmodule
module ysyx_23060124_ALU (
    input              [32-1:0]         src1                       ,
    input              [32-1:0]         src2                       ,
    input                               if_unsigned                ,
    input              [3-1:0]          opt                        ,
    output             [32-1:0]         res                        
);
/***************parameter***************/
parameter ADD =  3'b000;
parameter SUB =  3'b000;
parameter SLL =  3'b001;
parameter SLT =  3'b010;
parameter SLTU=  3'b011;
parameter XOR =  3'b100;
parameter SRL =  3'b101;
parameter OR  =  3'b110;
parameter AND =  3'b111;

wire [31:0] add_res;
wire [31:0] and_res;
wire [31:0] or_res;
wire [31:0] xor_res;
wire [31:0] sll_res;
wire [31:0] srl_res;
wire [31:0] slt_res;
wire [31:0] sltu_res;
wire [63:0] temp;

assign temp = {{{32{src1[31]}},src1} >> src2[4:0]};
assign add_res = if_unsigned ? src1 - src2 : src1 + src2;
assign and_res = src1 & src2;
assign or_res  = src1 | src2;
assign xor_res = src1 ^ src2;
assign sll_res = src1 << src2[4:0];
assign srl_res = if_unsigned ? temp[31:0] : src1 >>> src2[4:0];
assign slt_res = (src1[31] != src2[31]) ? (src1[31] ? 32'b1 : 32'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
assign sltu_res = ({1'b0, src1} < {1'b0, src2}) ? 32'b1 : 32'b0;


assign res = (opt == ADD) ? add_res :
             (opt == AND) ? and_res :
             (opt == OR)  ? or_res  :
             (opt == XOR) ? xor_res :
             (opt == SLL) ? sll_res :
             (opt == SRL) ? srl_res :
             (opt == SLT) ? slt_res :
             (opt == SLTU)? sltu_res: 32'b0;

endmodule
module ysyx_23060124_EXU(
    input                               clock                      ,
    input                               i_rst_n                    ,
    input                               csr_src_sel                ,
    input              [32 - 1:0]       src1                       ,
    input              [32 - 1:0]       src2                       ,
    input              [32 - 1:0]       csr_rs2                    ,
    input                               if_unsigned                ,
    //control signal
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,

    input              [32 - 1:0]       i_pc                       ,
    input              [32 - 1:0]       imm                        ,
    input              [3 - 1:0]        exu_opt                    ,
    input              [3 - 1:0]        load_opt                   ,
    input              [3 - 1:0]        store_opt                  ,
    input              [3 - 1:0]        brch_opt                   ,
    input              [2 - 1:0]        i_src_sel                  ,
    output             [32 - 1:0]       o_res                      ,
    output                              o_zero                     ,
  //axi interface
    //write address channel  
    output             [32-1 : 0]       M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [4-1 : 0]        M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [32-1 : 0]       M_AXI_WDATA                ,
    output             [4-1 : 0]        M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [32-1 : 0]       M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [4-1 : 0]        M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [32-1 : 0]       M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [4-1 : 0]        M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [4-1 : 0]        M_AXI_BID                  ,
  //exu -> wbu handshake
    input                               i_post_ready               ,
    input                               i_pre_valid                ,
    output                              o_post_valid               ,
    output reg                          o_pre_ready                 
);


/******************parameter******************/
parameter BEQ   = 3'b000;
parameter BNE   = 3'b001;
parameter BLT   = 3'b100;
parameter BGE   = 3'b101;
parameter BLTU  = 3'b110;
parameter BGEU  = 3'b111;
//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;


wire                   [32-1:0]         sel_src2                   ;
wire                   [32-1:0]         alu_src1,alu_src2          ;
wire                   [32-1:0]         alu_res, lsu_res           ;
wire                                    carry, brch_res            ;
wire                                    lsu_post_valid             ;

reg                    [  31:0]         alu_src1_reg, alu_src2_reg ;

assign sel_src2 = csr_src_sel ? csr_rs2 : src2;
assign o_post_valid = lsu_post_valid;

assign alu_src1 = (i_src_sel == EXU_SEL_REG) ? src1 :
                  (i_src_sel == EXU_SEL_IMM) ? src1 :
                  (i_src_sel == EXU_SEL_PC4) ? i_pc :
                  (i_src_sel == EXU_SEL_PCI) ? i_pc : 32'b0;

assign alu_src2 = (i_src_sel == EXU_SEL_REG) ? sel_src2 :
                  (i_src_sel == EXU_SEL_IMM) ? imm :
                  (i_src_sel == EXU_SEL_PC4) ? 32'h4 :
                  (i_src_sel == EXU_SEL_PCI) ? imm : 32'b0;

always @(posedge  clock or negedge i_rst_n) begin
  if(~i_rst_n) begin
    o_pre_ready <= 1'b0;
  end
  else if(i_pre_valid && ~o_pre_ready) begin
    o_pre_ready <= 1'b1;
  end
  else if(i_pre_valid && o_pre_ready) begin
    o_pre_ready <= 1'b0;
  end
  else o_pre_ready <= o_pre_ready;
end

always @(posedge  clock or negedge i_rst_n) begin
  if(~i_rst_n) begin
    alu_src1_reg <= 32'b0;
    alu_src2_reg <= 32'b0;
  end
  else if(i_pre_valid && o_pre_ready) begin
    alu_src1_reg <= alu_src1;
    alu_src2_reg <= alu_src2;
  end
  else begin
    alu_src1_reg <= alu_src1_reg;
    alu_src2_reg <= alu_src2_reg;
  end
end

ysyx_23060124_ALU exu_alu(
    .src1                              (alu_src1_reg              ),
    .src2                              (alu_src2_reg              ),
    .if_unsigned                       (if_unsigned               ),
    .opt                               (exu_opt                   ),
    .res                               (alu_res                   ) 
);

ysyx_23060124_LSU exu_lsu(
    .clock                             (clock                     ),
    .i_rst_n                           (i_rst_n                   ),
    .lsu_src2                          (src2                      ),
    .alu_res                           (alu_res                   ),
    .load_opt                          (load_opt                  ),
    .store_opt                         (store_opt                 ),
    .lsu_res                           (lsu_res                   ),
    .i_load                            (i_load                    ),
    .i_store                           (i_store                   ),
  //lsu ->exu sram axi
  //write address channel  
    .M_AXI_AWADDR                      (M_AXI_AWADDR              ),
    .M_AXI_AWVALID                     (M_AXI_AWVALID             ),
    .M_AXI_AWREADY                     (M_AXI_AWREADY             ),
    .M_AXI_AWLEN                       (M_AXI_AWLEN               ),
    .M_AXI_AWSIZE                      (M_AXI_AWSIZE              ),
    .M_AXI_AWBURST                     (M_AXI_AWBURST             ),
    .M_AXI_AWID                        (M_AXI_AWID                ),

  //write data channel
    .M_AXI_WVALID                      (M_AXI_WVALID              ),
    .M_AXI_WREADY                      (M_AXI_WREADY              ),
    .M_AXI_WDATA                       (M_AXI_WDATA               ),
    .M_AXI_WSTRB                       (M_AXI_WSTRB               ),
    .M_AXI_WLAST                       (M_AXI_WLAST               ),
  //read data channel
    .M_AXI_RDATA                       (M_AXI_RDATA               ),
    .M_AXI_RRESP                       (M_AXI_RRESP               ),
    .M_AXI_RVALID                      (M_AXI_RVALID              ),
    .M_AXI_RREADY                      (M_AXI_RREADY              ),
    .M_AXI_RID                         (M_AXI_RID                 ),
    .M_AXI_RLAST                       (M_AXI_RLAST               ),
  //read adress channel
    .M_AXI_ARADDR                      (M_AXI_ARADDR              ),
    .M_AXI_ARVALID                     (M_AXI_ARVALID             ),
    .M_AXI_ARREADY                     (M_AXI_ARREADY             ),
    .M_AXI_ARID                        (M_AXI_ARID                ),
    .M_AXI_ARLEN                       (M_AXI_ARLEN               ),
    .M_AXI_ARSIZE                      (M_AXI_ARSIZE              ),
    .M_AXI_ARBURST                     (M_AXI_ARBURST             ),
  //write back channel
    .M_AXI_BRESP                       (M_AXI_BRESP               ),
    .M_AXI_BVALID                      (M_AXI_BVALID              ),
    .M_AXI_BREADY                      (M_AXI_BREADY              ),
    .M_AXI_BID                         (M_AXI_BID                 ),
  //handshake
    .i_pre_valid                       (i_pre_valid               ),
    .o_pre_ready                       (o_pre_ready               ),
    .o_post_valid                      (lsu_post_valid            ) 
);

assign brch_res = (brch_opt == BEQ )   ? (alu_src1_reg == alu_src2_reg)  :
                  (brch_opt == BNE )   ? (alu_src1_reg != alu_src2_reg)  :
                  (brch_opt == BLT )   ? (alu_res == 32'b1) :
                  (brch_opt == BGE )   ? (alu_res == 32'b0) :
                  (brch_opt == BLTU)   ? (alu_res == 32'b1) :
                  (brch_opt == BGEU)   ? (alu_res == 32'b0) :
                  1'b0;

assign o_res = i_load ? lsu_res : (i_brch ? {31'b0, brch_res} : alu_res);
assign o_zero = ~(|o_res);

endmodule
module ysyx_23060124_LSU 
(
    input                               clock                      ,
    input                               i_rst_n                    ,
    input              [32 - 1:0]       lsu_src2                   ,
    input              [32 - 1:0]       alu_res                    ,
    input              [3 - 1:0]        load_opt                   ,
    input              [3 - 1:0]        store_opt                  ,
    output reg         [32 - 1:0]       lsu_res                    ,
    //
    input                               i_load                     ,
    input                               i_store                    ,

    //axi interface
    //write address channel  
    output             [32-1 : 0]       M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [4-1 : 0]        M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [32-1 : 0]       M_AXI_WDATA                ,
    output             [4-1 : 0]        M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [32-1 : 0]       M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [4-1 : 0]        M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [32-1 : 0]       M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [4-1 : 0]        M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [4-1 : 0]        M_AXI_BID                  ,
  //lsu -> wbu handshake
    input                               o_pre_ready                ,
    input                               i_pre_valid                ,
    output reg                          o_post_valid                
);
/************parameter************/
//LSU_OPT
parameter LB  = 3'b000;
parameter LH  = 3'b001;
parameter LW  = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;
 
reg [32 - 1 : 0]  store_addr, store_src2;
reg [3 - 1 : 0]   store_opt_next;


wire                   [   3:0]         wstrb                      ;
// Initiate AXI transactions
wire                                    INIT_AXI_TXN               ;
wire                                    M_AXI_ACLK                 ;
wire                                    M_AXI_ARESETN              ;

// AXI4LITE signals
reg                                     axi_awvalid                ;
reg                                     axi_wvalid                 ;
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                    [32-1:0]         axi_rdata                  ;
reg                                     axi_bready                 ;
reg                    [32-1 : 0]       axi_awaddr                 ;
reg                    [32-1 : 0]       axi_araddr                 ;
reg                                     init_txn_ff                ;
reg                                     init_txn_ff2               ;
reg                                     init_txn_edge              ;
reg                                     o_pre_ready_d1             ;

wire                                    init_txn_pulse             ;
wire                                    is_ls, not_ls              ;
wire                   [   1:0]         shift                      ;
wire                   [32-1:0]         read_res                   ;

assign M_AXI_ARESETN = i_rst_n; 
assign M_AXI_ACLK = clock;
assign M_AXI_AWADDR    = alu_res;
assign M_AXI_WDATA = lsu_src2 << 8*shift;

assign M_AXI_AWVALID	= axi_awvalid;
assign M_AXI_AWLEN = 'b0;
assign M_AXI_AWSIZE =   (store_opt == SW) ? 3'b010 :
                        (store_opt == SH) ? 3'b001 :
                        (store_opt == SB) ? 3'b000 : 3'b010;
assign M_AXI_AWID = 0;
assign M_AXI_AWBURST = 2'b00;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign wstrb =  (store_opt == SB) ? 4'b0001 :
                (store_opt == SH) ? 4'b0011 :
                (store_opt == SW) ? 4'b1111 : 4'b0000;
assign M_AXI_WSTRB = wstrb << shift;
assign M_AXI_WLAST = 1'b1;

//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR	= alu_res;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARLEN = 'b0;
assign M_AXI_ARSIZE =   (load_opt == LW ) ? 3'b010 :
                        (load_opt == LH || load_opt == LHU) ? 3'b001 :
                        (load_opt == LB || load_opt == LBU) ? 3'b000 : 3'b010;

assign M_AXI_ARBURST = 2'b00;
assign M_AXI_ARID = 0;
//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
//Example design I/O
assign init_txn_pulse	= ~i_rst_n ? 1'b1 : (!init_txn_ff2) && init_txn_ff;
assign INIT_AXI_TXN = ~i_rst_n ? 1'b1 : (o_pre_ready_d1 && is_ls ? 1'b1 : 1'b0);
assign is_ls = |i_load  || |i_store;
assign not_ls = ~is_ls;
wire txn_pulse_load;
wire txn_pulse_store;
assign txn_pulse_load = |i_load && init_txn_pulse;
assign txn_pulse_store = |i_store && init_txn_pulse;  

assign shift = alu_res[1:0];

always @(posedge clock)begin
    if(i_rst_n == 1'b0)begin
      o_pre_ready_d1 <= 1'b0; 
    end
    else begin
      o_pre_ready_d1 <= o_pre_ready;
    end
end

always @(posedge clock)begin
    if(i_rst_n == 1'b0)begin
      o_post_valid <= 1'b0; 
    end
    else begin
      if(is_ls && (M_AXI_BREADY || M_AXI_RREADY))begin
        o_post_valid <= 1'b1;
      end
      else if(not_ls && o_pre_ready_d1)begin
        o_post_valid <= 1'b1;
      end
      else begin
        o_post_valid <= 1'b0;
      end
    end
end

//Generate a pulse to initiate AXI transaction.
always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        init_txn_ff <= 1'b0;                                                   
        init_txn_ff2 <= 1'b0;                                                   
        end                                                                               
    else                                                                       
        begin  
        init_txn_ff <= INIT_AXI_TXN;
        init_txn_ff2 <= init_txn_ff;                                                                 
        end                                                                      
    end     
	//--------------------
	//Write Address Channel
	//--------------------
	  always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    //Only VALID signals must be deasserted during reset per AXI spec          
	    //Consider inverting then registering active-low reset for higher fmax     
	    if (M_AXI_ARESETN == 0)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	      //Signal a new address/data command is available by user logic           
	    else                                                                       
	      begin                                                                    
	        if (txn_pulse_store == 1'b1)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;                                               
	          end                                                                  
	     //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end      

	//--------------------
	//Write Data Channel
	//--------------------

	//The write data channel is for transfering the actual data.
	//The data generation is speific to the example design, and 
	//so only the WVALID/WREADY handshake is shown here

	   always @(posedge M_AXI_ACLK)                                        
	   begin                                                                         
	     if (M_AXI_ARESETN == 0)                                                    
	       begin                                                                     
	         axi_wvalid <= 1'b0;                                                     
	       end                                                                       
	     //Signal a new address/data command is available by user logic              
	     else if (txn_pulse_store == 1'b1)                                                
	       begin                                                                     
	         axi_wvalid <= 1'b1;                                                     
	       end                                                                       
	     //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)      
	     else if (M_AXI_WREADY && axi_wvalid)                                        
	       begin                                                                     
	        axi_wvalid <= 1'b0;                                                      
	       end                                                                       
	   end                                                                           

	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	  always @(posedge M_AXI_ACLK)                                    
	  begin                                                                
	    if (M_AXI_ARESETN == 0)                                           
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // accept/acknowledge bresp with axi_bready by the master          
	    // when M_AXI_BVALID is asserted by slave                          
	    else if (M_AXI_BVALID && ~axi_bready)                              
	      begin                                                            
	        axi_bready <= 1'b1;                                            
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // retain the previous value                                       
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                       

//----------------------------
//Read Address Channel
//----------------------------
    // A new axi_arvalid is asserted when there is a valid read address              
    // available by the master. start_single_read triggers a new read                
    // transaction                                                                   
    always @(posedge M_AXI_ACLK)                                                     
    begin                                                                            
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if (txn_pulse_load == 1'b1)                                                    
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
    // if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)    
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
                                
// wire mst_reg_rden;
// assign mst_reg_rden = M_AXI_RVALID && ~axi_rready;

    always @( posedge M_AXI_ACLK )
    begin
        if ( M_AXI_ARESETN == 1'b0 )
        begin
            axi_rdata  <= 0;
        end 
        else
        begin    
            if (M_AXI_RVALID && ~axi_rready)
            begin
                axi_rdata <= M_AXI_RDATA;     // register read data
            end   
        end
    end

assign read_res = axi_rdata >> 8 * shift;

always @(posedge clock) begin
    case(load_opt)
    LB: begin 
      lsu_res <= {{24{read_res[7]}}, read_res[7:0]}; 
    end
    LH: begin 
      lsu_res <= {{16{read_res[15]}}, read_res[15:0]}; 
      end
    LW: begin 
      lsu_res <= read_res[31:0]; 
    end
    LBU: begin 
        lsu_res <= {24'b0, read_res[7:0]};
      end
    LHU: begin 
        lsu_res <= {{16'b0}, read_res[15:0]};
      end
    default: begin lsu_res <= 32'b0; end
    endcase
end

endmodule

module ysyx_23060124_IDU (
    input                               clock                      ,
    input              [32-1:0]         ins                        ,
    input                               reset                      ,
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output             [32-1:0]         o_imm                      ,
    output             [5-1:0]          o_rd                       ,
    output             [5-1:0]          o_rs1                      ,
    output             [5-1:0]          o_rs2                      ,
    output             [12-1:0]         o_csr_addr                 ,
    output             [3-1:0]          o_exu_opt                  ,
    output             [3-1:0]          o_load_opt                 ,
    output             [3-1:0]          o_store_opt                ,
    output             [3-1:0]          o_brch_opt                 ,
    output                              o_wen                      ,
    output                              o_csr_wen                  ,
    output             [2-1:0]          o_src_sel                  ,
    output                              o_if_unsigned              ,
    output                              o_mret                     ,
    output                              o_ecall                    ,
    output                              o_load                     ,
    output                              o_store                    ,
    output                              o_brch                     ,
    output                              o_jal                      ,
    output                              o_jalr                     ,
    output reg                          o_pre_ready                ,
    output reg                          o_post_valid                
);
/************************parameter**********************/
//TYPE_R_FUN3
localparam ADD   =  3'b000;
localparam SUB   =  3'b000;
localparam SLL   =  3'b001;
localparam SLT   =  3'b010;
localparam SLTU  =  3'b011;
localparam XOR   =  3'b100;
localparam SRL_SRA   =  3'b101;
localparam OR    =  3'b110;
localparam AND   =  3'b111;

//EXU_SRC_SEL
localparam EXU_SEL_REG = 2'b00;
localparam EXU_SEL_IMM = 2'b01;
localparam EXU_SEL_PC4 = 2'b10;
localparam EXU_SEL_PCI = 2'b11;

localparam TYPE_I      =  7'b0010011;
localparam TYPE_I_LOAD =  7'b0000011;
localparam TYPE_JALR   =  7'b1100111;
localparam TYPE_EBRK  = 7'b1110011;
localparam TYPE_S     = 7'b0100011;
localparam TYPE_R     = 7'b0110011;
localparam TYPE_AUIPC = 7'b0010111;
localparam TYPE_LUI   = 7'b0110111;
localparam TYPE_JAL   = 7'b1101111;
localparam TYPE_B     = 7'b1100011;

//TYPE_I_FUN3
localparam FUN3_SRL_SRA =  3'b101;
//CSRR
localparam FUN3_CSRRW = 3'b001;
localparam FUN3_CSRRS = 3'b010;
localparam FUN3_EXCPT = 3'b000;
//TYPE_EXCPT_RS2
localparam RS2_ECALL   =  5'b00000;
localparam RS2_MRET    =  5'b00010;

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pre_ready <= 1'b1;
        o_post_valid <= 1'b0;   
    end
    else if(i_pre_valid && o_pre_ready) begin
        o_post_valid <= 1'b1;
    end
    else if(o_post_valid && i_post_ready) begin
        o_post_valid <= 1'b0;
    end
    else begin
        o_post_valid <= o_post_valid;
        o_pre_ready <= o_pre_ready;
    end
end


wire [2:0] func3  = ins[14:12];
wire [6:0] opcode  = ins[6:0];
wire [6:0] func7 = ins[31:25];
wire [5-1:0] rs1 = ins[19:15];
wire [5-1:0] rs2 = ins[24:20];
wire [5-1:0] rd  = ins[11:7];

assign o_imm = (opcode == TYPE_I || opcode == TYPE_I_LOAD) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == TYPE_LUI || opcode == TYPE_AUIPC) ? {{0{ins[31]}}, ins[31:12], 12'b0} :
               (opcode == TYPE_JAL) ? {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0} :
               (opcode == TYPE_JALR) ? {{20{ins[31]}}, ins[31:20]} :
               (opcode == TYPE_B) ? {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0} :
               (opcode == TYPE_S) ? {{20{ins[31]}}, ins[31:25], ins[11:7]} :
               32'b0;

assign o_rd = (opcode == TYPE_I || opcode == TYPE_I_LOAD ||
               opcode == TYPE_R || opcode == TYPE_LUI ||
               opcode == TYPE_AUIPC || opcode == TYPE_JAL ||
               opcode == TYPE_JALR || opcode == TYPE_EBRK) ? rd : 5'b0;

assign o_rs1 = (opcode == TYPE_I || opcode == TYPE_I_LOAD ||
                opcode == TYPE_R || opcode == TYPE_JALR ||
                opcode == TYPE_B || opcode == TYPE_S ||
                opcode == TYPE_EBRK) ? rs1 : 5'b0;

assign o_rs2 = (opcode == TYPE_R || opcode == TYPE_B ||
                opcode == TYPE_S) ? rs2 : 5'b0;

assign o_csr_addr = (opcode == TYPE_EBRK) ? ins[31:20] : 12'b0;

assign o_wen = (opcode == TYPE_I     || opcode == TYPE_I_LOAD ||
                opcode == TYPE_R     || opcode == TYPE_LUI ||
                opcode == TYPE_AUIPC || opcode == TYPE_JAL ||
                opcode == TYPE_JALR  || opcode == TYPE_EBRK) ? 1'b1 : 1'b0;

assign o_csr_wen =  (opcode == TYPE_EBRK ) ? 1'b1 : 1'b0;
                 
assign o_if_unsigned =  (opcode == TYPE_I && func3 == SRL_SRA && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == TYPE_R && func3 == SRL_SRA && func7 == 7'b0100000) ? 1'b1 :
                        (opcode == TYPE_R && func3 == ADD     && func7 == 7'b0100000) ? 1'b1 :
                        1'b0;

assign o_exu_opt =  (opcode == TYPE_I)       ? func3 :
                    (opcode == TYPE_R)       ? func3 :
                    (opcode == TYPE_LUI)     ? 3'b000:
                    (opcode == TYPE_AUIPC)   ? 3'b000:
                    (opcode == TYPE_JAL)     ? 3'b000:
                    (opcode == TYPE_JALR)    ? 3'b000:
                    (opcode == TYPE_I_LOAD)  ? 3'b000:
                    (opcode == TYPE_S)       ? 3'b000:
                    (opcode == TYPE_B && func3[1] == 1'b0)  ? 3'b010:
                    (opcode == TYPE_B && func3[2] == 1'b1)  ? 3'b011:
                    (opcode == TYPE_EBRK && func3 == FUN3_CSRRW)    ? 3'b000:
                    (opcode == TYPE_EBRK && func3 == FUN3_CSRRS)    ? 3'b110:
                    'b0;

assign o_load_opt =   (opcode == TYPE_I_LOAD) ? func3 : 3'b111;

assign o_store_opt =  (opcode == TYPE_S) ? func3 : 3'b111;

assign o_brch_opt =   (opcode == TYPE_B) ? func3 : 3'b010;
                    
assign o_src_sel =    (opcode == TYPE_I)       ? EXU_SEL_IMM:
                      (opcode == TYPE_R)       ? EXU_SEL_REG:
                      (opcode == TYPE_LUI)     ? EXU_SEL_IMM:
                      (opcode == TYPE_AUIPC)   ? EXU_SEL_PCI:
                      (opcode == TYPE_JAL)     ? EXU_SEL_PC4:
                      (opcode == TYPE_JALR)    ? EXU_SEL_PC4:
                      (opcode == TYPE_I_LOAD)  ? EXU_SEL_IMM:
                      (opcode == TYPE_S)       ? EXU_SEL_IMM:
                      (opcode == TYPE_B)       ? EXU_SEL_REG:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRW) ? EXU_SEL_IMM:
                      (opcode == TYPE_EBRK && func3 == FUN3_CSRRS) ? EXU_SEL_REG:
                      'b0;
                    
assign o_ecall = (opcode == TYPE_EBRK)&&(rs2 == RS2_ECALL) &&(func3 == FUN3_EXCPT) ? 'b1: 'b0;
assign o_mret =  (opcode == TYPE_EBRK)&&(rs2 == RS2_MRET ) &&(func3 == FUN3_EXCPT) ? 'b1: 'b0;
assign o_load  = (opcode == TYPE_I_LOAD) ?  'b1: 'b0;
assign o_store = (opcode == TYPE_S)      ?  'b1: 'b0;
assign o_brch  = (opcode == TYPE_B)      ?  'b1: 'b0;
assign o_jal   = (opcode == TYPE_JAL)    ?  'b1: 'b0;
assign o_jalr  = (opcode == TYPE_JALR)   ?  'b1: 'b0;

endmodule
module ysyx_23060124_IFU
(
    input              [32-1:0]         i_pc_next                  ,
    input                               clock                      ,
    input                               ifu_rst                    ,
    input                               i_pc_update                ,
    input                               i_post_ready               ,
    output reg         [32-1:0]         o_ins                      ,
    output reg         [32-1:0]         o_pc_next                  ,

    //write address channel  
    output             [32-1 : 0]       M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [4-1 : 0]        M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [32-1 : 0]       M_AXI_WDATA                ,
    output             [4-1 : 0]        M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [32 - 1 : 0]     M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [4-1 : 0]        M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [32-1 : 0]       M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [4-1 : 0]        M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [4-1 : 0]        M_AXI_BID                  ,

    //ifu_to_idu valid
    output reg                          o_post_valid                
);

localparam RESET_PC = 32'h3000_0000;
/******************************regs*****************************/
    // Initiate AXI transactions
reg                                     INIT_AXI_TXN               ;
    // AXI4LITE signals
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                    [32-1:0]         axi_araddr                 ;
reg                    [32-1:0]         axi_rdata                  ;
reg                    [32-1:0]         pc_next                    ;

    //Flag is asserted when the read index reaches the last read transction number
reg                                     init_txn_ff                ;
reg                                     init_txn_ff2               ;
reg                                     init_txn_edge              ;
wire                                    init_txn_pulse             ;

/******************************nets*****************************/
    // AXI clock signal
wire                                    M_AXI_ACLK                 ;
    // AXI active low reset signal
wire                                    M_AXI_ARESETN              ;
/******************************combinational logic*****************************/
    assign M_AXI_ARESETN = ifu_rst;
    assign M_AXI_ACLK =  clock;
    
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
    assign M_AXI_ARADDR = pc_next;
    assign M_AXI_ARVALID	= axi_arvalid;
    assign M_AXI_ARID = 'b0;
    assign M_AXI_ARLEN = 'b0;
    assign M_AXI_ARSIZE = 3'b010;
    assign M_AXI_ARBURST = 2'b00;
    //Read and Read Response (R)
    assign M_AXI_RREADY	= axi_rready;
    //Example design I/O
    assign init_txn_pulse	= ~ifu_rst ? 1'b1 : (!init_txn_ff2) && init_txn_ff;

/******************************sequential logic*****************************/



always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        INIT_AXI_TXN <= 1'b1;                                            
        end                                                                               
    else                                                                       
        begin  
        if(i_pc_update)begin
            INIT_AXI_TXN <= 1'b1;
        end
        else INIT_AXI_TXN <= 1'b0;                                                          
        end                                                                      
    end     

//Generate a pulse to initiate AXI transaction.
always @(posedge M_AXI_ACLK)										      
    begin                                                                        
    // Initiates AXI transaction delay    
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                    
        init_txn_ff <= 1'b0;                                                   
        init_txn_ff2 <= 1'b0;                                                   
        end                                                                               
    else                                                                       
        begin  
        init_txn_ff <= INIT_AXI_TXN;
        init_txn_ff2 <= init_txn_ff;                                                                 
        end                                                                      
    end     

//----------------------------
//Read Address Channel
//----------------------------       
    // A new axi_arvalid is asserted when there is a valid read address              
    // available by the master. start_single_read triggers a new read                
    // transaction                                                                   
    always @(posedge M_AXI_ACLK)                                                     
    begin                                                                            
    if (M_AXI_ARESETN == 0 )                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if (init_txn_pulse == 1'b1)                                                    
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
    // if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)    
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
                                
// wire mst_reg_rden;
// assign mst_reg_rden = M_AXI_RVALID && ~axi_rready;

    always @( posedge M_AXI_ACLK )
    begin
        if ( M_AXI_ARESETN == 1'b0 )
        begin
            axi_rdata  <= 0;
        end 
        else
        begin    
            if (M_AXI_RVALID && ~axi_rready)
            begin
                axi_rdata <=  M_AXI_RDATA;     // register read data
            end   
        end
    end    

//----------------------------
// only for ifu
//----------------------------

ysyx_23060124_Reg #(.WIDTH(32), .RESET_VAL(RESET_PC)) next_pc_reg(
    .clock                             (clock                     ),
    .rst                               (ifu_rst                   ),
    .din                               (i_pc_next                 ),
    .dout                              (pc_next                   ),
    .wen                               (i_pc_update               ) 
);

always @(posedge  clock or negedge ifu_rst) begin
  if(~ifu_rst) begin
    o_post_valid <= 1'b0;
  end
  else if(M_AXI_RREADY) begin
    o_post_valid <= 1'b1;
  end
  else if(o_post_valid && i_post_ready) begin
    o_post_valid <= 1'b0;
  end
  else o_post_valid <= o_post_valid;
end

always @(posedge  clock or negedge ifu_rst) begin
  if(~ifu_rst) begin
    o_ins <= 32'h0;
    o_pc_next <= RESET_PC;
  end
  else if(i_post_ready && o_post_valid) begin
    o_ins <= axi_rdata[32-1:0];
    o_pc_next <= pc_next;
  end
end

endmodule
module CLINT(
    input                               clock                      ,
    input                               S_AXI_ARESETN              ,
    //read data channel
    output             [32-1 : 0]       S_AXI_RDATA                ,
    output             [   1:0]         S_AXI_RRESP                ,
    output                              S_AXI_RVALID               ,
    input                               S_AXI_RREADY               ,
    output                              S_AXI_RLAST                ,
    output             [4-1 : 0]        S_AXI_RID                  ,

    //read adress channel
    input              [32-1 : 0]       S_AXI_ARADDR               ,
    input                               S_AXI_ARVALID              ,
    output                              S_AXI_ARREADY              ,
    input              [4-1 : 0]        S_AXI_ARID                 ,
    input              [   7:0]         S_AXI_ARLEN                ,
    input              [   2:0]         S_AXI_ARSIZE               ,
    input              [   1:0]         S_AXI_ARBURST              ,

    //write back channel
    output             [   1:0]         S_AXI_BRESP                ,
    output                              S_AXI_BVALID               ,
    input                               S_AXI_BREADY               ,
    output             [4-1 : 0]        S_AXI_BID                  ,

    //write address channel  
    input              [32-1 : 0]       S_AXI_AWADDR               ,
    input                               S_AXI_AWVALID              ,
    output                              S_AXI_AWREADY              ,
    input              [4-1 : 0]        S_AXI_AWID                 ,
    input              [   7:0]         S_AXI_AWLEN                ,
    input              [   2:0]         S_AXI_AWSIZE               ,
    input              [   1:0]         S_AXI_AWBURST              ,

    //write data channel
    input              [32-1 : 0]       S_AXI_WDATA                ,
    input              [4-1 : 0]        S_AXI_WSTRB                ,
    input                               S_AXI_WVALID               ,
    input                               S_AXI_WLAST                ,
    output                              S_AXI_WREADY                
);
/**********************para******************************/
// mtime Register Address
localparam MTIME_REG_ADDR_LOW = 32'h0200_0000;
localparam MTIME_REG_ADDR_HIGH = 32'h0200_0004;

/**********************regs******************************/
reg [32-1 : 0] 	axi_awaddr;
reg  	axi_awready;
reg  	axi_wready;
reg [1 : 0] 	axi_bresp;
reg  	axi_bvalid;
reg [32-1 : 0] 	axi_araddr;
reg  	axi_arready;
reg [32-1 : 0] 	axi_rdata;
reg [1 : 0] 	axi_rresp;
reg  	axi_rvalid;
reg	 aw_en;

// clint 
reg [64-1:0]	reg_mtime;

/**********************wire******************************/
wire	 slv_reg_rden;
wire	 slv_reg_wren;
wire [32-1:0]	 reg_data_out;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;
assign S_AXI_RLAST	= 1'b1;
assign S_AXI_RID    = 4'b0;
assign S_AXI_BID    = 4'b0;

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
        if (slv_reg_wren && S_AXI_AWADDR == MTIME_REG_ADDR_LOW) begin
            reg_mtime[32-1 : 0] <= S_AXI_WDATA;
            // $display("ERROR: Should not reach timer address");
        end
        else if (slv_reg_wren && S_AXI_AWADDR == MTIME_REG_ADDR_HIGH) begin
            reg_mtime[64-1 : 32] <= S_AXI_WDATA;
            // $display("ERROR: Should not reach timer address");
        end
    end 
end  
// Implement axi_awready generation
// axi_awready is asserted for one clock clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_awready <= 1'b0;
        aw_en <= 1'b1;
    end 
    else
    begin    
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
            // slave is ready to accept write address when 
            // there is a valid write address and write data
            // on the write address and data bus. This design 
            // expects no outstanding transactions. 
            axi_awready <= 1'b1;
            aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end
        else           
        begin
            axi_awready <= 1'b0;
        end
    end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 
always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_awaddr <= 0;
    end 
    else
    begin    
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
            // Write Address latching 
            axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end      

// Implement axi_wready generation
// axi_wready is asserted for one clock clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_wready <= 1'b0;
    end 
    else
    begin    
        if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
            // slave is ready to accept write data when 
            // there is a valid write address and write data
            // on the write address and data bus. This design 
            // expects no outstanding transactions. 
            axi_wready <= 1'b1;
        end
        else
        begin
            axi_wready <= 1'b0;
        end
    end 
end       

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_bvalid  <= 0;
        axi_bresp   <= 2'b0;
    end 
    else
    begin    
        if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
            // indicates a valid write response is available
            axi_bvalid <= 1'b1;
            /*********/
            axi_bresp  <= 2'b1; // 'OKAY' response 
            /*********/
        end                   // work error responses in future
        else
        begin
            if (S_AXI_BREADY && axi_bvalid) 
            //check if bready is asserted while bvalid is high) 
            //(there is a possibility that bready is always asserted high)   
            begin
                axi_bvalid <= 1'b0; 
                /*********/
                axi_bresp  <= 2'b0; // 'OKAY' response 
                /*********/
            end  
        end
    end
end   

always @( posedge clock )
begin
    if ( S_AXI_ARESETN == 1'b0 )
    begin
        axi_arready <= 1'b0;
        axi_araddr  <= 32'b0;
    end 
    else
    begin    
        if (~axi_arready && S_AXI_ARVALID)
        begin
            // indicates that the slave has acceped the valid read address
            axi_arready <= 1'b1;
            // Read address latching
            axi_araddr  <= S_AXI_ARADDR;
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
        axi_rresp  <= 0;
    end 
    else
    begin    
        if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
            // Valid read data is available at the read data bus
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b1; // 'OKAY' response
        end   
        else if (axi_rvalid && S_AXI_RREADY)
        begin
            // Read data is accepted by the master
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b0; // 'IDLE' response
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
        if (slv_reg_rden && S_AXI_ARADDR == MTIME_REG_ADDR_LOW)
        begin
            axi_rdata <= reg_mtime[32-1 : 0];     // register read data
        end
        else if (slv_reg_rden && S_AXI_AWADDR == MTIME_REG_ADDR_HIGH)
        begin
            axi_rdata <= reg_mtime[64-1 : 32];     // register read data
        end
    end
end    

endmodule
module ysyx_23060124_Reg #(parameter WIDTH = 1, parameter RESET_VAL = 0) (
    input                               clock                      ,
    input                               rst                        ,
    input                               wen                        ,
    input              [WIDTH-1:0]      din                        ,
    output reg         [WIDTH-1:0]      dout                        
);

  always @(posedge  clock or negedge rst) begin
    if (!rst) dout <= RESET_VAL;
    else if (wen) dout <= din;
  end
  
endmodule

module ysyx_23060124_stdrst(
  input clock,
  input i_rst_n,
  output o_rst_n_sync
);
  reg [10:0] shift_reg;
  always @(posedge clock or posedge i_rst_n) begin
    if (i_rst_n) begin
      shift_reg <= 11'b0;
    end else begin
      shift_reg <= {shift_reg[9:0], 1'b1};
    end
  end

  assign o_rst_n_sync = shift_reg[10];

endmodule

module ysyx_23060124_Xbar(
    input                               clock                      ,
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
    output                              CLINT_WLAST                ,

    input              [   1:0]         CLINT_BRESP                ,
    input                               CLINT_BVALID               ,
    output                              CLINT_BREADY               ,
    input              [4-1 : 0]        CLINT_BID                  ,
    
    output             [32-1:0]         CLINT_ARADDR               ,
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
    output                              SRAM_WLAST                 ,
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
    always @(posedge clock or negedge RESETN) begin
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
    
    always @(posedge clock or negedge RESETN) begin
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
assign CPU_AWREADY = (OUT_STATE == SRAM_ACCESS) ? SRAM_AWREADY : (OUT_STATE == CLINT_ACCESS) ? CLINT_AWREADY : 0;

assign CPU_WDATA   = (IN_STATE == IFU_ACCESS) ? IFU_WDATA   : (IN_STATE == LSU_ACCESS) ? LSU_WDATA   : 0;
assign CPU_WVALID  = (IN_STATE == IFU_ACCESS) ? IFU_WVALID  : (IN_STATE == LSU_ACCESS) ? LSU_WVALID  : 0;
assign CPU_WSTRB   = (IN_STATE == IFU_ACCESS) ? IFU_WSTRB   : (IN_STATE == LSU_ACCESS) ? LSU_WSTRB   : 0;
assign CPU_WLAST   = (IN_STATE == IFU_ACCESS) ? IFU_WLAST   : (IN_STATE == LSU_ACCESS) ? LSU_WLAST   : 0;
assign CPU_WREADY  = (OUT_STATE == SRAM_ACCESS) ? SRAM_WREADY  : (OUT_STATE == CLINT_ACCESS) ? CLINT_WREADY  : 0;

assign CPU_BREADY  = (IN_STATE == IFU_ACCESS) ? IFU_BREADY  : (IN_STATE == LSU_ACCESS) ? LSU_BREADY  : 0;
assign CPU_BVALID  = (OUT_STATE == SRAM_ACCESS) ? SRAM_BVALID  : (OUT_STATE == CLINT_ACCESS) ? CLINT_BVALID  : 0;
assign CPU_BRESP   = (OUT_STATE == SRAM_ACCESS) ? SRAM_BRESP   : (OUT_STATE == CLINT_ACCESS) ? CLINT_BRESP   : 0;
assign CPU_BID     = (OUT_STATE == SRAM_ACCESS) ? SRAM_BID     : (OUT_STATE == CLINT_ACCESS) ? CLINT_BID     : 0;

assign CPU_ARADDR  = (IN_STATE == IFU_ACCESS) ? IFU_ARADDR  : (IN_STATE == LSU_ACCESS) ? LSU_ARADDR  : 0;
assign CPU_ARVALID = (IN_STATE == IFU_ACCESS) ? IFU_ARVALID : (IN_STATE == LSU_ACCESS) ? LSU_ARVALID : 0;
assign CPU_ARLEN   = (IN_STATE == IFU_ACCESS) ? IFU_ARLEN   : (IN_STATE == LSU_ACCESS) ? LSU_ARLEN   : 0;
assign CPU_ARSIZE  = (IN_STATE == IFU_ACCESS) ? IFU_ARSIZE  : (IN_STATE == LSU_ACCESS) ? LSU_ARSIZE  : 0;
assign CPU_ARBURST = (IN_STATE == IFU_ACCESS) ? IFU_ARBURST : (IN_STATE == LSU_ACCESS) ? LSU_ARBURST : 0;
assign CPU_ARID    = (IN_STATE == IFU_ACCESS) ? IFU_ARID    : (IN_STATE == LSU_ACCESS) ? LSU_ARID    : 0;
assign CPU_ARREADY = (OUT_STATE == SRAM_ACCESS) ? SRAM_ARREADY : (OUT_STATE == CLINT_ACCESS) ? CLINT_ARREADY : 0;

// CPU signals
assign CPU_RVALID  = (OUT_STATE == SRAM_ACCESS) ? SRAM_RVALID  : (OUT_STATE == CLINT_ACCESS) ? CLINT_RVALID  : 0;
assign CPU_RDATA   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RDATA   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RDATA   : 0;
assign CPU_RRESP   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RRESP   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RRESP   : 0;
assign CPU_RLAST   = (OUT_STATE == SRAM_ACCESS) ? SRAM_RLAST   : (OUT_STATE == CLINT_ACCESS) ? CLINT_RLAST   : 0;
assign CPU_RID     = (OUT_STATE == SRAM_ACCESS) ? SRAM_RID     : (OUT_STATE == CLINT_ACCESS) ? CLINT_RID     : 0;
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
assign SRAM_WLAST   = (OUT_STATE == SRAM_ACCESS) ? CPU_WLAST   : 0;
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
assign CLINT_WLAST   = (OUT_STATE == CLINT_ACCESS) ? CPU_WLAST   : 0;
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


endmodule

module ysyx_23060124_WBU (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_pre_valid                ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input              [32 - 1:0]       i_pc                       ,
  // ecall and mret
    input              [32 - 1:0]       i_mepc                     ,
    input              [32 - 1:0]       i_mtvec                    ,
  // 
    input              [32 - 1:0]       i_rs1                      ,
    input              [32 - 1:0]       i_imm                      ,
    input              [32 - 1:0]       i_res                      ,
    output             [32 - 1:0]       o_pc_next                  ,
    output             [32 - 1:0]       o_rd_wdata                 ,
    output             [32 - 1:0]       o_csr_rd                   ,
    output reg                          o_pre_ready                ,
    output                              o_wbu_wen                  ,
    output                              o_wbu_csr_wen              ,
    output                              o_pc_update                 
);

wire [32 - 1:0] pc;
wire [32 - 1:0] res;
wire [32 - 1:0] rs1;
wire [32 - 1:0] imm;
wire brch;
wire jal;
wire jalr;
wire mret;
wire ecall;
wire [32 - 1:0] mtvec;
wire [32 - 1:0] mepc;

assign pc            =  i_pre_valid && o_pre_ready ? i_pc        :  'b0;
assign res           =  i_pre_valid && o_pre_ready ? i_res       :  'b0;
assign rs1           =  i_pre_valid && o_pre_ready ? i_rs1       :  'b0;
assign imm           =  i_pre_valid && o_pre_ready ? i_imm       :  'b0;
assign brch          =  i_pre_valid && o_pre_ready ? i_brch      :  'b0;
assign jal           =  i_pre_valid && o_pre_ready ? i_jal       :  'b0;
assign jalr          =  i_pre_valid && o_pre_ready ? i_jalr      :  'b0;
assign mret          =  i_pre_valid && o_pre_ready ? i_mret      :  'b0;
assign ecall         =  i_pre_valid && o_pre_ready ? i_ecall     :  'b0;
assign mtvec         =  i_pre_valid && o_pre_ready ? i_mtvec     :  'b0;
assign mepc          =  i_pre_valid && o_pre_ready ? i_mepc      :  'b0;
assign o_wbu_wen     =  i_pre_valid && o_pre_ready ? i_wen       :  1'b0;
assign o_wbu_csr_wen =  i_pre_valid && o_pre_ready ? i_csr_wen   :  1'b0;

assign o_rd_wdata = jal || jalr ? pc + 4 : res;
assign o_csr_rd  = res;
assign o_pc_next =    jal ? (pc + imm) : 
                      (jalr ? (rs1 + imm) : 
                      (brch && res[0] ? pc + imm : 
                      (ecall ? mtvec :
                      (mret ? mepc : pc + 4))));



always @(posedge clock or posedge reset) begin
  if(reset) begin
    o_pre_ready <= 1'b1;
  end
end
assign o_pc_update = i_pre_valid && o_pre_ready;

endmodule
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


// import "DPI-C" function void load_cnt_dpic   ();
// import "DPI-C" function void csr_cnt_dpic    ();
// import "DPI-C" function void brch_cnt_dpic   ();
// import "DPI-C" function void jal_cnt_dpic    ();
// import "DPI-C" function void store_cnt_dpic  ();
// import "DPI-C" function void ifu_start  ();
// import "DPI-C" function void ifu_end  ();
// import "DPI-C" function void load_start  ();
// import "DPI-C" function void load_end  ();
// import "DPI-C" function void store_start  ();
// import "DPI-C" function void store_end  ();

// always @(posedge clock) begin
//   if(if_load && exu2idu_ready) begin
//     load_cnt_dpic();
//   end
//   if(if_store && exu2idu_ready) begin
//     store_cnt_dpic();
//   end
//   if(brch && exu2idu_ready) begin
//     brch_cnt_dpic();
//   end
//   if((jal || jalr) && exu2idu_ready) begin
//     jal_cnt_dpic();
//   end
//   if(csr_wen && exu2idu_ready) begin
//     csr_cnt_dpic();
//   end
// end

// always @(posedge clock) begin
//   if(IFU_SRAM_AXI_ARREADY && IFU_SRAM_AXI_ARVALID) begin
//     ifu_start();
//   end
//   else if(IFU_SRAM_AXI_RREADY && IFU_SRAM_AXI_RVALID) begin
//     ifu_end();
//   end

//   if(LSU_SRAM_AXI_ARREADY && LSU_SRAM_AXI_ARVALID) begin
//     load_start();
//   end
//   else if(LSU_SRAM_AXI_RREADY && LSU_SRAM_AXI_RVALID) begin
//     load_end();
//   end

//   if(LSU_SRAM_AXI_AWREADY && LSU_SRAM_AXI_AWVALID) begin
//     store_start();
//   end
//   else if(LSU_SRAM_AXI_BREADY && LSU_SRAM_AXI_BVALID) begin
//     store_end();
//   end
// end

endmodule

