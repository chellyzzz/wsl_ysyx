module ysyx_23060124_Xbar(
    input                               clock                      ,
    input                               RESETN                      ,
    // IFU AXI-FULL Interface
    output             [  31:0]         IFU_RDATA                  ,
    output             [   1:0]         IFU_RRESP                  ,
    output                              IFU_RVALID                 ,
    input                               IFU_RREADY                 ,
    output                              IFU_RLAST                  ,
    output             [   3:0]         IFU_RID                    ,

    input              [  31:0]         IFU_ARADDR                 ,
    input                               IFU_ARVALID                ,
    output                              IFU_ARREADY                ,
    input              [   3:0]         IFU_ARID                   ,
    input              [   7:0]         IFU_ARLEN                  ,
    input              [   2:0]         IFU_ARSIZE                 ,
    input              [   1:0]         IFU_ARBURST                ,

    // LSU AXI-FULL Interface
    output             [  31:0]         LSU_RDATA                  ,
    output             [   1:0]         LSU_RRESP                  ,
    output                              LSU_RVALID                 ,
    input                               LSU_RREADY                 ,
    output                              LSU_RLAST                  ,
    output             [   3:0]         LSU_RID                    ,

    input              [  31:0]         LSU_ARADDR                 ,
    input                               LSU_ARVALID                ,
    output                              LSU_ARREADY                ,
    input              [   3:0]         LSU_ARID                   ,
    input              [   7:0]         LSU_ARLEN                  ,
    input              [   2:0]         LSU_ARSIZE                 ,
    input              [   1:0]         LSU_ARBURST                ,
    
    output             [   1:0]         LSU_BRESP                  ,
    output                              LSU_BVALID                 ,
    input                               LSU_BREADY                 ,
    output             [   3:0]         LSU_BID                    ,

    input              [  31:0]         LSU_AWADDR                 ,
    input                               LSU_AWVALID                ,
    output                              LSU_AWREADY                ,
    input              [   3:0]         LSU_AWID                   ,
    input              [   7:0]         LSU_AWLEN                  ,
    input              [   2:0]         LSU_AWSIZE                 ,
    input              [   1:0]         LSU_AWBURST                ,

    input              [  31:0]         LSU_WDATA                  ,
    input              [   3:0]         LSU_WSTRB                  ,
    input                               LSU_WVALID                 ,
    input                               LSU_WLAST                  ,
    output                              LSU_WREADY                 ,
    
    output                              CLINT_ARADDR               ,
    output             [   3:0]         CLINT_ARID                 ,
    output                              CLINT_ARVALID              ,
    input                               CLINT_ARREADY              ,
    output             [   7:0]         CLINT_ARLEN                ,
    output             [   2:0]         CLINT_ARSIZE               ,
    output             [   1:0]         CLINT_ARBURST              ,

    input              [  31:0]         CLINT_RDATA                ,
    input              [   1:0]         CLINT_RRESP                ,
    input                               CLINT_RVALID               ,
    output                              CLINT_RREADY               ,
    input              [   3:0]         CLINT_RID                  ,
    input                               CLINT_RLAST                ,

    // SRAM AXI-Lite Interface
    output             [  31:0]         SRAM_AWADDR                ,
    output                              SRAM_AWVALID               ,
    input                               SRAM_AWREADY               ,
    output             [   3:0]         SRAM_AWID                  ,
    output             [   7:0]         SRAM_AWLEN                 ,
    output             [   2:0]         SRAM_AWSIZE                ,
    output             [   1:0]         SRAM_AWBURST               ,
    output             [  31:0]         SRAM_WDATA                 ,
    output             [   3:0]         SRAM_WSTRB                 ,
    output                              SRAM_WVALID                ,
    input                               SRAM_WREADY                ,
    output                              SRAM_WLAST                 ,
    input              [   1:0]         SRAM_BRESP                 ,
    input                               SRAM_BVALID                ,
    output                              SRAM_BREADY                ,
    input              [   3:0]         SRAM_BID                   ,
    output             [  31:0]         SRAM_ARADDR                ,
    output             [   3:0]         SRAM_ARID                  ,
    output                              SRAM_ARVALID               ,
    input                               SRAM_ARREADY               ,
    output             [   7:0]         SRAM_ARLEN                 ,
    output             [   2:0]         SRAM_ARSIZE                ,
    output             [   1:0]         SRAM_ARBURST               ,
    input              [  31:0]         SRAM_RDATA                 ,
    input              [   1:0]         SRAM_RRESP                 ,
    input                               SRAM_RVALID                ,
    output                              SRAM_RREADY                ,
    input              [   3:0]         SRAM_RID                   ,
    input                               SRAM_RLAST                  

);

wire ifu_req;
wire lsu_req;
wire ifu_ram_finish;
wire lsu_ram_finish;
assign ifu_req = IFU_ARVALID;
assign lsu_req = LSU_AWVALID || LSU_ARVALID;
assign ifu_ram_finish = (SRAM_RLAST && IFU_RREADY);
assign lsu_ram_finish = SRAM_BREADY || LSU_RREADY;

