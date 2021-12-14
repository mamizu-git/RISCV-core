module wrapper_core (
    input  wire CLK, RST_N,
    input  wire Empty, Full,
    input  wire [7:0] fifo_data_out,
    output wire RE_fifo, WE_fifo,
    output wire [7:0] fifo_data_in 
);

    core core_instance(.CLK(CLK), .RST_N(RST_N), 
                       .Empty(Empty), .Full(Full),
                       .fifo_data_out(fifo_data_out),
                       .RE_fifo(RE_fifo), .WE_fifo(WE_fifo), .fifo_data_in(fifo_data_in));

endmodule
