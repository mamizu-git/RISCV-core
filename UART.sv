module UART (
    input  logic CLK, RST_N, 
    input  logic rxd, Empty, Full,
    input  logic [7:0] data_out, 

    output logic txd, RE_fifo, WE_fifo,
    output logic [7:0] data_in
);

    localparam WAIT_DIV = 43;

    typedef enum {
        s_send1,
        s_program,
        s_send2,
        s_data,
        s_wait,
        s_send3,
        s_fin
    } state_type;

    state_type state, n_state;

    logic [7:0] send_data, receive_data;
    logic Sdata_valid, Send_fin, Rdata_valid, Receive_fin;

    serial_rx #(WAIT_DIV) serial_rx_instance(.*);
    serial_tx #(WAIT_DIV) serial_tx_instance(.*);

    assign RE_fifo = ~Empty;
    assign WE_fifo = Rdata_valid;
    assign data_in = receive_data;

    always_comb begin
        n_state     = state;
        send_data   = 8'd0;
        Sdata_valid = 1'b0;
        if (state == s_send1) begin 
            if (Send_fin) begin
                n_state = s_program; 
            end
            send_data   = 8'h99;
            Sdata_valid = 1'b1;
        end else if (state == s_program) begin
            if (Receive_fin) begin
                n_state = s_send2;
            end
        end else if (state == s_send2) begin
            if (Send_fin) begin
                n_state = s_data; 
            end
            send_data   = 8'haa;
            Sdata_valid = 1'b1;            
        end else if (state == s_data) begin
            if (Receive_fin) begin
                n_state = s_wait;
            end
        end else if (state == s_wait) begin
            if (RE_fifo) begin
                n_state = s_send3; 
            end
        end else if (state == s_send3) begin
            if (Send_fin) begin
                n_state = s_fin;
            end
            send_data   = data_out;
            Sdata_valid = 1'b1;
        end
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (~RST_N) begin
            state <= s_send1;
        end else begin
            state <= n_state;
        end
    end

endmodule
