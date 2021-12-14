module serial_rx #(WAIT_DIV = 434) (
    input  logic CLK, RST_N, 
    input  logic rxd,
    
    output logic Rdata_valid, Receive_fin,
    output logic [7:0] receive_data
);

    typedef enum {
        s_wait_num,
        s_receive_num,
        s_wait_inst,
        s_receive_inst,
        s_fin
    } state_type;

    state_type state, n_state;

    logic [31:0] num, n_num;
    logic [31:0] byte_cnt, n_byte_cnt;
    logic Ready;

    serial_receive #(WAIT_DIV) serial_receive_instance(.*, .data_in(sync_reg[0]), .data_out(receive_data));

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (~RST_N) begin
            sync_reg <= 3'b111;
        end else begin
            sync_reg <= {rxd, sync_reg[2:1]};
        end
    end

    (* ASYNC_REG = "true" *) logic [2:0] sync_reg;

    always_comb begin
        n_state     = state;
        n_num       = num;
        n_byte_cnt  = byte_cnt;
        Ready       = 1'b0;
        Receive_fin = 1'b0;
        if (state == s_wait_num) begin
            if (sync_reg[0] == 1'b0) begin
                n_state = s_receive_num;
                Ready   = 1'b1;
            end
        end else if (state == s_receive_num) begin
            if (Rdata_valid) begin
                if (byte_cnt == 32'd3) begin
                    n_state    = s_wait_inst;
                    n_num      = {receive_data, num[31:8]};
                    n_byte_cnt = 32'd0;
                end else begin
                    n_state    = s_wait_num;
                    n_num      = {receive_data, num[31:8]};
                    n_byte_cnt = byte_cnt + 1'b1;
                end 
            end
        end else if (state == s_wait_inst) begin
            if (byte_cnt == num) begin
                n_state     = s_fin;
                Receive_fin = 1'b1;
            end else if (sync_reg[0] == 1'b0) begin
                n_state = s_receive_inst;
                Ready   = 1'b1;
            end 
        end else if (state == s_receive_inst) begin
            if (Rdata_valid) begin
                n_state    = s_wait_inst;
                n_byte_cnt = byte_cnt + 1'b1;
            end
        end else if (state == s_fin) begin
            Receive_fin = 1'b1;
        end
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (~RST_N) begin
            state    <= s_wait_num;
            num      <= 32'd0;
            byte_cnt <= 32'd0;
        end else begin
            state    <= n_state;
            num      <= n_num;
            byte_cnt <= n_byte_cnt;
        end
    end

endmodule
