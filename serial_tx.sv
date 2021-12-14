module serial_tx #(WAIT_DIV = 434) (
    input  logic CLK, RST_N, 
    input  logic [7:0] send_data,
    input  logic Sdata_valid,
    
    output logic txd, Send_fin
);

    typedef enum {
        s_send,
        s_wait,
        s_fin
    } state_type;

    state_type state, n_state;

    logic [3:0] byte_cnt, n_byte_cnt;
    logic WE, Busy;

    serial_send #(WAIT_DIV) serial_send_instance(.*, .data_in(send_data), .data_out(txd));

    always_comb begin
        n_state    = state;
        n_byte_cnt = byte_cnt;
        WE         = 1'b0;
        Send_fin   = 1'b0; 
        if (state == s_send) begin
            if (Sdata_valid) begin
                n_state = s_wait;
                WE      = 1'b1;
            end
        end else if (state == s_wait) begin
            if (~Busy) begin
                if (byte_cnt == 4'd0) begin
                    n_state = s_fin;
                end else begin
                    n_state = s_send;
                    n_byte_cnt = byte_cnt + 1'b1;
                end
            end
        end else if (state == s_fin) begin
            n_state  = s_send;
            Send_fin = 1'b1; 
        end
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (~RST_N) begin
            state    <= s_send;
            byte_cnt <= 4'd0;
        end else begin
            state    <= n_state;
            byte_cnt <= n_byte_cnt;
        end
    end

endmodule
