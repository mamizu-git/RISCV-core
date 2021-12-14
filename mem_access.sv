module mem_access (
    input  logic CLK, RST_N,
    input  logic RE_mem, WE_mem, Empty, Full, Flush, Stall,
    input  logic [31:0] pc, mem_addr, mem_write_data,
    input  logic [7:0] fifo_data_out,

    output logic RE_fifo, WE_fifo, Stall_mem, Flush_if, 
    output logic [31:0] inst, pc_if, read_data,
    output logic [7:0] fifo_data_in
);

    // 0x000~0x0fc: bootloader, 0x100~0x1fc: inst_mem, 0x200~0x3f8: data_mem, 0x3fc: UART

    memory inst_memory_instance(.*, .read_addr(pc[26:0]), .write_addr(n_addr_in), 
                                .read_data(inst), .write_data(n_write_data), 
                                .RE(RE_inst), .WE(n_WE_inst),
                                .Request_valid(Req_valid_inst), .Request_completed(Req_comp_inst));
    memory data_memory_instance(.*, .read_addr(n_addr_in), .write_addr(n_addr_in), 
                                .read_data(n_mem_rdata), .write_data(n_write_data), 
                                .RE(n_RE_data), .WE(n_WE_data), 
                                .Request_valid(Req_valid_data), .Request_completed(Req_comp_data));

    typedef enum {
        s_idle, 
        s_ready,
        s_wait,
        s_wait_fifo
    } state_type; 

    state_type state_inst, n_state_inst, state_data, n_state_data;

    logic Req_valid_inst, Req_comp_inst, Req_valid_data, Req_comp_data;
    logic RE_inst, WE_inst, n_WE_inst, RE_data, n_RE_data, WE_data, n_WE_data;
    logic Use_fifo, Valid_fifo, n_Valid_fifo, RE_f, n_RE_f, WE_f, n_WE_f;
    logic [26:0] addr_in, n_addr_in;
    logic [31:0] mem_read_data, write_data, n_write_data, n_mem_rdata, mem_rdata;

    assign Stall_mem = (state_inst != s_ready) || (state_data != s_ready);

    always_comb begin
        n_state_inst   = state_inst;
        n_state_data   = state_data;
        Req_valid_inst = 1'b0;
        Req_valid_data = 1'b0;
        RE_fifo        = 1'b0;
        WE_fifo        = 1'b0;
        n_WE_inst      = 1'b0;
        n_RE_data      = 1'b0;
        n_WE_data      = 1'b0;
        n_Valid_fifo   = Valid_fifo;
        n_RE_f         = 1'b0;
        n_WE_f         = 1'b0;
        n_addr_in      = addr_in;
        n_write_data   = write_data;

        if (state_inst == s_idle) begin
            n_state_inst   = s_wait;
            Req_valid_inst = 1'b1; 
        end else if (state_inst == s_ready) begin
            if (~Stall) begin
                n_state_inst   = s_wait;
                Req_valid_inst = 1'b1; 
                n_WE_inst      = WE_mem && (~mem_addr[9]);
                n_addr_in      = {18'd0, mem_addr[8:0]};
                n_write_data   = mem_write_data;
            end
        end else if (state_inst == s_wait) begin
            if (Req_comp_inst) begin
                n_state_inst = s_ready;
            end else begin
                n_WE_inst = WE_inst;
            end
        end
        
        if (state_data == s_idle) begin
            n_state_data = s_ready;
        end else if (state_data == s_ready) begin
            if (~Stall && Use_fifo && (RE_mem || WE_mem)) begin
                n_state_data = s_wait_fifo;
                n_RE_f       = RE_mem;
                n_WE_f       = WE_mem;
                n_write_data = mem_write_data;
            end else if (~Stall && (RE_mem || WE_mem)) begin
                n_state_data   = s_wait;
                Req_valid_data = 1'b1;
                n_RE_data      = RE_mem && (mem_addr[9]);
                n_WE_data      = WE_mem && (mem_addr[9]);
                n_addr_in      = {18'd0, mem_addr[8:0]};
                n_write_data   = mem_write_data;
            end 
        end else if (state_data == s_wait) begin
            if (Req_comp_data) begin
                n_state_data = s_ready;
                n_Valid_fifo = 1'b0;
            end else begin
                n_RE_data = RE_data;
                n_WE_data = WE_data;
            end
        end else if (state_data == s_wait_fifo) begin
            if (~Empty && RE_f) begin
                n_state_data = s_ready;
                n_Valid_fifo = 1'b1;
                RE_fifo      = 1'b1;
            end else if (~Full && WE_f) begin
                n_state_data = s_ready;
                WE_fifo      = 1'b1;
            end else begin
                n_RE_f = RE_f;
                n_WE_f = WE_f;
            end
        end
    end

    assign read_data    = Valid_fifo ? {24'd0, fifo_data_out} : mem_rdata;
    assign RE_inst      = 1'b1;
    assign Use_fifo     = (mem_addr == 32'd1020);
    assign fifo_data_in = write_data[7:0];

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            state_inst <= s_idle;
            state_data <= s_idle;
            pc_if      <= 32'd0;
            addr_in    <= 27'd0;
            write_data <= 32'd0;
            mem_rdata  <= 32'd0;
            Flush_if   <= 1'b0;
            WE_inst    <= 1'b0;
            RE_data    <= 1'b0;
            WE_data    <= 1'b0;
            Valid_fifo <= 1'b0;
            RE_f       <= 1'b0;
            WE_f       <= 1'b0;
        end else begin
            state_inst <= n_state_inst;
            state_data <= n_state_data;
            pc_if      <= (Stall ? pc_if : pc);
            addr_in    <= n_addr_in;
            write_data <= n_write_data;
            mem_rdata  <= n_mem_rdata;
            Flush_if   <= (Stall ? Flush_if : Flush);
            WE_inst    <= n_WE_inst;
            RE_data    <= n_RE_data;
            WE_data    <= n_WE_data;
            Valid_fifo <= n_Valid_fifo;
            RE_f       <= n_RE_f;
            WE_f       <= n_WE_f;
        end
    end
    
endmodule
