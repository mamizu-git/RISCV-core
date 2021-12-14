module serial_send #(WAIT_DIV = 434) (
    input  logic CLK, RST_N, 
    input  logic [7:0] data_in,
    input  logic WE,
    
    output logic data_out,
    output logic Busy
);

    localparam WAIT_LEN = $clog2(WAIT_DIV);

    typedef enum {
        s_idle,
        s_send
    } state_type; 

    state_type state, n_state;

    logic [9:0] data_reg, n_data_reg;
    logic [WAIT_LEN-1:0] wait_cnt, n_wait_cnt;
    logic [3:0] bit_cnt, n_bit_cnt;

    assign data_out = data_reg[0];

    always_comb begin
        Busy       = 1'b0;
        n_state    = state;
        n_data_reg = data_reg;
        n_wait_cnt = wait_cnt;
        n_bit_cnt  = bit_cnt;
        if (state == s_idle) begin
            if (WE) begin
                n_state    = s_send;
                n_data_reg = {1'b1, data_in, 1'b0};
            end
        end else if (state == s_send) begin
            Busy = 1'b1;
            if (wait_cnt == WAIT_DIV - 1) begin
                if (bit_cnt == 4'd9) begin
                    n_state    = s_idle;
                    n_wait_cnt = 0;
                    n_bit_cnt  = 4'd0;
                end else begin
                    n_data_reg = {1'b1, data_reg[9:1]};
                    n_wait_cnt = 0;
                    n_bit_cnt  = bit_cnt + 1'b1;
                end
            end else begin
                n_wait_cnt = wait_cnt + 1'b1;
            end
        end
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (~RST_N) begin
            state    <= s_idle;
            data_reg <= 10'h3ff;
            wait_cnt <= 0;
            bit_cnt  <= 4'd0;
        end else begin
            state    <= n_state;
            data_reg <= n_data_reg;
            wait_cnt <= n_wait_cnt;
            bit_cnt  <= n_bit_cnt;
        end
    end

endmodule