reg [2:0] state;
localparam IDLE         = 3'b000;
localparam LSU_CLINT    = 3'b001;
localparam IFU_RAM      = 3'b010;
localparam LSU_RAM      = 3'b100;

    always @(posedge clock) begin
        if (RESETN == 1'b0) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (ifu_req) begin
                        state <= IFU_RAM;
                    end 
                    else if(lsu_req) begin
                        state <= LSU_ARADDR[31:31-7] == 8'h02 ? LSU_CLINT : LSU_RAM;
                    end
                    else state <= IDLE;
                end
                LSU_CLINT: begin
                    if(LSU_RREADY)     state <= IDLE;
                end
                IFU_RAM: begin
                    if(ifu_ram_finish) state <= IDLE;
                end
                LSU_RAM: begin
                    if(lsu_ram_finish) state <= IDLE;
                end
            default: state <= IDLE;
            endcase
        end
    end

assign IFU_ARREADY = state[1] ? SRAM_ARREADY : 'b0;
assign IFU_RVALID  = state[1] ? SRAM_RVALID  : 'b0;
assign IFU_RDATA   = state[1] ? SRAM_RDATA   : 'b0;
assign IFU_RRESP   = state[1] ? SRAM_RRESP   : 'b0;
assign IFU_RLAST   = state[1] ? SRAM_RLAST   : 'b0;
assign IFU_RID     = state[1] ? SRAM_RID     : 'b0;

// LSU signals
assign LSU_AWREADY = state[2] ? SRAM_AWREADY : 'b0;
assign LSU_WREADY  = state[2] ? SRAM_WREADY  : 'b0;
assign LSU_BVALID  = state[2] ? SRAM_BVALID  : 'b0;
assign LSU_BRESP   = state[2] ? SRAM_BRESP   : 'b0;
assign LSU_BID     = state[2] ? SRAM_BID     : 'b0;
assign LSU_ARREADY = state[2] ? SRAM_ARREADY : (state[0] ? CLINT_ARREADY: 'b0);
assign LSU_RVALID  = state[2] ? SRAM_RVALID  : (state[0] ? CLINT_RVALID : 'b0);
assign LSU_RDATA   = state[2] ? SRAM_RDATA   : (state[0] ? CLINT_RDATA  : 'b0);
assign LSU_RRESP   = state[2] ? SRAM_RRESP   : (state[0] ? CLINT_RRESP  : 'b0);
assign LSU_RLAST   = state[2] ? SRAM_RLAST   : (state[0] ? CLINT_RLAST  : 'b0);
assign LSU_RID     = state[2] ? SRAM_RID     : (state[0] ? CLINT_RID    : 'b0);

// SRAM signals
// assign SRAM_AWADDR  = state[2] ? LSU_AWADDR  : 'b0;
assign SRAM_AWADDR  = LSU_AWADDR;
assign SRAM_AWVALID = state[2] ? LSU_AWVALID : 'b0;
assign SRAM_AWID    = state[2] ? LSU_AWID    : 'b0;
assign SRAM_WDATA   = state[2] ? LSU_WDATA   : 'b0;
assign SRAM_WVALID  = state[2] ? LSU_WVALID  : 'b0;
assign SRAM_WSTRB   = state[2] ? LSU_WSTRB   : 'b0;
assign SRAM_WLAST   = state[2] ? LSU_WLAST   : 'b0;
assign SRAM_BREADY  = state[2] ? LSU_BREADY  : 'b0;

assign SRAM_ARADDR  = state[2] ? LSU_ARADDR  :  IFU_ARADDR;
assign SRAM_ARID    = state[2] ? LSU_ARID    : (state[1] ? IFU_ARID    : 'b0);
assign SRAM_ARVALID = state[2] ? LSU_ARVALID : (state[1] ? IFU_ARVALID : 'b0);
assign SRAM_RREADY  = state[2] ? LSU_RREADY  : (state[1] ? IFU_RREADY  : 'b0);
assign SRAM_ARLEN   = state[2] ? LSU_ARLEN   : (state[1] ? IFU_ARLEN   : 'b0);
assign SRAM_ARSIZE  = state[2] ? LSU_ARSIZE  : (state[1] ? IFU_ARSIZE  : 'b0);
assign SRAM_ARBURST = state[2] ? LSU_ARBURST : (state[1] ? IFU_ARBURST : 'b0);

assign SRAM_AWLEN   = state[2] ? LSU_AWLEN   : 'b0;
assign SRAM_AWSIZE  = state[2] ? LSU_AWSIZE  : 'b0;
assign SRAM_AWBURST = state[2] ? LSU_AWBURST : 'b0;

// CLINT signals
assign CLINT_ARADDR  = LSU_ARADDR[2];
assign CLINT_ARVALID = (state[0]) ? LSU_ARVALID     : 0;
assign CLINT_ARID    = (state[0]) ? LSU_ARID        : 0;
assign CLINT_RREADY  = (state[0]) ? LSU_RREADY      : 0;
assign CLINT_ARLEN   = (state[0]) ? LSU_ARLEN       : 0;
assign CLINT_ARSIZE  = (state[0]) ? LSU_ARSIZE      : 0;
assign CLINT_ARBURST = (state[0]) ? LSU_ARBURST     : 0;

endmodule

module CLINT(
    input                               clock                      ,
    input                               reset                      ,
    //read data channel
    output             [  31:0]         S_AXI_RDATA                ,
    output             [   1:0]         S_AXI_RRESP                ,
    output                              S_AXI_RVALID               ,
    input                               S_AXI_RREADY               ,
    output                              S_AXI_RLAST                ,
    output             [   3:0]         S_AXI_RID                  ,

    //read adress channel
    input                               S_AXI_ARADDR               ,
    input                               S_AXI_ARVALID              ,
    output                              S_AXI_ARREADY              ,
    input              [   3:0]         S_AXI_ARID                 ,
    input              [   7:0]         S_AXI_ARLEN                ,
    input              [   2:0]         S_AXI_ARSIZE               ,
    input              [   1:0]         S_AXI_ARBURST              
);

/**********************regs******************************/
wire                   [  63:0]         reg_mtime                  ;
reg axi_raddr;

assign S_AXI_ARREADY    = 1'b1;
assign S_AXI_RRESP      = 2'b0;
assign S_AXI_RVALID     = 1'b1;
assign S_AXI_RLAST      = 1'b1;
assign S_AXI_RID        = 4'b0;

always @(posedge clock) begin
    if (reset) begin
        axi_raddr <= 1'b0;
    end
    else begin
        axi_raddr <= S_AXI_ARADDR;
    end
end
Reg  #(.WIDTH(64), .RESET_VAL(64'b0)) mtime_reg
(
    .clk(clock),
    .rst(reset),
    .din(reg_mtime+1),
    .dout(reg_mtime)
);
 
assign S_AXI_RDATA = axi_raddr ? reg_mtime[63 : 32] : reg_mtime[31 : 0];

endmodule

module Reg #( parameter WIDTH = 1, 
              parameter RESET_VAL = 0) 
(
  input clk,
  input rst,
  input [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);
  always @(posedge clk) begin
    if (rst) dout <= RESET_VAL;
    else dout <= din;
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
module ysyx_23060124_idu_exu_regs (
    input              [  31:0]         i_pc                       ,
    input                               clock                      ,
    input                               reset                      ,
    // handshake signals
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output                              o_pre_ready                ,
    output                              o_post_valid               ,

    input              [  31:0]         i_imm                      ,
    input              [  11:0]         i_csr_addr                 ,
    input              [  31:0]         i_src1                     ,
    input              [  31:0]         i_src2                     ,
    input              [   3:0]         i_rd                       ,
    input              [  31:0]         i_csr_rs2                  ,
    input                               i_csr_src_sel              ,
    /***TODO:
    combine wen, csr_wen into one input
    combine csr_addr rd into one input
    ***/
    input              [   2:0]         i_exu_opt                  ,
    input              [   9:0]         i_alu_opt                  ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    input              [   1:0]         i_src_sel1                 ,
    input              [   2:0]         i_src_sel2                 ,
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    input                               i_fence_i                  ,
    input                               i_ebreak                   ,
    
    input              [  31:0]         i_mepc                     ,
    input              [  31:0]         i_mtvec                    ,

    output reg         [  31:0]         o_pc                       ,
    output reg         [  31:0]         o_src1                     ,
    output reg         [  31:0]         o_src2                     ,
    output reg         [  31:0]         o_imm                      ,
    output reg         [   1:0]         o_src_sel1                 ,
    output reg         [   2:0]         o_src_sel2                 ,
    output reg         [   3:0]         o_rd                       ,
    //
    output reg         [  11:0]         o_csr_addr                 ,
    output reg         [   2:0]         o_exu_opt                  ,
    output reg         [   9:0]         o_alu_opt                  ,
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    output reg                          o_mret                     ,
    output reg                          o_ecall                    ,
    
    output reg                          o_load                     ,
    output reg                          o_store                    ,
    output reg                          o_brch                     ,
    output reg                          o_jal                      ,
    output reg                          o_ebreak                   ,
    output reg                          o_fence_i                  ,
    //
    output reg                          o_jalr                      
);

reg                                     post_valid                 ;

assign o_post_valid = post_valid;
assign o_pre_ready  = i_post_ready; 
always @(posedge clock or posedge reset) begin
    if(reset) begin
        post_valid <= 1'b0;   
    end
    else if(i_pre_valid) begin
        post_valid <= 1'b1;
    end
    else if(~i_pre_valid && i_post_ready && o_post_valid)begin
        post_valid <= 1'b0;
    end
end


wire                    [  31:0]         sel_src1                   ;
wire                    [  31:0]         sel_src2                   ;

assign sel_src1 =   ({32{i_ecall}}& i_mtvec )|
                    ({32{i_mret}} & i_mepc  )|
                    i_src1;

assign sel_src2 =   ({32{i_csr_src_sel}} & i_csr_rs2) | i_src2;

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc            <= 32'b0;
        o_src1          <= 32'b0;
        o_src2          <= 32'b0;
        o_imm           <= 32'b0;
        o_src_sel1      <= 2'b0;
        o_src_sel2      <= 3'b0;
        o_rd            <= 4'b0;
        o_exu_opt       <= 3'b0;
        o_alu_opt       <= 10'b0;
        o_wen           <= 1'b0;
        o_csr_wen       <= 1'b0;
        o_mret          <= 1'b0;
        o_ecall         <= 1'b0;
        o_load          <= 1'b0;
        o_store         <= 1'b0;
        o_brch          <= 1'b0;
        o_jal           <= 1'b0;
        o_jalr          <= 1'b0;
        o_ebreak        <= 1'b0;
        o_fence_i       <= 1'b0;
        //
        o_csr_addr      <= 12'b0;

    end
    else if(i_post_ready && o_post_valid) begin
        o_pc            <= i_pc;
        o_src1          <= sel_src1;
        o_src2          <= sel_src2;
        o_imm           <= i_imm;
        o_src_sel1      <= i_src_sel1;
        o_src_sel2      <= i_src_sel2;

        o_rd            <= i_rd;
        o_exu_opt       <= i_exu_opt;
        o_alu_opt       <= i_alu_opt;
        o_wen           <= i_wen;
        o_csr_wen       <= i_csr_wen;
        o_mret          <= i_mret;
        o_ecall         <= i_ecall;
        o_load          <= i_load;
        o_store         <= i_store;
        o_brch          <= i_brch;
        o_jal           <= i_jal;
        o_jalr          <= i_jalr;
        o_ebreak        <= i_ebreak;
        o_fence_i       <= i_fence_i;
        o_csr_addr      <= i_csr_addr;

    end
    else if(i_post_ready && ~o_post_valid) begin
        o_pc            <= 32'b0;
        o_src1          <= 32'b0;
        o_src2          <= 32'b0;
        o_imm           <= 32'b0;
        //TODO:
        o_src_sel1      <= 2'b0;
        o_src_sel2      <= 3'b0;
        o_rd            <= 4'b0;
        o_exu_opt       <= 3'b0;
        o_alu_opt       <= 10'b0;
        o_wen           <= 1'b0;
        o_csr_wen       <= 1'b0;
        o_mret          <= 1'b0;
        o_ecall         <= 1'b0;
        o_load          <= 1'b0;
        o_store         <= 1'b0;
        o_brch          <= 1'b0;
        o_jal           <= 1'b0;
        o_jalr          <= 1'b0;
        o_ebreak        <= 1'b0;
        o_fence_i       <= 1'b0;
        //
        o_csr_addr      <= 12'b0;
    end
end

// import "DPI-C" function void load_cnt_dpic   ();
// import "DPI-C" function void store_cnt_dpic  ();

// always @(posedge clock) begin
//   if(i_post_ready && o_post_valid && i_load) begin
//     load_cnt_dpic();
//   end
//   if(i_post_ready && o_post_valid && i_store) begin
//     store_cnt_dpic();
//   end
// end

endmodule   
module ysyx_23060124_IDU (
    input                               clock                      ,
    input              [  31:0]         ins                        ,
    input                               reset                      ,

    output             [  31:0]         o_imm                      ,
    output             [   3:0]         o_rd                       ,
    output             [   3:0]         o_rs1                      ,
    output             [   3:0]         o_rs2                      ,
    output             [  11:0]         o_csr_addr                 ,
    output             [   2:0]         o_exu_opt                  ,
    output             [   9:0]         o_alu_opt                  ,
    output                              o_wen                      ,
    output                              o_csr_wen                  ,
    output             [   1:0]         o_src_sel1                 ,
    output             [   2:0]         o_src_sel2                 ,

    output                              o_mret                     ,
    output                              o_ecall                    ,
    output                              o_load                     ,
    output                              o_store                    ,
    output                              o_brch                     ,
    output                              o_jal                      ,
    output                              o_jalr                     ,
    output                              o_ebreak                   ,
    output                              o_fence_i                  
);
/************************parameter**********************/
//TYPE_R_FUN3
localparam                              ADD         =  3'b000      ;
localparam                              SUB         =  3'b000      ;
localparam                              SLL         =  3'b001      ;
localparam                              SLT         =  3'b010      ;
localparam                              SLTU        =  3'b011      ;
localparam                              XOR         =  3'b100      ;
localparam                              SRL_SRA     =  3'b101      ;
localparam                              OR          =  3'b110      ;
localparam                              AND         =  3'b111      ;
//
localparam                              ALU_ADD         =  10'd1   ;
localparam                              ALU_SUB         =  10'd2   ;
localparam                              ALU_SLL         =  10'd4   ;
localparam                              ALU_SLT         =  10'd8   ;
localparam                              ALU_SLTU        =  10'd16  ;
localparam                              ALU_XOR         =  10'd32  ;
localparam                              ALU_SRL         =  10'd64  ;
localparam                              ALU_SRA         =  10'd512  ;
localparam                              ALU_OR          =  10'd128 ;
localparam                              ALU_AND         =  10'd256 ;

//EXU_SRC_SEL
localparam                              EXU_SEL_REG = 4'b0001        ;
localparam                              EXU_SEL_IMM = 4'b0010        ;
localparam                              EXU_SEL_PC4 = 4'b0100        ;
localparam                              EXU_SEL_PCI = 4'b1000        ;
//
localparam                              SEL1_REG = 2'b01        ;
localparam                              SEL1_PC  = 2'b10        ;

localparam                              SEL2_REG = 3'b001        ;
localparam                              SEL2_IMM = 3'b010        ;
localparam                              SEL2_4   = 3'b100        ;


localparam                              TYPE_I       =  7'b0010011;
localparam                              TYPE_I_LOAD  =  7'b0000011;
localparam                              TYPE_JALR    =  7'b1100111;
localparam                              TYPE_EBRK    =  7'b1110011;
localparam                              TYPE_S       =  7'b0100011;
localparam                              TYPE_R       =  7'b0110011;
localparam                              TYPE_AUIPC   =  7'b0010111;
localparam                              TYPE_LUI     =  7'b0110111;
localparam                              TYPE_JAL     =  7'b1101111;
localparam                              TYPE_B       =  7'b1100011;
localparam                              TYPE_FENCE   =  7'b0001111;
//TYPE_I_FUN3
localparam                              FUN3_SRL_SRA =  3'b101     ;
//CSRR
localparam                              FUN3_CSRRW = 3'b001        ;
localparam                              FUN3_CSRRS = 3'b010        ;
localparam                              FUN3_EXCPT = 3'b000        ;
//TYPE_EXCPT_RS2
localparam                              RS2_ECALL   =  5'b00000    ;
localparam                              RS2_MRET    =  5'b00010    ;

wire [2:0] func3    = ins[14:12];
wire [6:0] opcode   = ins[6:0];
wire [6:0] func7    = ins[31:25];
wire [3:0] rs1      = ins[18:15];
wire [3:0] rs2      = ins[23:20];
wire [3:0] rd       = ins[10:7];

wire                                    TYPEI       = (opcode == TYPE_I         );
wire                                    TYPEI_LOAD  = (opcode == TYPE_I_LOAD    );
wire                                    TYPER       = (opcode == TYPE_R         );
wire                                    TYPELUI     = (opcode == TYPE_LUI       );
wire                                    TYPEAUIPC   = (opcode == TYPE_AUIPC     );
wire                                    TYPEJAL     = (opcode == TYPE_JAL       );
wire                                    TYPEJALR    = (opcode == TYPE_JALR      );
wire                                    TYPES       = (opcode == TYPE_S         );
wire                                    TYPEB       = (opcode == TYPE_B         );
wire                                    TYPEEBRK    = (opcode == TYPE_EBRK      );
wire                                    TYPEFENCE   = (opcode == TYPE_FENCE     );
wire                                    CSRRS       = (TYPEEBRK && func3 == FUN3_CSRRS      );
wire                                    CSRRW       = (TYPEEBRK && func3 == FUN3_CSRRW      );

assign o_imm = (TYPEI || TYPEI_LOAD) ? {{20{ins[31]}}, ins[31:20]} :
               (TYPELUI || TYPEAUIPC) ? {ins[31:12], 12'b0} :
               (TYPEJAL) ? {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0} :
               (TYPEJALR) ? {{20{ins[31]}}, ins[31:20]} :
               (TYPEB) ? {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0} :
               (TYPES) ? {{20{ins[31]}}, ins[31:25], ins[11:7]} :
               32'b0;

assign o_rd = rd;

assign o_rs1 = (TYPEAUIPC || TYPELUI ||TYPEJAL) ? 4'b0 : rs1;

assign o_rs2 = (TYPER || TYPEB || TYPES) ? rs2 : 4'b0;

//TODO: TYPE_I
assign o_csr_addr = (TYPEEBRK) ? ins[31:20] : 12'b0;

assign o_wen        = (TYPES || TYPEB || TYPEFENCE) ? 1'b0 : 1'b1;

assign o_csr_wen    = (TYPEEBRK && |func3);

wire o_if_unsigned;
assign o_if_unsigned =  (TYPEI && func3 == SRL_SRA && func7[5]) ? 1'b1 :
                        (TYPER && func3 == SRL_SRA && func7[5]) ? 1'b1 :
                        (TYPER && func3 == ADD     && func7[5]) ? 1'b1 :
                        1'b0;

assign o_exu_opt =  func3;
wire [2:0] exu_opt;
assign exu_opt =  (TYPEB)       ? {1'b0,func3[2:1]}:
                  func3;

assign o_alu_opt =  (TYPES | TYPEI_LOAD | TYPELUI | TYPEAUIPC | TYPEJAL) ? ALU_ADD:
                    (CSRRS) ? ALU_OR: 
                    (CSRRW) ? ALU_ADD:
                    (exu_opt ==  ADD && ~o_if_unsigned           )  ? ALU_ADD  :
                    (exu_opt ==  SUB &&  o_if_unsigned           )  ? ALU_SUB  :
                    (exu_opt ==  SLL           )  ? ALU_SLL  :
                    (exu_opt ==  SLT           )  ? ALU_SLT  :
                    (exu_opt ==  SLTU          )  ? ALU_SLTU :
                    (exu_opt ==  XOR           )  ? ALU_XOR  :
                    (exu_opt ==  SRL_SRA &&  o_if_unsigned      )  ? ALU_SRL  :
                    (exu_opt ==  SRL_SRA && ~o_if_unsigned      )  ? ALU_SRA  :
                    (exu_opt ==  OR            )  ? ALU_OR   :
                    (exu_opt ==  AND           )  ? ALU_AND  :
                    ALU_ADD;

// assign o_alu_opt[0] = TYPES | TYPEI_LOAD | TYPELUI | TYPEAUIPC | TYPEJAL | CSRRW | (exu_opt ==  ADD && ~o_if_unsigned           );
// assign o_alu_opt[1] = (exu_opt ==  SUB &&  o_if_unsigned           );
// assign o_alu_opt[2] = (exu_opt ==  SLL           );
// assign o_alu_opt[3] = (exu_opt ==  SLT           );
// assign o_alu_opt[4] = (exu_opt ==  SLTU          );
// assign o_alu_opt[5] = (exu_opt ==  XOR           );
// assign o_alu_opt[6] = (exu_opt ==  SRL_SRA &&  o_if_unsigned      );
// assign o_alu_opt[7] = (exu_opt ==  SRL_SRA && ~o_if_unsigned      );
// assign o_alu_opt[8] = CSRRS |(exu_opt ==  OR            );
// assign o_alu_opt[9] = (exu_opt ==  AND           );

assign o_src_sel1 =   (TYPEI)       ? SEL1_REG:
                      (TYPER)       ? SEL1_REG:
                      (TYPELUI)     ? SEL1_REG:
                      (TYPEAUIPC)   ? SEL1_PC:
                      (TYPEJAL)     ? SEL1_PC:
                      (TYPEJALR)    ? SEL1_PC:
                      (TYPEI_LOAD)  ? SEL1_REG:
                      (TYPES)       ? SEL1_REG:
                      (TYPEB)       ? SEL1_REG:
                      (CSRRW) ? SEL1_REG:
                      (CSRRS) ? SEL1_REG:
                      'b0;

assign o_src_sel2 =   (TYPEI)       ? SEL2_IMM:
                      (TYPER)       ? SEL2_REG:
                      (TYPELUI)     ? SEL2_IMM:
                      (TYPEAUIPC)   ? SEL2_IMM:
                      (TYPEJAL)     ? SEL2_4:
                      (TYPEJALR)    ? SEL2_4:
                      (TYPEI_LOAD)  ? SEL2_IMM:
                      (TYPES)       ? SEL2_IMM:
                      (TYPEB)       ? SEL2_REG:
                      (CSRRW) ? SEL2_IMM:
                      (CSRRS) ? SEL2_REG:
                      'b0;
                                        
assign o_ecall      = (TYPEEBRK && func3 == 3'b0 && rs2[1:0] == 2'b00);
assign o_mret       = (TYPEEBRK && func3 == 3'b0 && rs2[1:0] == 2'b10);

assign o_load       = (TYPEI_LOAD);
assign o_store      = (TYPES)     ;
assign o_brch       = (TYPEB)     ;
assign o_jal        = (TYPEJAL)   ;
assign o_jalr       = (TYPEJALR)  ;
assign o_fence_i    = (TYPEFENCE)&&(func3 == 3'b001);
assign o_ebreak     = (TYPEEBRK && func3 == 3'b0 && rs2[1:0] == 2'b01);

endmodule
module ysyx_23060124_exu_wbu_regs (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_wen                      ,
    input                               i_csr_wen                  ,
    //TODO: combine addr_rd and csr_addr into one input
    //TODO: i_csr_wen adn i_wen into one input
    input                               i_jalr                     ,
    input                               i_ebreak                   ,
    input                               i_mret                     ,
    input                               i_ecall                    ,

    input              [  31:0]         i_res                      ,
    input              [  31:0]         i_pc_next                  ,
    input              [  11:0]         i_csr_addr                 ,
    input              [   3:0]         i_rd_addr                  ,

    output reg         [  31:0]         o_pc_next                  ,
    output reg         [  11:0]         o_csr_addr                 ,
    output reg         [   3:0]         o_rd_addr                  , 
    //
    output reg                          o_wen                      ,
    output reg                          o_csr_wen                  ,
    //
    output reg                          o_brch                     ,
    output reg                          o_jal                      ,
    output reg                          o_jalr                     ,
    output reg                          o_mret                     ,
    output reg                          o_ecall                    ,
    output reg                          o_ebreak                   ,
    //
    output reg         [  31:0]         o_res                      ,
    // output reg                          o_next                     ,
    input                               i_post_ready               ,
    input                               o_post_valid                
);

always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc_next   <= 'b0; 
        o_csr_addr  <= 'b0; 
        o_rd_addr   <= 'b0; 
        o_wen       <= 'b0; 
        o_csr_wen   <= 'b0; 
        o_brch      <= 'b0; 
        o_jal       <= 'b0; 
        o_jalr      <= 'b0; 
        o_mret      <= 'b0; 
        o_ecall     <= 'b0;  
        o_res       <= 'b0; 
        o_ebreak    <= 'b0;
        // o_next      <= 'b0;
    end
    else if(i_post_ready && o_post_valid) begin
        o_pc_next   <= i_pc_next;
        o_csr_addr  <= i_csr_addr;
        o_rd_addr   <= i_rd_addr;
        o_wen       <= i_wen;
        o_csr_wen   <= i_csr_wen;
        o_brch      <= i_brch;
        o_jal       <= i_jal;
        o_jalr      <= i_jalr;
        o_mret      <= i_mret;
        o_ecall     <= i_ecall;
        o_res       <= i_res;
        o_ebreak    <= i_ebreak;
        // o_next      <= 1'b1;
    end
    else if(i_post_ready && ~o_post_valid) begin
        o_pc_next   <= 'b0; 
        o_csr_addr  <= 'b0; 
        o_rd_addr   <= 'b0; 
        o_wen       <= 'b0; 
        o_csr_wen   <= 'b0; 
        o_brch      <= 'b0; 
        o_jal       <= 'b0; 
        o_jalr      <= 'b0; 
        o_mret      <= 'b0; 
        o_ecall     <= 'b0; 
        o_res       <= 'b0; 
        o_ebreak    <= 'b0;
        // o_next      <= 'b0;
    end
end
endmodule   module ysyx_23060124_EXU(
    input                               clock                      ,
    input                               reset                      ,
    input              [  31:0]         i_src1                     ,
    input              [  31:0]         i_src2                     ,
    input              [  31:0]         i_pc                       ,
    input              [  31:0]         i_imm                      ,
    input              [   1:0]         i_src_sel1                 ,
    input              [   2:0]         i_src_sel2                 ,

    //control signal
    input                               i_load                     ,
    input                               i_store                    ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    //ecall and mret
    input                               i_ecall                    ,
    input                               i_mret                     ,
    input              [   9:0]         i_alu_opt                  ,
    input              [   2:0]         exu_opt                    ,

    output             [  31:0]         o_res                      ,
    output                              o_brch                     ,
    output             [  31:0]         o_pc_next                  ,

    //write address channel  
    output             [  31:0]         M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [   3:0]         M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [  31:0]         M_AXI_WDATA                ,
    output             [   3:0]         M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [  31:0]         M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [   3:0]         M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [  31:0]         M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [   3:0]         M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [   3:0]         M_AXI_BID                  ,
  //exu -> wbu handshake
    input                               i_post_ready               ,
    input                               i_pre_valid                ,
    output                              o_post_valid               ,
    output                              o_pre_ready                 
);

/******************parameter******************/
parameter BEQ   = 3'b000;
parameter BNE   = 3'b001;
parameter BLT   = 3'b100;
parameter BGE   = 3'b101;
parameter BLTU  = 3'b110;
parameter BGEU  = 3'b111;

wire                   [  31:0]         alu_res, load_res          ;
wire                                    if_lsu                     ;

reg post_valid;

assign if_lsu = i_load || i_store;
assign o_post_valid =  if_lsu  ?  (M_AXI_RLAST && M_AXI_RREADY)||(M_AXI_BREADY) : 
                       post_valid;

assign o_pre_ready  =  if_lsu  ?  (M_AXI_RLAST && M_AXI_RREADY)||(M_AXI_BREADY) : 
                       1'b1;

always @(posedge clock) begin
    if(reset) begin
        post_valid <= 1'b0;   
    end
    post_valid <= i_pre_valid;
end

reg                  [  31:0]         alu_src1                   ;
reg                  [  31:0]         alu_src2                   ;

always_comb begin
    unique case(1'b1)
        i_src_sel1[0]:  alu_src1 = i_src1;
        default: alu_src1 = i_pc;
    endcase
end

always_comb begin
    unique case(1'b1)
        i_src_sel2[0]:  alu_src2 = i_src2;
        i_src_sel2[1]:  alu_src2 = i_imm;
        i_src_sel2[2]:  alu_src2 = 32'h4;
        default: alu_src2 = 32'h0;
    endcase
end

assign o_pc_next =    i_jal             ? i_pc    + i_imm : 
                      i_jalr            ? i_src1  + i_imm : 
                      i_brch            ? i_pc    + i_imm :
                      i_ecall           ? i_src1          :
                      i_mret            ? i_src1          : 
                      i_pc + 4;

ysyx_23060124_ALU exu_alu(
    .src1                              (alu_src1                  ),
    .src2                              (alu_src2                  ),
    .opt                               (i_alu_opt                 ),
    .res                               (alu_res                   ) 
);

ysyx_23060124_LSU exu_lsu(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .store_src                         (i_src2                    ),
    .alu_res                           (alu_res                   ),
    .exu_opt                           (exu_opt                   ),
    .load_res                          (load_res                  ),
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
    .o_pre_ready                       (o_pre_ready               )
);

wire beq, bne;
assign beq = (alu_src1 == alu_src2);
assign bne = ~beq;
reg                                     brch_res                   ;
wire [2:0] brch_opt;
assign brch_opt = exu_opt;
always @(*) begin
  case(brch_opt)
    BEQ:  brch_res = beq;
    BNE:  brch_res = bne;
    BLT:  brch_res = alu_res[0] ;
    BGE:  brch_res = ~alu_res[0] ;
    BLTU: brch_res = alu_res[0];
    BGEU: brch_res = ~alu_res[0];
    default: brch_res = 1'b0;
  endcase
end
assign o_res  = i_load ? load_res : alu_res;
assign o_brch = i_brch && brch_res;

endmodule
module ysyx_23060124_LSU
(
    input                               clock                      ,
    input                               reset                     ,
    input              [  31:0]         store_src                  ,
    input              [  31:0]         alu_res                    ,
    input              [   2:0]         exu_opt                    ,
    output reg         [  31:0]         load_res                   ,
    //
    input                               i_load                     ,
    input                               i_store                    ,
    //axi interface
    //write address channel  
    output             [  31:0]         M_AXI_AWADDR               ,
    output                              M_AXI_AWVALID              ,
    input                               M_AXI_AWREADY              ,
    output             [   7:0]         M_AXI_AWLEN                ,
    output             [   2:0]         M_AXI_AWSIZE               ,
    output             [   1:0]         M_AXI_AWBURST              ,
    output             [   3:0]         M_AXI_AWID                 ,

    //write data channel
    output                              M_AXI_WVALID               ,
    input                               M_AXI_WREADY               ,
    output             [  31:0]         M_AXI_WDATA                ,
    output             [   3:0]         M_AXI_WSTRB                ,
    output                              M_AXI_WLAST                ,

    //read data channel
    input              [  31:0]         M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [   3:0]         M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [  31:0]         M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [   3:0]         M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    //write back channel
    input              [   1:0]         M_AXI_BRESP                ,
    input                               M_AXI_BVALID               ,
    output                              M_AXI_BREADY               ,
    input              [   3:0]         M_AXI_BID                  ,
  //lsu -> wbu handshake
    input                               o_pre_ready                ,
    input                               i_pre_valid                
);
/************parameter************/
//exu_opt
parameter LB  = 3'b000;
parameter LH  = 3'b001;
parameter LW  = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;
 
wire                   [   3:0]         wstrb                      ;
// Initiate AXI transactions
wire                                    INIT_AXI_TXN               ;
// AXI4LITE signals
reg                                     axi_awvalid                ;
reg                                     axi_wvalid                 ;
reg                                     axi_arvalid                ;
reg                                     axi_rready                 ;
reg                                     axi_bready                 ;
//combine awaddr araddr to 1
reg                    [  31:0]         axi_axaddr                 ;

reg                                     init_txn_ff                ;
reg                                     init_txn_ff2               ;
reg                                     init_txn_edge              ;
reg                                     o_pre_ready_d1             ;

wire                                    init_txn_pulse             ;
wire                                    is_ls                      ;
wire                   [   4:0]         shift8                     ;
reg                    [   1:0]         shift                      ;

wire txn_pulse_load;
wire txn_pulse_store;

assign shift8 = {shift, 3'b0};
assign M_AXI_AWADDR = axi_axaddr;
assign M_AXI_WDATA  = store_src << shift8;

assign M_AXI_AWVALID	= axi_awvalid;
assign M_AXI_AWLEN = 'b0;
assign M_AXI_AWSIZE =   (exu_opt == SW) ? 3'b010 :
                        (exu_opt == SH) ? 3'b001 :
                        (exu_opt == SB) ? 3'b000 : 3'b010;
assign M_AXI_AWID    = 0;
assign M_AXI_AWBURST = 2'b00;
//Write Data(W)
assign M_AXI_WVALID	= axi_wvalid;
//Set all byte strobes in this example
assign wstrb =  (exu_opt == SB) ? 4'b0001 :
                (exu_opt == SH) ? 4'b0011 :
                (exu_opt == SW) ? 4'b1111 : 4'b0000;

assign M_AXI_WSTRB = wstrb << shift;
assign M_AXI_WLAST = 1'b1;

//Write Response (B)
assign M_AXI_BREADY	= axi_bready;
//Read Address (AR)
assign M_AXI_ARADDR = axi_axaddr;
assign M_AXI_ARVALID	= axi_arvalid;
assign M_AXI_ARLEN = 'b0;
assign M_AXI_ARSIZE =   (exu_opt[1:0] == 2'b10) ? 3'b010 :
                        (exu_opt[1:0] == 2'b01) ? 3'b001 :
                        (exu_opt[1:0] == 2'b00) ? 3'b000 : 3'b010;
                        
assign M_AXI_ARBURST = 2'b00;
assign M_AXI_ARID = 0;

//Read and Read Response (R)
assign M_AXI_RREADY	= axi_rready;
//Example design I/O
assign init_txn_pulse	= reset ? 1'b0 : (!init_txn_ff2) && init_txn_ff;
assign INIT_AXI_TXN   = reset ? 1'b0 : (o_pre_ready_d1 && is_ls ? 1'b1 : 1'b0);
assign is_ls = i_load  || i_store;
assign txn_pulse_load   = i_load  && init_txn_pulse;
assign txn_pulse_store  = i_store && init_txn_pulse;  

reg idle;

always @(posedge clock)begin
    if(reset)begin
      o_pre_ready_d1 <= 1'b0; 
    end
    else begin
      o_pre_ready_d1 <= o_pre_ready;
    end
end

always @(posedge clock)										      
    begin                                                                        
    if (reset)                                                   
        begin                                                                    
        init_txn_ff <= 1'b0;                                                   
        init_txn_ff2 <= 1'b0;     
        shift <= 2'b00;                                              
        end                                                                               
    else                                                                       
        begin  
        init_txn_ff <= INIT_AXI_TXN;
        init_txn_ff2 <= init_txn_ff;
        axi_axaddr <= alu_res;
        shift <= alu_res[1:0];  
        end                                                                      
    end     

  // always @(posedge clock)										      
  //   begin                                                                        
  //   if (reset)                                                   
  //       begin                                                                    
  //         idle <= 1'b1;
  //       end                                                                               
  //   else if((i_store || i_load) && idle) begin
  //     idle <= 1'b0;
  //   end            
  //   else if((M_AXI_RLAST && M_AXI_RREADY) || M_AXI_BREADY) begin
  //     idle <= 1'b1;
  //   end          
  //   else idle <= idle;                                                
  //   end     

	  always @(posedge clock)										      
	  begin                                                                         
	    if (reset)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	    else                                                                       
	      begin                                                                    
	        if (txn_pulse_store)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;
	          end                                                                  
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end      

	   always @(posedge clock)                                        
	   begin                                                                         
	     if (reset)                                                    
	       begin                                                                     
	         axi_wvalid <= 1'b0;       
	       end                                                                       
	     else if (txn_pulse_store)                                                
	       begin                                                                     
	         axi_wvalid <= 1'b1;       
	       end                                                                       
	     else if (M_AXI_WREADY && axi_wvalid)                                        
	       begin                                                                     
	        axi_wvalid <= 1'b0;         
	       end                                                                       
	   end                                                                           

	  always @(posedge clock)                                    
	  begin                                                                
	    if (reset)                                           
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                                                   
	    else if (M_AXI_BVALID && ~axi_bready)                              
	      begin                                                            
	        axi_bready <= 1'b1;                                            
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                                                                                  
    always @(posedge clock)                                                     
    begin                                                                            
    if (reset)                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    else if (txn_pulse_load)                                                    
        begin                                                                        
        axi_arvalid <= 1'b1;  
        end                                                                          
    else if (axi_arvalid && M_AXI_ARREADY)                                         
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    end                                                                              
                     
    always @(posedge clock)                                    
    begin                                                                 
    if (reset)                                                                                    
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                                                        
    else if (M_AXI_RVALID && ~axi_rready)                               
        begin                                                             
        axi_rready <= 1'b1;                                             
        end                                                               
    else if (axi_rready)                                                
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                               
    end 
                                
wire                   [  31:0]         axi_rdata                  ;
assign axi_rdata = M_AXI_RDATA >> shift8;

always @(*) begin
  case(exu_opt)
    LB  : load_res = {{24{axi_rdata[7]}}, axi_rdata[7:0]};
    LH  : load_res = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
    LW  : load_res = axi_rdata[31:0];
    LBU : load_res = {24'b0, axi_rdata[7:0]};
    LHU : load_res = {{16'b0}, axi_rdata[15:0]};
    default: load_res = 32'b0;
  endcase
end

endmodule
module ysyx_23060124_ALU (
    input       signed [  31:0]         src1                       ,
    input       signed [  31:0]         src2                       ,
    input              [   9:0]         opt                        ,
    output reg         [  31:0]         res                         
);

/***************parameter***************/
parameter ADD =  4'b0000;
parameter SUB =  4'b1000;
parameter SLL =  4'b0001;
parameter SLT =  4'b0010;
parameter SLTU=  4'b0011;
parameter XOR =  4'b0100;
parameter SRL =  4'b0101;
parameter OR  =  4'b0110;
parameter AND =  4'b0111;

localparam                              ALU_ADD         =  10'd1   ;
localparam                              ALU_SUB         =  10'd2   ;
localparam                              ALU_SLL         =  10'd4   ;
localparam                              ALU_SLT         =  10'd8   ;
localparam                              ALU_SLTU        =  10'd16  ;
localparam                              ALU_XOR         =  10'd32  ;
localparam                              ALU_SRL         =  10'd64  ;
localparam                              ALU_OR          =  10'd128 ;
localparam                              ALU_AND         =  10'd256 ;
localparam                              ALU_SRA         =  10'd512  ;

wire                   [  31:0]         add_res                    ;
wire                   [  31:0]         and_res                    ;
wire                   [  31:0]         or_res                     ;
wire                   [  31:0]         xor_res                    ;
wire                   [  31:0]         sll_res                    ;
wire                   [  31:0]         slt_res                    ;
wire                   [  31:0]         sltu_res                   ;
wire            signed [  31:0]         srl_res                    ;
wire                   [  31:0]         sra_res                    ;
wire                   [  31:0]         sub_res                    ;

wire                                    op_add                     ;
wire                                    op_sub                     ;
wire                                    op_and                     ;
wire                                    op_or                      ;
wire                                    op_xor                     ;
wire                                    op_sll                     ;
wire                                    op_slt                     ;
wire                                    op_sltu                    ;
wire                                    op_srl                     ;
wire                                    op_sra                     ;


assign op_add = opt[0];
assign op_sub = opt[1];
assign op_sll = opt[2];
assign op_slt = opt[3];
assign op_sltu= opt[4];
assign op_xor = opt[5];
assign op_srl = opt[6];
assign op_or  = opt[7];
assign op_and = opt[8];
assign op_sra = opt[9];

assign add_res      = src1 + src2;
assign sub_res      = src1 - src2;
assign and_res      = src1 & src2;
assign or_res       = src1 | src2;
assign xor_res      = src1 ^ src2;
assign sll_res      = src1 << src2[4:0];
assign srl_res      = src1 >>> src2[4:0];
assign sra_res      = src1 >> src2[4:0];
assign slt_res      = (src1[31] != src2[31]) ? (src1[31] ? 32'b1 : 32'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
assign sltu_res     = ({1'b0, src1} < {1'b0, src2}) ? 32'b1 : 32'b0;

always_comb begin
    unique case(1'b1)
        op_add:     res = add_res;
        op_sub:     res = sub_res;
        op_slt:     res = slt_res;
        op_sltu:    res = sltu_res;
        op_and:     res = and_res;
        op_or:      res = or_res;
        op_xor:     res = xor_res;
        op_sll:     res = sll_res;
        op_srl:     res = srl_res;
        op_sra:     res = sra_res;
        default:    res = 32'b0;
    endcase
end

endmodule
module ysyx_23060124_CSR_RegisterFile (
    input                               clock                      ,
    input                               reset                        ,
    input                               i_csr_wen                  ,
    input                               i_ecall                    ,
    input                               i_mret                     ,
    input              [  31:0]         i_pc                       ,
    
    input              [  11:0]         i_csr_raddr                ,
    output             [  31:0]         o_csr_rdata                ,

    input              [  11:0]         i_csr_waddr                ,
    input              [  31:0]         i_csr_wdata                ,

    output             [  31:0]         o_mepc                     ,
    output             [  31:0]         o_mtvec                    
);
// ysyx_23060124
wire [31:0] mvendorid , marchid;
wire [31:0] mcause;
assign mvendorid    = 32'h79737978;
assign marchid      = 32'h23060124;
assign mcause       = 32'd11;

reg [12:0] mstatus;
reg [31:0] mepc;
reg [31:0] mtvec;

always @(posedge  clock) begin
    if(reset) begin
        mstatus <= 13'b0;
        mepc <= 32'b0;
        mtvec <= 32'b0;
    end
    else if(i_ecall)begin
        mepc    <= i_pc;
        // mstatus <= {mstatus[31:13], 2'b11, mstatus[10:8],mstatus[3],mstatus[6:4], 1'b0, mstatus[2:0]};
        mstatus[7] <= mstatus[3];
        mstatus[12:11] <= 2'b11;
        mstatus[3] <= 1'b0;
    end
    else if(i_mret)begin
        mepc <= mepc;
        // mstatus <={mstatus[31:13], 2'b0, mstatus[10:8],1'b1,mstatus[6:4], 1'b0, mstatus[2:0]};
        mstatus[3] <= mstatus[7];
        mstatus[7] <= 1'b1;
        mstatus[12:11] <= 2'b0;
    end
    else if (i_csr_wen) begin 
        case (i_csr_waddr)
            // 12'h300: mstatus    <= i_csr_wdata[15:0];
            12'h341: mepc       <= i_csr_wdata;
            12'h305: mtvec      <= i_csr_wdata;
            default: begin
            end
        endcase
    end
    else begin
        mtvec <= mtvec;
        mepc <= mepc;
        mstatus <= mstatus;
    end
end 
// always @(*) begin
//     case(i_csr_raddr)
//         12'hf11: o_csr_rdata = mvendorid;
//         12'hf12: o_csr_rdata = marchid;
//         12'h300: o_csr_rdata = mstatus;
//         12'h341: o_csr_rdata = mepc;
//         12'h342: o_csr_rdata = mcause;
//         12'h305: o_csr_rdata = mtvec;
//         default: o_csr_rdata = 32'b0;
//     endcase
// end

assign o_csr_rdata  = i_csr_raddr == 12'hf11 ? mvendorid :
                      i_csr_raddr == 12'hf12 ? marchid :
                      i_csr_raddr == 12'h300 ? {19'b0, mstatus} :
                      i_csr_raddr == 12'h341 ? mepc :
                      i_csr_raddr == 12'h342 ? mcause :
                      i_csr_raddr == 12'h305 ? mtvec : 
                      32'b0;

assign o_mepc       = i_mret    ? mepc  : 32'b0;
assign o_mtvec      = i_ecall   ? mtvec : 32'b0;

endmodule
module ysyx_23060124_RegisterFile (
    input                               clock                      ,
    input                               reset                      ,
    input              [  31:0]         wdata                      ,
    input              [   3:0]         waddr                      ,
  
    //
    input              [   3:0]         exu_rd                     ,
    input              [  31:0]         exu_wdata                  ,
    input                               exu_wen                    ,
    input              [   3:0]         wbu_rd                     ,
    input              [  31:0]         wbu_wdata                  ,
    input                               wbu_wen                    ,
    //
    input                               idu_wen                    ,
    input              [   3:0]         idu_waddr                  ,
    // 
    input              [   3:0]         raddr1                     ,
    input              [   3:0]         raddr2                     ,

    output             [  31:0]         rdata1                     ,
    output             [  31:0]         rdata2                     ,
    input                               wen                         
);

reg  [31:0] regfile [15:1];
wire [31:0] rf      [15:0];

genvar i;
generate
  for(i = 1; i < 16; i = i + 1) begin
    assign rf[i] = regfile[i];
  end
endgenerate

assign rf[0] = 32'b0;

always @(posedge  clock) begin
  if (wen && waddr != 0) begin
    regfile[waddr[3:0]] <= wdata;
  end
end

assign rdata1 = (raddr1 == exu_rd && exu_wen)  ? exu_wdata:
                (raddr1 == wbu_rd && wbu_wen)  ? wbu_wdata:
                rf[raddr1[3:0]];

assign rdata2 = (raddr2 == exu_rd && exu_wen)  ? exu_wdata:
                (raddr2 == wbu_rd && wbu_wen)  ? wbu_wdata:
                rf[raddr2[3:0]];


endmodule

module ysyx_23060124_WBU (
    input                               clock                      ,
    input                               reset                      ,
    input                               i_pre_valid                ,
    input                               i_wen                      ,
    input              [   3:0]         i_rd_addr                  ,
    input              [  11:0]         i_csr_addr                 ,
    input                               i_csr_wen                  ,
    input                               i_brch                     ,
    input                               i_jal                      ,
    input                               i_jalr                     ,
    input                               i_ebreak                   ,
    input                               i_mret                     ,
    input                               i_ecall                    ,
    input              [  31:0]         i_pc_next                  ,
    // input                               i_next                     ,
  // ecall and mret

    input              [  31:0]         i_res                      ,

    output reg         [  31:0]         o_pc_next                  ,
    output             [  31:0]         o_rd_wdata                 ,
    output             [  31:0]         o_csr_rd_wdata             ,
    output                              o_wbu_wen                  ,
    output                              o_wbu_csr_wen              ,
    output             [   3:0]         o_rd_addr                  ,
    output             [  11:0]         o_csr_addr                 ,

    output reg                          o_pre_ready                ,
    output reg                          o_pc_update                 
);


wire [31:0] pc_next;

assign o_rd_wdata       = i_res;
assign o_csr_rd_wdata   = i_res;
assign o_wbu_wen        = i_wen ;
assign o_wbu_csr_wen    = i_csr_wen ;
assign o_rd_addr        =  i_rd_addr ;
assign o_csr_addr       =  i_csr_addr;

always @(posedge clock) begin
  if(reset) begin
    o_pre_ready <= 1'b1;
  end
  else begin
    o_pre_ready <= o_pre_ready;
  end
end

always @(posedge clock) begin
  if(reset) begin
    o_pc_update <= 1'b0;
  end
  else if(~o_pc_update) begin
    o_pc_update <= i_jal || i_jalr || i_brch  || i_ecall || i_mret;
  end
  else if(o_pc_update) begin
    o_pc_update <= 1'b0;
  end
end

always @(posedge clock) begin
  if(reset) begin
    o_pc_next <= 32'b0;
  end
  else begin
    o_pc_next <= i_pc_next;
  end
end

// `ifdef DIFF_TEST
// reg diff;
// always @(posedge clock)begin
//   if(reset) begin
//     diff <= 1'b0;
//   end
//   // else diff <= i_next && ((i_res != 32'b0) || (i_rd_addr != 4'b0) || (i_wen != 1'b0) || (i_jal || i_jalr || i_brch || i_ecall || i_mret) != 0);
//   else diff <= i_next;
// end
// `endif 

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
localparam                              REG_ADDR = 4               ;
localparam                              CSR_ADDR=12                ;

/******************global wires****************/
wire                                    rst_n_sync                 ;

wire                   [ISA_WIDTH-1:0]  imm,ins                    ;
wire                   [REG_ADDR-1:0]   idu_addr_rs1,idu_addr_rs2,idu_addr_rd;
wire                   [CSR_ADDR-1:0]   idu_csr_raddr              ;
wire                   [ISA_WIDTH-1:0]  rs1, rs2, wbu_rd_wdata     ;
//csr wdata rd_wdata
wire                   [ISA_WIDTH-1:0]  csr_rd_wdata               ;

wire                   [ISA_WIDTH-1:0]  exu_res                    ;
wire                                    exu_brch                   ;
//mret ecall
wire                   [ISA_WIDTH-1:0]  csr_rs2                    ;
wire                   [ISA_WIDTH-1:0]  mcause, mstatus, mepc, mtvec;

//load store
wire                   [3-1:0]          exu_opt                    ;
wire                   [   9:0]         alu_opt                    ;
wire                                    idu_wen, csr_wen, wbu_wen, wbu_csr_wen;
wire                   [ISA_WIDTH-1:0]  pc_next, ifu_pc_next       ;
wire                   [   1:0]         i_src_sel1                 ;
wire                   [   2:0]         i_src_sel2                 ;
wire                                    brch,jal,jalr              ;// idu -> pcu.
wire                                    ebreak                     ;
wire                                    if_store,if_load           ;// idu -> exu.
wire                                    ecall,mret                 ;// idu -> pcu.
wire                                    pc_update_en               ;
//
wire                                    ifu2idu_valid, idu2ifu_ready;
wire                                    idu2exu_valid, exu2idu_ready;
wire                                    exu2wbu_valid, wbu2exu_ready;
//cache 
wire                                    mem_valid                  ;
wire                                    ifu2cache_req              ;
wire                   [ISA_WIDTH-1:0]  icache_ins                 ;
wire                   [ISA_WIDTH-1:0]  ifu_req_addr               ;
wire                                    icache_hit                 ;
wire                                    fence_i                    ;

//write address channel  
wire                   [  31:0]         LSU_SRAM_AXI_AWADDR        ;
wire                                    LSU_SRAM_AXI_AWVALID       ;
wire                                    LSU_SRAM_AXI_AWREADY       ;
wire                   [   7:0]         LSU_SRAM_AXI_AWLEN         ;
wire                   [   2:0]         LSU_SRAM_AXI_AWSIZE        ;
wire                   [   1:0]         LSU_SRAM_AXI_AWBURST       ;
wire                   [   3:0]         LSU_SRAM_AXI_AWID          ;
//write data channel,
wire                                    LSU_SRAM_AXI_WVALID        ;
wire                                    LSU_SRAM_AXI_WREADY        ;
wire                   [  31:0]         LSU_SRAM_AXI_WDATA         ;
wire                   [   3:0]         LSU_SRAM_AXI_WSTRB         ;
wire                                    LSU_SRAM_AXI_WLAST         ;
//read data channel
wire                   [  31:0]         IFU_SRAM_AXI_RDATA         ;
wire                   [  31:0]         LSU_SRAM_AXI_RDATA         ;
wire                   [   1:0]         IFU_SRAM_AXI_RRESP, LSU_SRAM_AXI_RRESP;
wire                                    IFU_SRAM_AXI_RVALID, LSU_SRAM_AXI_RVALID;
wire                                    IFU_SRAM_AXI_RREADY, LSU_SRAM_AXI_RREADY;
wire                   [   3:0]         IFU_SRAM_AXI_RID,LSU_SRAM_AXI_RID;
wire                                    IFU_SRAM_AXI_RLAST,LSU_SRAM_AXI_RLAST;
    
//read adress channel
wire                   [  31:0]         IFU_SRAM_AXI_ARADDR, LSU_SRAM_AXI_ARADDR;
wire                                    IFU_SRAM_AXI_ARVALID, LSU_SRAM_AXI_ARVALID;
wire                                    IFU_SRAM_AXI_ARREADY, LSU_SRAM_AXI_ARREADY;
wire                   [   3:0]         IFU_SRAM_AXI_ARID,LSU_SRAM_AXI_ARID;
wire                   [   7:0]         IFU_SRAM_AXI_ARLEN   ,LSU_SRAM_AXI_ARLEN;
wire                   [   2:0]         IFU_SRAM_AXI_ARSIZE  ,LSU_SRAM_AXI_ARSIZE;
wire                   [   1:0]         IFU_SRAM_AXI_ARBURST ,LSU_SRAM_AXI_ARBURST;
//write back channel
wire                   [   1:0]         LSU_SRAM_AXI_BRESP         ;
wire                                    LSU_SRAM_AXI_BVALID        ;
wire                                    LSU_SRAM_AXI_BREADY        ;
wire                   [   3:0]         LSU_SRAM_AXI_BID           ;

//read data channel
wire                   [  31:0]         CLINT_AXI_RDATA            ;
wire                   [   1:0]         CLINT_AXI_RRESP            ;
wire                                    CLINT_AXI_RVALID           ;
wire                                    CLINT_AXI_RREADY           ;
wire                   [   3:0]         CLINT_AXI_RID              ;
wire                                    CLINT_AXI_RLAST            ;
    
//read adress channel
wire                                    CLINT_AXI_ARADDR           ;
wire                                    CLINT_AXI_ARVALID          ;
wire                                    CLINT_AXI_ARREADY          ;
wire                   [   3:0]         CLINT_AXI_ARID             ;
wire                   [   7:0]         CLINT_AXI_ARLEN            ;
wire                   [   2:0]         CLINT_AXI_ARSIZE           ;
wire                   [   1:0]         CLINT_AXI_ARBURST          ;


ysyx_23060124_stdrst u_stdrst(
    .clock                             (clock                     ),
    .i_rst_n                           (reset                     ),
    .o_rst_n_sync                      (rst_n_sync                ) 
);

wire                   [   3:0]         wbu_rd_addr                ;
wire                   [  11:0]         wbu_csr_addr               ;

ysyx_23060124_RegisterFile regfile1(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .waddr                             (wbu_rd_addr               ),
    .wdata                             (wbu_rd_wdata              ),
    .wen                               (wbu_wen                   ),
//
    .exu_rd                            (idu2exu_rd                ),
    .exu_wdata                         (exu_res                   ),
    .exu_wen                           (idu2exu_wen               ),
    .wbu_rd                            (exu2wbu_rd_addr           ),
    .wbu_wdata                         (exu2wbu_res               ),
    .wbu_wen                           (exu2wbu_wen               ),
//
    .raddr1                            (idu_addr_rs1              ),
    .raddr2                            (idu_addr_rs2              ),
    .rdata1                            (rs1                       ),
    .rdata2                            (rs2                       ),
        //scoreboard
    .idu_wen                           (idu_wen                   ),
    .idu_waddr                         (idu_addr_rd               )
);

ysyx_23060124_CSR_RegisterFile Csrs(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .i_csr_wen                         (wbu_csr_wen               ),
    .i_ecall                           (ecall                     ),
    .i_mret                            (mret                      ),
    .i_pc                              (ifu2idu_pc                ),

    .i_csr_raddr                       (idu_csr_raddr             ),
    .o_csr_rdata                       (csr_rs2                   ),

    .i_csr_waddr                       (wbu_csr_addr              ),
    .i_csr_wdata                       (csr_rd_wdata              ),

    .o_mepc                            (mepc                      ),
    .o_mtvec                           (mtvec                     ) 
);
  
ysyx_23060124__icache icache1(
    .clock                             (clock                     ),
    .rst_n_sync                        (rst_n_sync                ),
    .addr                              (ifu_req_addr              ),
    .data                              (icache_ins                ),
    .hit                               (icache_hit                ),
    .fence_i                           (fence_i                   ),
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
    .M_AXI_ARBURST                     (IFU_SRAM_AXI_ARBURST      ) 
);


wire                   [  31:0]         ifu2idu_ins                ;
wire                   [  31:0]         ifu2idu_pc                 ;

ysyx_23060124_IFU ifu1
(
    .i_pc_next                         (pc_next                   ),
    .clock                             (clock                     ),
    .rst_n_sync                        (rst_n_sync                ),
    .i_pc_update                       (pc_update_en              ),
    .ins                               (ins                       ),
  //ifu -> idu handshake
    .i_post_ready                      (idu2ifu_ready             ),
    .pc_next                           (ifu_pc_next               ),
  //cache -> ifu
    .hit                               (icache_hit                ),
    .icache_ins                        (icache_ins                ),
    .req_addr                          (ifu_req_addr              ) 
);

ysyx_23060124_ifu_idu_regs ifu2idu_regs(
    .i_pc                              (ifu_pc_next               ),
    .o_pc                              (ifu2idu_pc                ),
    .i_ins                             (ins                       ),
    .o_ins                             (ifu2idu_ins               ),
    .clock                             (clock                     ),
    .reset                             (reset  || pc_update_en  || idu2exu_fence_i),

    .icache_hit                        (icache_hit                ),
    .i_pre_valid                       (pc_update_en              ),
    .i_post_ready                      (idu2ifu_ready             ),
    .o_post_valid                      (ifu2idu_valid             ) 
);

ysyx_23060124_IDU idu1(
    .clock                             (clock                     ),
    .ins                               (ifu2idu_ins               ),
    .reset                             (reset                     ),

    .o_imm                             (imm                       ),
    .o_rd                              (idu_addr_rd               ),
    .o_rs1                             (idu_addr_rs1              ),
    .o_rs2                             (idu_addr_rs2              ),
    .o_csr_addr                        (idu_csr_raddr             ),
    .o_exu_opt                         (exu_opt                   ),
    .o_alu_opt                         (alu_opt                   ),
    .o_wen                             (idu_wen                   ),
    .o_csr_wen                         (csr_wen                   ),
    .o_src_sel1                        (i_src_sel1                ),
    .o_src_sel2                        (i_src_sel2                ),
    .o_ecall                           (ecall                     ),
    .o_mret                            (mret                      ),
    .o_load                            (if_load                   ),
    .o_store                           (if_store                  ),
    .o_brch                            (brch                      ),
    .o_jal                             (jal                       ),
    .o_jalr                            (jalr                      ),
    .o_ebreak                          (ebreak                    ),
    .o_fence_i                         (fence_i                   ) 
);

wire                   [  31:0]         idu2exu_pc                 ;
wire                   [  31:0]         idu2exu_src1               ;
wire                   [  31:0]         idu2exu_src2               ;
wire                   [  31:0]         idu2exu_imm                ;
wire                   [   1:0]         idu2exu_src_sel1           ;
wire                   [   2:0]         idu2exu_src_sel2           ;
wire                   [   3:0]         idu2exu_rd                 ;
wire                   [   2:0]         idu2exu_exu_opt            ;
wire                   [   9:0]         idu2exu_alu_opt            ;
wire                                    idu2exu_wen                ;
wire                                    idu2exu_csr_wen            ;
wire                                    idu2exu_mret               ;
wire                                    idu2exu_ecall              ;
wire                                    idu2exu_load               ;
wire                                    idu2exu_store              ;
wire                                    idu2exu_brch               ;
wire                                    idu2exu_jal                ;
wire                                    idu2exu_jalr               ;
wire                                    idu2exu_ebreak             ;
wire                                    idu2exu_fence_i            ;
wire                   [  11:0]         idu2exu_csr_addr           ;

ysyx_23060124_idu_exu_regs idu2exu_regs(
    .clock                             (clock                     ),
    .reset                             (reset || pc_update_en || idu2exu_fence_i),
    .i_pre_valid                       (ifu2idu_valid             ),
    .i_post_ready                      (exu2idu_ready             ),
    .o_pre_ready                       (idu2ifu_ready             ),
    .o_post_valid                      (idu2exu_valid             ),

    .i_pc                              (ifu2idu_pc                ),
    .i_imm                             (imm                       ),
    .i_csr_addr                        (idu_csr_raddr             ),
    .i_src1                            (rs1                       ),
    .i_src2                            (rs2                       ),
    //mepc mtvec
    .i_mepc                            (mepc                      ),
    .i_mtvec                           (mtvec                     ),
    //
    .i_rd                              (idu_addr_rd               ),
    .i_csr_rs2                         (csr_rs2                   ),
    .i_csr_src_sel                     (csr_wen                   ),
    .i_exu_opt                         (exu_opt                   ),
    .i_alu_opt                         (alu_opt                   ),

    .i_wen                             (idu_wen                   ),
    .i_csr_wen                         (csr_wen                   ),
    .i_src_sel1                        (i_src_sel1                ),
    .i_src_sel2                        (i_src_sel2                ),
    .i_mret                            (mret                      ),
    .i_ecall                           (ecall                     ),
    .i_load                            (if_load                   ),
    .i_store                           (if_store                  ),
    .i_brch                            (brch                      ),
    .i_jal                             (jal                       ),
    .i_jalr                            (jalr                      ),
    .i_fence_i                         (fence_i                   ),
    .i_ebreak                          (ebreak                    ),
    
    .o_pc                              (idu2exu_pc                ),
    .o_src1                            (idu2exu_src1              ),
    .o_src2                            (idu2exu_src2              ),
    .o_imm                             (idu2exu_imm               ),
    .o_src_sel1                        (idu2exu_src_sel1          ),
    .o_src_sel2                        (idu2exu_src_sel2          ),
    .o_rd                              (idu2exu_rd                ),
    .o_exu_opt                         (idu2exu_exu_opt           ),
    .o_alu_opt                         (idu2exu_alu_opt           ),
    .o_wen                             (idu2exu_wen               ),
    .o_csr_wen                         (idu2exu_csr_wen           ),
    .o_mret                            (idu2exu_mret              ),
    .o_ecall                           (idu2exu_ecall             ),
    .o_load                            (idu2exu_load              ),
    .o_store                           (idu2exu_store             ),
    .o_brch                            (idu2exu_brch              ),
    .o_jal                             (idu2exu_jal               ),
    .o_jalr                            (idu2exu_jalr              ),
    .o_ebreak                          (idu2exu_ebreak            ),
    .o_fence_i                         (idu2exu_fence_i           ),
    //
    .o_csr_addr                        (idu2exu_csr_addr          )
);

wire                   [  31:0]         exu_pc_next                ;
ysyx_23060124_EXU exu1(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .i_src1                            (idu2exu_src1              ),
    .i_src2                            (idu2exu_src2              ),
    .i_imm                             (idu2exu_imm               ),
    .i_pc                              (idu2exu_pc                ),
    .i_src_sel1                         (idu2exu_src_sel1           ), 
    .i_src_sel2                         (idu2exu_src_sel2           ),
    //control signal
    .i_load                            (idu2exu_load              ),
    .i_store                           (idu2exu_store             ),
    .i_brch                            (idu2exu_brch              ),
    .i_jal                             (idu2exu_jal               ),
    .i_jalr                            (idu2exu_jalr              ),
    //
    .i_ecall                           (idu2exu_ecall             ),
    .i_mret                            (idu2exu_mret              ),

    .exu_opt                           (idu2exu_exu_opt           ),
    .i_alu_opt                         (idu2exu_alu_opt           ),
    .o_res                             (exu_res                   ),
    .o_brch                            (exu_brch                  ),
    .o_pc_next                         (exu_pc_next               ),
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
wire                   [  31:0]         exu2wbu_pc_next            ;
wire                   [  11:0]         exu2wbu_csr_addr           ;
wire                   [   3:0]         exu2wbu_rd_addr            ;
wire                                    exu2wbu_wen                ;
wire                                    exu2wbu_csr_wen            ;
wire                                    exu2wbu_brch               ;
wire                                    exu2wbu_jal                ;
wire                                    exu2wbu_jalr               ;
wire                                    exu2wbu_mret               ;
wire                                    exu2wbu_ecall              ;
wire                   [  31:0]         exu2wbu_res                ;
wire                                    exu2wbu_ebreak             ;
wire                                    exu2wbu_next               ;

ysyx_23060124_exu_wbu_regs exu_wbu_regs (
    .clock                             (clock                     ),
    .reset                             (reset || pc_update_en     ),
    .i_brch                            (exu_brch                  ),
    .i_jal                             (idu2exu_jal               ),
    .i_wen                             (idu2exu_wen               ),
    .i_csr_wen                         (idu2exu_csr_wen           ),
    .i_jalr                            (idu2exu_jalr              ),
    .i_ebreak                          (idu2exu_ebreak            ),
    .i_mret                            (idu2exu_mret              ),
    .i_ecall                           (idu2exu_ecall             ),
    .i_res                             (exu_res                   ),
    .i_pc_next                         (exu_pc_next               ),
    .i_csr_addr                        (idu2exu_csr_addr          ),
    .i_rd_addr                         (idu2exu_rd                ),

    .o_pc_next                         (exu2wbu_pc_next           ),
    .o_csr_addr                        (exu2wbu_csr_addr          ),
    .o_rd_addr                         (exu2wbu_rd_addr           ),
    .o_wen                             (exu2wbu_wen               ),
    .o_csr_wen                         (exu2wbu_csr_wen           ),
    .o_brch                            (exu2wbu_brch              ),
    .o_jal                             (exu2wbu_jal               ),
    .o_jalr                            (exu2wbu_jalr              ),
    .o_mret                            (exu2wbu_mret              ),
    .o_ecall                           (exu2wbu_ecall             ),
    .o_res                             (exu2wbu_res               ),
    .o_ebreak                          (exu2wbu_ebreak            ),
    // .o_next                            (exu2wbu_next              ),
    .i_post_ready                      (wbu2exu_ready             ),
    .o_post_valid                      (exu2wbu_valid             ) 
);

ysyx_23060124_WBU wbu1(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
    .i_pc_next                         (exu2wbu_pc_next           ),
    .i_pre_valid                       (exu2wbu_valid             ),
    // .i_next                            (exu2wbu_next              ),

    .i_rd_addr                         (exu2wbu_rd_addr           ),
    .i_csr_addr                        (exu2wbu_csr_addr          ),
    .i_brch                            (exu2wbu_brch              ),
    .i_jal                             (exu2wbu_jal               ),
    .i_wen                             (exu2wbu_wen               ),
    .i_csr_wen                         (exu2wbu_csr_wen           ),
    .i_jalr                            (exu2wbu_jalr              ),
    .i_ebreak                          (exu2wbu_ebreak            ),
    .i_mret                            (exu2wbu_mret              ),
    .i_ecall                           (exu2wbu_ecall             ),

    .i_res                             (exu2wbu_res               ),

    .o_pc_next                         (pc_next                   ),
    .o_pc_update                       (pc_update_en              ),
    .o_rd_wdata                        (wbu_rd_wdata              ),
    .o_rd_addr                         (wbu_rd_addr               ),
    //
    .o_csr_addr                        (wbu_csr_addr              ),
    .o_csr_rd_wdata                    (csr_rd_wdata              ),
    //
    .o_wbu_wen                         (wbu_wen                   ),
    .o_wbu_csr_wen                     (wbu_csr_wen               ),
    .o_pre_ready                       (wbu2exu_ready             ) 
);


ysyx_23060124_Xbar xbar
(
    .clock                             (clock                     ),
    .RESETN                            (rst_n_sync                ),

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
    .SRAM_RREADY                       (io_master_rready          ),
    .SRAM_RLAST                        (io_master_rlast           ),
    .SRAM_RID                          (io_master_rid             ) 
);


CLINT clint
(
    .clock                             (clock                     ),
    .reset                             (reset                     ),
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
    .S_AXI_ARBURST                     (CLINT_AXI_ARBURST         )
);


// import "DPI-C" function void csr_cnt_dpic    ();
// import "DPI-C" function void brch_cnt_dpic   ();
// import "DPI-C" function void jal_cnt_dpic    ();
// import "DPI-C" function void ifu_start  ();
// import "DPI-C" function void ifu_end  ();
// import "DPI-C" function void icache_end  ();
// import "DPI-C" function void load_start  ();
// import "DPI-C" function void load_end  ();
// import "DPI-C" function void store_start  ();
// import "DPI-C" function void store_end  ();


// always @(posedge clock) begin
//   if(exu2wbu_brch) begin
//     brch_cnt_dpic();
//   end
//   if(exu2wbu_jalr || exu2wbu_jal) begin
//     jal_cnt_dpic();
//   end
//   if(exu2wbu_csr_wen) begin
//     csr_cnt_dpic();
//   end
// end

// always @(posedge clock) begin
//   if(IFU_SRAM_AXI_ARVALID && IFU_SRAM_AXI_ARREADY) begin
//     ifu_start();
//   end
//   else if(IFU_SRAM_AXI_RREADY && IFU_SRAM_AXI_RLAST) begin
//     ifu_end();
//   end
//   if(icache_hit) begin
//     icache_end();
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

module ysyx_23060124_IFU
(
    input              [  31:0]         i_pc_next                  ,
    input                               clock                      ,
    input                               rst_n_sync                 ,
    input                               i_pc_update                ,
    input                               i_post_ready               ,
    output             [  31:0]         ins                        ,
    output reg         [  31:0]         pc_next                    ,
    //ifu_to_cache
    output             [  31:0]         req_addr                   ,
    input              [  31:0]         icache_ins                 ,
    input                               hit                         
);

localparam                              RESET_PC = 32'h3000_0000   ;

assign req_addr = pc_next;

always @(posedge  clock or negedge rst_n_sync) begin
  if (~rst_n_sync) pc_next <= RESET_PC;
  else if(i_pc_update) pc_next <= i_pc_next;
  else if(hit && i_post_ready) pc_next <= pc_next + 4;
  else pc_next <= pc_next;
end

assign ins = icache_ins;

endmodule
module ysyx_23060124_ifu_idu_regs (
    input              [  31:0]         i_pc                       ,
    input              [  31:0]         i_ins                      ,
    output reg         [  31:0]         o_pc                       ,
    output reg         [  31:0]         o_ins                      ,
    input                               clock                      ,
    input                               reset                      ,
    // handshake signals
    input                               icache_hit              ,
    input                               i_pre_valid                ,
    input                               i_post_ready               ,
    output                              o_post_valid                

);

reg post_valid;
assign o_post_valid = i_post_ready && icache_hit;

// always @(posedge clock or posedge reset) begin
//     if(reset) begin
//         post_valid <= 1'b0;   
//     end
//     else if(icache_hit) begin
//         post_valid <= 1'b1;
//     end
//     else if(~icache_hit)begin
//         post_valid <= 1'b0;
//     end
// end


always @(posedge clock or posedge reset) begin
    if(reset) begin
        o_pc <= 32'h0;
        o_ins <= 32'h0;
    end
    else if(icache_hit && i_post_ready) begin
        o_pc <= i_pc;
        o_ins <= i_ins;
    end
    else if(~icache_hit && i_post_ready) begin
        o_pc <= 32'h0;
        o_ins <= 32'h0;
    end
    else if(icache_hit && ~i_post_ready) begin
        o_pc <= o_pc;
        o_ins <= o_ins;
    end
end

endmodule   module ysyx_23060124__icache #(
    parameter                           ADDR_WIDTH = 32            ,
    parameter                           DATA_WIDTH = 32            ,
    parameter                           CACHE_SIZE = 16            ,// Number of cache blocks 
    parameter                           WAY_NUMS = 2               ,// Block size in bytes
    parameter                           BYTES_NUMS = 8             
)
(
   //read data channel
    input              [  31:0]         M_AXI_RDATA                ,
    input              [   1:0]         M_AXI_RRESP                ,
    input                               M_AXI_RVALID               ,
    output                              M_AXI_RREADY               ,
    input              [   3:0]         M_AXI_RID                  ,
    input                               M_AXI_RLAST                ,

    //read adress channel
    output             [  31:0]         M_AXI_ARADDR               ,
    output                              M_AXI_ARVALID              ,
    input                               M_AXI_ARREADY              ,
    output             [   3:0]         M_AXI_ARID                 ,
    output             [   7:0]         M_AXI_ARLEN                ,
    output             [   2:0]         M_AXI_ARSIZE               ,
    output             [   1:0]         M_AXI_ARBURST              ,

    input                               clock                        ,
    input                               rst_n_sync                 ,
    input              [ADDR_WIDTH-1:0] addr                       ,
    output             [DATA_WIDTH-1:0] data                       ,

    input                               fence_i                    ,
    output                              hit                         
);
localparam                              BLOCK_SIZE = 4*BYTES_NUMS  ;
localparam                              ARLEN   =  BLOCK_SIZE/4 - 1;
localparam                              RINDEX = $clog2(BYTES_NUMS);//index = log2(CACHE_SIZE) = 3 = n
localparam                              INDEX_BITS = $clog2(WAY_NUMS);//index = log2(CACHE_SIZE) = 1
localparam                              OFFSET_BITS = $clog2(BLOCK_SIZE);//offset = log2(BLOCK_SIZE) = 5 = m
localparam                              TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;//tag = 32 - 5  -1 = 26

// AXI
/******************************regs*****************************/
    // Initiate AXI transactions
reg                                         axi_arvalid                ;
reg                                         axi_rready                 ;
reg                    [   RINDEX-1:0]      read_index                 ;
reg                    [  31-OFFSET_BITS:0] araddr                     ;
reg                                         idle                       ;
/******************************nets*****************************/
    // AXI clock signal
    // AXI active low reset signal
/******************************combinational logic*****************************/
        
    assign M_AXI_ARADDR = {araddr, {OFFSET_BITS{1'b0}}};
    // assign M_AXI_ARADDR     = addr;
    assign M_AXI_ARVALID    = axi_arvalid;
    assign M_AXI_ARID       = 'b0;
    assign M_AXI_ARLEN      = ARLEN;
    assign M_AXI_ARSIZE     = 3'b010;
    assign M_AXI_ARBURST    = 2'b01; //incrementing burst
    assign M_AXI_RREADY     = axi_rready; 


// Cache control logic 
always @(posedge clock)
begin
    if(~rst_n_sync) 
        begin
            cache_valid <= 'b0;
        end
    else if(M_AXI_ARVALID && ~M_AXI_ARREADY) begin
        cache_tag[index]   <= tag;
        cache_valid[index] <= 1'b0;                                                       
    end
    else if(M_AXI_RLAST) begin
        cache_valid[index] <= 1'b1;
    end
    else if(fence_i) begin
        cache_valid <= 'b0;
    end
end
	  always @(posedge clock)                                       
	  begin                                                              
	    if (rst_n_sync == 0)                                          
	      begin                                                          
	        araddr <= 'b0;    
            idle <= 1'b1;                                       
	      end
        else if(!hit && idle) begin
            araddr <= addr[31:OFFSET_BITS];
            idle <= 1'b0;
        end
        else if(M_AXI_RLAST && M_AXI_RREADY) begin
            if(hit) begin
                araddr <= 'b0;
                idle <= 1'b1;
            end
            else araddr <= addr[31:OFFSET_BITS];
        end                                                                                  
	    else                                                             
	      araddr <= araddr;     
	  end                                                                

//----------------------------
//Read Address Channel
//----------------------------       
    // A new axi_arvalid is asserted when there is a hit read address              
    // available by the master. start_single_read triggers a new read                
    // transaction                                                                   
    always @(posedge clock)                                                     
    begin                                                                            
    if (rst_n_sync == 0)                                                   
        begin                                                                        
        axi_arvalid <= 1'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if (!hit && idle)                                                    
        begin                                                                        
        axi_arvalid <= 1'b1;     
        end                                                                          
    //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)    
    else if (axi_arvalid && M_AXI_ARREADY)                                         
        begin                                                                        
        axi_arvalid <= 1'b0;
        end
    else if(M_AXI_RLAST && M_AXI_RREADY && (!hit)) begin
        axi_arvalid <= 1'b1;
    end       
    else axi_arvalid <= axi_arvalid;                                                             
    // retain the previous value                                                   
    end                                                                              

    // read index
    always @(posedge clock)                                                     
    begin                                                                            
    if (M_AXI_ARVALID && M_AXI_ARREADY)                                                   
        begin                                                                        
        read_index <= 'b0;                                                       
        end                                                                          
    //Signal a new read address command is available by user logic                 
    else if(M_AXI_RVALID && ~M_AXI_RREADY) begin
        read_index <= read_index + 1;   
    end                                        
    else read_index <= read_index;          
    end                   
//--------------------------------
//Read Data (and Response) Channel
//--------------------------------

//The Read Data channel returns the results of the read request 
//The master will accept the read data by asserting axi_rready
//when there is a hit read data available.
//While not necessary per spec, it is advisable to reset READY signals in
//case of differing reset latencies between master/slave.

    always @(posedge clock)                                    
    begin                                                                 
    if (rst_n_sync == 0)                                                                                    
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                                                       
    else if (M_AXI_RVALID && ~axi_rready)                               
        begin                                                             
        axi_rready <= 1'b1;                                             
        end                                                               
    // deassert after one clock cycle                                   
    else if (axi_rready)                                                
        begin                                                             
        axi_rready <= 1'b0;                                             
        end                                                                                                      
    end 

reg                    [DATA_WIDTH-1:0] cache_data  [WAY_NUMS-1:0][BYTES_NUMS-1:0]                           ;
reg                    [TAG_BITS-1:0]   cache_tag   [WAY_NUMS-1:0]                           ;
reg                    [WAY_NUMS-1:0]   cache_valid                ;

wire [TAG_BITS-1:0]   tag   = araddr[ADDR_WIDTH-OFFSET_BITS-1:INDEX_BITS]; // tag = M_AXI_ARADDR[31:6]
wire [INDEX_BITS-1:0] index = araddr[OFFSET_BITS+INDEX_BITS-OFFSET_BITS-1:0]; // index = M_AXI_ARADDR[4+2:4]


always @(posedge clock) begin
    if(M_AXI_RVALID && ~axi_rready) begin
            cache_data [index][read_index] <= M_AXI_RDATA;
        end
end


//TODO: hit_tag
assign data = cache_data[hit_index][hit_offset[OFFSET_BITS-1:2]];

wire                   [TAG_BITS-1:0]   hit_tag                    ;
wire                   [INDEX_BITS-1:0] hit_index                  ;
wire                   [OFFSET_BITS-1:0]hit_offset                 ;

assign hit_tag    = addr[ADDR_WIDTH-1               : INDEX_BITS+OFFSET_BITS];
assign hit_index  = addr[OFFSET_BITS+INDEX_BITS-1   : OFFSET_BITS];
assign hit_offset = addr[OFFSET_BITS-1              :0];

assign hit  =  cache_valid[hit_index] && (cache_tag[hit_index] == hit_tag);


// import "DPI-C" function void cache_miss ();

// always @(posedge clock) begin
//  if(!hit && idle) begin
//     cache_miss();
//   end
// end

endmodule
