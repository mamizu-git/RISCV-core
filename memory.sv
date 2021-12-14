module bram_inst (
    input  logic CLK, RST_N,
    input  logic RE_bram, WE_bram,
    input  logic [26:0] read_addr, write_addr, 
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    (* ram_style = "BLOCK" *) reg [31:0] ram [127:0];

    initial begin
        $readmemb("bootloader.mem", ram);
    end

    always_ff @ ( posedge CLK ) begin
        if (~RST_N) begin
            read_data <= 32'd0;
        end else begin
            if (RE_bram) begin
                read_data <= ram[read_addr[8:2]];
            end
            if (WE_bram) begin
                ram[write_addr[8:2]] <= write_data;
            end
        end
    end

endmodule

module memory (
    input  logic CLK, RST_N,
    input  logic Request_valid, RE, WE,
    input  logic [26:0] read_addr, write_addr, 
    input  logic [31:0] write_data,
    output logic Request_completed,
    output logic [31:0] read_data
);

    typedef enum {
        s_ready,
        s_busy
    } state_type; 

    state_type state, n_state;
    logic RE_bram, WE_bram;

    bram_inst bram_inst_instance(.*);

    always_comb begin
        n_state           = state;
        RE_bram           = 1'b0;
        WE_bram           = 1'b0;
        Request_completed = 1'b0;
        if (state == s_ready) begin
            if (Request_valid) begin
                n_state = s_busy;
                RE_bram = RE;
                WE_bram = WE;
            end
        end else if (state == s_busy) begin
            n_state           = s_ready;
            Request_completed = 1'b1;
        end
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            state   <= s_ready;
        end else begin
            state   <= n_state;
        end
    end

endmodule
