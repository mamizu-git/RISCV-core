module core (
    input  logic CLK, RST_N,
    input  logic Empty, Full,
    input  logic [7:0] fifo_data_out,

    output logic RE_fifo, WE_fifo,
    output logic [7:0] fifo_data_in
);

    logic [1:0] Fowarding_i, Fowarding_f;
    logic Flush, Stall, Finish;

    assign Stall = (Stall_fpu) || (Stall_mem);

    logic [31:0] pc;

    logic [31:0] inst, pc_if;
    logic Flush_if;

    logic [4:0] rd_addr_id, rs1_addr, rs2_addr;
    logic [31:0] rs1_data, rs2_data, frs1_data, frs2_data, imm, pc_id;
    logic inst_lui, inst_auipc, inst_jal, inst_jalr,
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
          inst_fmv_w_x, inst_fmv_x_w; 
    logic Flush_id;

    assign Fowarding_i[0] = (WE_reg) && (!Flush_ex) && (rs1_addr == rd_addr_ex);
    assign Fowarding_i[1] = (WE_reg) && (!Flush_ex) && (rs2_addr == rd_addr_ex);
    assign Fowarding_f[0] = (WE_freg) && (!Flush_ex) && (rs1_addr == rd_addr_ex);
    assign Fowarding_f[1] = (WE_freg) && (!Flush_ex) && (rs2_addr == rd_addr_ex);

    logic [31:0] op1, op2;

    assign op1 = (inst_fadd | inst_fsub | inst_fmul | inst_fdiv | inst_fsqrt |
                  inst_ftoi | inst_feq | inst_flt | inst_fle |
                  inst_fsgnj | inst_fsgnjn | inst_fsgnjx | inst_fmv_x_w) ? 
                  (Fowarding_f[0] ? reg_write_data : frs1_data) : 
                  (Fowarding_i[0] ? reg_write_data : rs1_data);

    assign op2 = (inst_fsw | inst_fadd | inst_fsub | inst_fmul | inst_fdiv | 
                  inst_feq | inst_flt | inst_fle |
                  inst_fsgnj | inst_fsgnjn | inst_fsgnjx) ? 
                  (Fowarding_f[1] ? reg_write_data : frs2_data) : 
                  (Fowarding_i[1] ? reg_write_data : rs2_data);

    logic [31:0] fpu_result;
    logic Stall_fpu;

    FPU fpu_instance(.*, .clk(CLK), .rstn(RST_N), .x1(op1), .x2(op2));
    
    logic Load_ex, F_inst_ex, RE_mem, WE_mem, WE_reg, WE_freg;
    logic [4:0] rd_addr_ex; 
    logic [31:0] exe_result_ex, op2_ex;
    logic [31:0] n_pc; 
    logic Flush_ex, Stall_mem;

    logic [31:0] mem_addr, mem_read_data, reg_write_data, inst_num;

    assign reg_write_data = Load_ex ? mem_read_data : 
                            F_inst_ex ? fpu_result : exe_result_ex;
    
    assign Finish = (inst_num == 32'd0) ? 1'b0 : (pc == {24'd1, inst_num[7:0]});

    decode decode_instance(.*);
    reg_access reg_access_instance(.*);
    execute execute_instance(.*);
    mem_access mem_access_instance(.*, .read_data(mem_read_data), .mem_write_data(op2));

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            pc <= 32'd0;
        end else if (Stall | Finish) begin
            pc <= pc;
        end else if (Flush) begin
            pc <= n_pc;
        end else begin
            pc <= pc + 32'd4;
        end
    end

endmodule
