module execute (
    input  logic CLK, RST_N,
    input  logic [31:0] op1, op2, imm, pc_id,
    input  logic inst_lui, inst_auipc, inst_jal, inst_jalr,
                 inst_beq, inst_bne, inst_blt, inst_bge, inst_bltu, inst_bgeu,
                 inst_lw, inst_sw,
                 inst_addi, inst_slti, inst_sltiu, inst_xori, inst_ori, inst_andi, 
                 inst_slli, inst_srli, inst_srai,
                 inst_add, inst_sub, inst_sll, inst_slt, inst_sltu, 
                 inst_xor, inst_srl, inst_sra, inst_or, inst_and,
                 inst_flw, inst_fsw,
                 inst_fadd, inst_fsub, inst_fmul, inst_fdiv, inst_fsqrt,
                 inst_ftoi, inst_itof,
                 inst_feq, inst_flt, inst_fle,
                 inst_fsgnj, inst_fsgnjn, inst_fsgnjx,
                 inst_fmv_w_x, inst_fmv_x_w,
    input  logic Flush_id, Stall,

    output logic Load_ex, F_inst_ex, RE_mem, WE_mem, WE_reg, WE_freg, Flush,
    output logic [31:0] exe_result_ex, n_pc, mem_addr,

    input  logic [4:0] rd_addr_id,
    output logic [4:0] rd_addr_ex,
    output logic [31:0] op2_ex,
    output logic Flush_ex
);

    logic [31:0] alu_op2, alu_result;
    logic alu_flush;

    // use immidiate or op2
    assign alu_op2 = (inst_lui | inst_auipc | inst_jal | inst_jalr | 
                      inst_lw | inst_sw | inst_flw | inst_fsw | 
                      inst_addi | inst_slti | inst_sltiu | 
                      inst_xori | inst_ori | inst_andi | 
                      inst_slli | inst_srli | inst_srai) ? imm : op2;

    ALU alu_instance(.*);

    assign n_pc  = alu_result;
    assign Flush = (~Stall) && (alu_flush) && (~Flush_id);

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            Flush_ex <= 1'b0;
        end else if (Stall) begin
            Flush_ex <= Flush_ex;
        end else begin
            Flush_ex <= Flush_id;
        end
    end

    assign mem_addr = alu_result;
    assign RE_mem   = (Flush_id) ? 1'b0 : (inst_lw | inst_flw);
    assign WE_mem   = (Flush_id) ? 1'b0 : (inst_sw | inst_fsw);

    logic n_WE_reg, n_WE_freg;

    always_comb begin
        n_WE_reg  = WE_reg;
        n_WE_freg = WE_freg;
        if (Flush_id) begin
            n_WE_reg  = 1'b0;
            n_WE_freg = 1'b0;
        end else if (inst_lui | inst_auipc | 
                     inst_addi | inst_slti | inst_sltiu | 
                     inst_xori | inst_ori | inst_andi | 
                     inst_slli | inst_srli | inst_srai |
                     inst_add | inst_sub | inst_sll | inst_slt | inst_sltu | 
                     inst_xor | inst_srl | inst_sra | inst_or | inst_and |
                     inst_jal | inst_jalr | inst_lw |
                     inst_ftoi | inst_feq | inst_flt | inst_fle | inst_fmv_x_w) 
        begin
            n_WE_reg  = 1'b1;
            n_WE_freg = 1'b0;
        end else if (inst_flw | inst_fadd | inst_fsub | inst_fmul | inst_fdiv | inst_fsqrt |
                     inst_itof | inst_fsgnj | inst_fsgnjn | inst_fsgnjx | inst_fmv_w_x)
        begin
            n_WE_reg  = 1'b0;
            n_WE_freg = 1'b1;
        end else if (inst_beq | inst_bne | inst_blt |
                     inst_bge | inst_bltu | inst_bgeu |
                     inst_sw | inst_fsw)  
        begin
            n_WE_reg  = 1'b0;    
            n_WE_freg = 1'b0;
        end
    end
    
    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            Load_ex       <= 1'b0;
            F_inst_ex     <= 1'b0;
            WE_reg        <= 1'b0;
            WE_freg       <= 1'b0;
            rd_addr_ex    <= 5'd0;
            exe_result_ex <= 32'd0;
            op2_ex        <= 32'd0;
        end else if (Stall) begin
            Load_ex       <= Load_ex;
            F_inst_ex     <= F_inst_ex;
            WE_reg        <= WE_reg;
            WE_freg       <= WE_freg;
            rd_addr_ex    <= rd_addr_ex;
            exe_result_ex <= exe_result_ex;
            op2_ex        <= op2_ex;
        end else begin
            if (inst_lui | inst_auipc | 
                inst_addi | inst_slti | inst_sltiu | 
                inst_xori | inst_ori | inst_andi | 
                inst_slli | inst_srli | inst_srai |
                inst_add | inst_sub | inst_sll | inst_slt | inst_sltu | 
                inst_xor | inst_srl | inst_sra | inst_or | inst_and | inst_sw) 
            begin
                Load_ex       <= 1'b0;
                F_inst_ex     <= 1'b0;
                WE_reg        <= n_WE_reg;
                WE_freg       <= n_WE_freg;
                rd_addr_ex    <= rd_addr_id;
                exe_result_ex <= alu_result;
                op2_ex        <= op2;
            end else if (inst_jal | inst_jalr) begin
                Load_ex       <= 1'b0;
                F_inst_ex     <= 1'b0;
                WE_reg        <= n_WE_reg;
                WE_freg       <= n_WE_freg;
                rd_addr_ex    <= rd_addr_id;
                exe_result_ex <= pc_id + 32'd4;
                op2_ex        <= op2;
            end else if (inst_beq | inst_bne | inst_blt |
                         inst_bge | inst_bltu | inst_bgeu) 
            begin
                Load_ex       <= 1'b0;
                F_inst_ex     <= 1'b0;
                WE_reg        <= n_WE_reg;
                WE_freg       <= n_WE_freg;
                rd_addr_ex    <= rd_addr_id;
                exe_result_ex <= 32'd0;
                op2_ex        <= op2;
            end else if (inst_fsw | inst_fadd | inst_fsub | inst_fmul | inst_fdiv | inst_fsqrt |
                         inst_ftoi | inst_itof |
                         inst_feq | inst_flt | inst_fle |
                         inst_fsgnj | inst_fsgnjn | inst_fsgnjx |
                         inst_fmv_w_x | inst_fmv_x_w) 
            begin
                Load_ex       <= 1'b0;
                F_inst_ex     <= 1'b1;
                WE_reg        <= n_WE_reg;
                WE_freg       <= n_WE_freg;
                rd_addr_ex    <= rd_addr_id;
                exe_result_ex <= alu_result;
                op2_ex        <= op2;
            end else if (inst_lw | inst_flw) begin
                Load_ex       <= 1'b1;
                F_inst_ex     <= 1'b0;
                WE_reg        <= n_WE_reg;
                WE_freg       <= n_WE_freg;
                rd_addr_ex    <= rd_addr_id;
                exe_result_ex <= alu_result;
                op2_ex        <= op2;
            end
        end
    end

endmodule
