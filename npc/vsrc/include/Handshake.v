module handshaking (
    input wire clk,
    input wire reset_n,
    input wire need_to_send, // 需要发送消息的信号
    input wire slave_ready,  // 从设备的ready信号
    output reg valid         // 主设备的valid信号
);

    // 状态定义
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        WAIT_READY = 2'b01
    } state_t;

    state_t state, next_state;

    // 状态转移逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 状态机逻辑
    always @(*) begin
        valid = 1'b0; // 默认valid信号无效
        next_state = state; // 默认保持当前状态
        case (state)
            IDLE: begin
                if (need_to_send) begin
                    valid = 1'b1;
                    next_state = WAIT_READY;
                end
            end
            WAIT_READY: begin
                valid = 1'b1;
                if (slave_ready) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
