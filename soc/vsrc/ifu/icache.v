module ysyx_23060124__icache #(
    parameter                           ADDR_WIDTH = 32            ,
    parameter                           DATA_WIDTH = 32            ,
    parameter                           CACHE_SIZE = 8            ,// Number of cache blocks 
    parameter                           BLOCK_SIZE = 4              // Block size in bytes
) (
    input  wire                         clk                        ,
    input  wire                         rst                        ,
    input  wire        [ADDR_WIDTH-1:0] addr                       ,
    input  wire                         req                        ,// 请求信号
    output wire        [DATA_WIDTH-1:0] data                       ,
    output wire                         hit                        ,
    input  wire        [DATA_WIDTH-1:0] mem_data                   ,
    input  wire                         mem_valid                   
);

    localparam INDEX_BITS = $clog2(CACHE_SIZE); //index = log2(CACHE_SIZE) = 4 = n
    localparam OFFSET_BITS = $clog2(BLOCK_SIZE); //offset = log2(BLOCK_SIZE) = 2 = m
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS; //tag = 32 - 4 - 2 = 26

    // Cache storage arrays
    reg [DATA_WIDTH-1:0] cache_data [CACHE_SIZE-1:0];
    reg [TAG_BITS-1:0] cache_tag [CACHE_SIZE-1:0];
    reg cache_valid [CACHE_SIZE-1:0];

    wire [TAG_BITS-1:0] tag = addr[ADDR_WIDTH-1:INDEX_BITS+OFFSET_BITS];
    wire [INDEX_BITS-1:0] index = addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [OFFSET_BITS-1:0] offset = addr[OFFSET_BITS-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset cache
            integer i;
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                cache_valid[i] <= 1'b0;
            end
            end else if(mem_valid) begin
                if (mem_valid) begin
                    // Update cache block on memory response
                    cache_valid[index] <= 1'b1;
                    cache_tag[index] <= tag;
                    cache_data[index] <= mem_data;
                end
            end
        end

assign data = hit ? cache_data[index] : 32'b0;
assign hit  = (req && cache_valid[index] && cache_tag[index] == tag);
endmodule
