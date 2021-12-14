module serial_receive #(WAIT_DIV = 434) (
    input  logic CLK, RST_N, 
    input  logic data_in, Ready,
    
    output logic [7:0] data_out,
    output logic Rdata_valid
);

    localparam WAIT_LEN = $clog2(WAIT_DIV);
    localparam WAIT_DIV_HALF = WAIT_DIV / 2;

    typedef enum {
        s_idle,
        s_start,
        s_receive
    } state_type; 

    state_type state, n_state;

    logic [7:0] n_data_out;
    logic [WAIT_LEN-1:0] wait_cnt, n_wait_cnt;
    logic [3:0] bit_cnt, n_bit_cnt;

    always_comb begin
        n_state    = state;
        n_data_out = data_out;
        n_wait_cnt = wait_cnt;
        n_bit_cnt  = bit_cnt;
        Rdata_valid = 1'b0;
        if (state == s_idle) begin
            if (Ready) begin
                n_state = s_start;
            end
        end else if (state == s_start) begin
            if (wait_cnt == WAIT_DIV_HALF - 1) begin
                n_state    = s_receive;
                n_wait_cnt = 0;
                n_bit_cnt  = 4'd0;
            end else begin
                n_wait_cnt = wait_cnt + 1'b1;
            end
        end else if (state == s_receive) begin
            if (wait_cnt == WAIT_DIV - 1) begin
                if (bit_cnt == 4'd8) begin
                    n_state    = s_idle;
                    n_wait_cnt = 0;
                    n_bit_cnt  = 4'd0;
                    Rdata_valid = 1'b1;
                end else begin
                    n_data_out = {data_in, data_out[7:1]};
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
            data_out <= 8'hff;
            wait_cnt <= 0;
            bit_cnt  <= 4'd0;
        end else begin
            state    <= n_state;
            data_out <= n_data_out;
            wait_cnt <= n_wait_cnt;
            bit_cnt  <= n_bit_cnt;
        end
    end

endmodule
