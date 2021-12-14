module wrapper_uart (
    input  wire CLK, RST_N, 
    input  wire rxd, Empty, Full,
    input  wire [7:0] data_out, 
    // input  wire Finish_wb,
    output wire txd, RE_fifo, WE_fifo,
    output wire [7:0] data_in
);

    UART uart_instance(.CLK(CLK), .RST_N(RST_N), .rxd(rxd), .txd(txd), .Empty(Empty), .Full(Full), .data_out(data_out), 
                       .RE_fifo(RE_fifo), .WE_fifo(WE_fifo), .data_in(data_in));

endmodule
