module decode (
    input  logic CLK, RST_N,
    input  logic [31:0] inst,
    input  logic Flush, Flush_if, Stall, 

    output logic [4:0] rd_addr_id, rs1_addr, rs2_addr,
    output logic [31:0] imm, 
    output logic inst_lui, inst_auipc, inst_jal, inst_jalr,
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
    output logic Flush_id,

    input  logic [31:0] pc_if, 
    output logic [31:0] pc_id
);

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            Flush_id <= 1'b0;
            pc_id    <= 32'd0;
        end else if (Stall) begin
            Flush_id <= Flush_id;
            pc_id    <= pc_id;
        end else begin
            Flush_id <= (Flush | Flush_if);
            pc_id    <= pc_if;
        end    
    end

    logic r_type, i_type, s_type, b_type, u_type, j_type;

    assign r_type = ((inst[6:5] == 2'b01) ||
                    ( inst[6:5] == 2'b10)) && ( inst[4:2] == 3'b100);
    assign i_type = ((inst[6:5] == 2'b00) && ((inst[4:2] == 3'b000) ||
                                              (inst[4:2] == 3'b001) ||
                                              (inst[4:2] == 3'b011) ||
                                              (inst[4:2] == 3'b100))) ||
                    ((inst[6:5] == 2'b11) && ((inst[4:2] == 3'b001) ||
                                              (inst[4:2] == 3'b100)));
    assign s_type = ( inst[6:5] == 2'b01) && ((inst[4:2] == 3'b000) ||
                                              (inst[4:2] == 3'b001));
    assign b_type = ( inst[6:5] == 2'b11) && ( inst[4:2] == 3'b000);
    assign u_type = ((inst[6:5] == 2'b00) ||
                    ( inst[6:5] == 2'b01)) && (inst[4:2] == 3'b101);
    assign j_type = ( inst[6:5] == 2'b11) && ( inst[4:2] == 3'b011);


    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            imm <= 32'd0;
        end else if (Stall) begin
            imm <= imm;
        end else begin
            imm <= (i_type) ? {{21{inst[31]}}, inst[30:20]} : // sign-extend
                   (s_type) ? {{21{inst[31]}}, inst[30:25], inst[11:7]} :
                   (b_type) ? {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0} :
                   (u_type) ? {inst[31:12], 12'b0000_0000_0000} :
                   (j_type) ? {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0} : 32'd0;
        end
    end  


    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            rd_addr_id  <= 5'd0;
            rs1_addr    <= 5'd0;
            rs2_addr    <= 5'd0;
        end else if (Stall) begin
            rd_addr_id  <= rd_addr_id;
            rs1_addr    <= rs1_addr;
            rs2_addr    <= rs2_addr;
        end else begin
            rd_addr_id  <= (r_type | i_type | u_type | j_type) ? inst[11:7] : 5'd0;
            rs1_addr    <= (r_type | i_type | s_type | b_type) ? inst[19:15] : 5'd0;
            rs2_addr    <= (r_type | s_type | b_type) ? inst[24:20] : 5'd0;
        end
    end


    logic [2:0] funct3;
    logic [6:0] funct7;

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            inst_lui     <= 1'b0;
            inst_auipc   <= 1'b0;
            inst_jal     <= 1'b0;
            inst_jalr    <= 1'b0;
            inst_beq     <= 1'b0;
            inst_bne     <= 1'b0;
            inst_blt     <= 1'b0;
            inst_bge     <= 1'b0;
            inst_bltu    <= 1'b0;
            inst_bgeu    <= 1'b0;
            inst_lw      <= 1'b0;
            inst_sw      <= 1'b0;
            inst_addi    <= 1'b0;
            inst_slti    <= 1'b0;
            inst_sltiu   <= 1'b0;
            inst_xori    <= 1'b0;
            inst_ori     <= 1'b0;
            inst_andi    <= 1'b0;
            inst_slli    <= 1'b0;
            inst_srli    <= 1'b0;
            inst_srai    <= 1'b0;
            inst_add     <= 1'b0;
            inst_sub     <= 1'b0;
            inst_sll     <= 1'b0;
            inst_slt     <= 1'b0;
            inst_sltu    <= 1'b0;
            inst_xor     <= 1'b0;
            inst_srl     <= 1'b0;
            inst_sra     <= 1'b0;
            inst_or      <= 1'b0;
            inst_and     <= 1'b0;
            inst_flw     <= 1'b0;
            inst_fsw     <= 1'b0;
            inst_fadd    <= 1'b0;
            inst_fsub    <= 1'b0;
            inst_fmul    <= 1'b0;
            inst_fdiv    <= 1'b0;
            inst_fsqrt   <= 1'b0;
            inst_ftoi    <= 1'b0;
            inst_itof    <= 1'b0;
            inst_feq     <= 1'b0;
            inst_flt     <= 1'b0;
            inst_fle     <= 1'b0;
            inst_fsgnj   <= 1'b0;
            inst_fsgnjn  <= 1'b0;
            inst_fsgnjx  <= 1'b0;
            inst_fmv_w_x <= 1'b0;
            inst_fmv_x_w <= 1'b0;
        end else if (Stall) begin
            inst_lui     <= inst_lui;
            inst_auipc   <= inst_auipc;
            inst_jal     <= inst_jal;
            inst_jalr    <= inst_jalr;
            inst_beq     <= inst_beq;
            inst_bne     <= inst_bne;
            inst_blt     <= inst_blt;
            inst_bge     <= inst_bge;
            inst_bltu    <= inst_bltu;
            inst_bgeu    <= inst_bgeu;
            inst_lw      <= inst_lw;
            inst_sw      <= inst_sw;
            inst_addi    <= inst_addi;
            inst_slti    <= inst_slti;
            inst_sltiu   <= inst_sltiu;
            inst_xori    <= inst_xori;
            inst_ori     <= inst_ori;
            inst_andi    <= inst_andi;
            inst_slli    <= inst_slli;
            inst_srli    <= inst_srli;
            inst_srai    <= inst_srai;
            inst_add     <= inst_add;
            inst_sub     <= inst_sub;
            inst_sll     <= inst_sll;
            inst_slt     <= inst_slt;
            inst_sltu    <= inst_sltu;
            inst_xor     <= inst_xor;
            inst_srl     <= inst_srl;
            inst_sra     <= inst_sra;
            inst_or      <= inst_or;
            inst_and     <= inst_and;
            inst_flw     <= inst_flw;
            inst_fsw     <= inst_fsw;
            inst_fadd    <= inst_fadd;
            inst_fsub    <= inst_fsub;
            inst_fmul    <= inst_fmul;
            inst_fdiv    <= inst_fdiv;
            inst_fsqrt   <= inst_fsqrt;
            inst_ftoi    <= inst_ftoi;
            inst_itof    <= inst_itof;
            inst_feq     <= inst_feq;
            inst_flt     <= inst_flt;
            inst_fle     <= inst_fle;
            inst_fsgnj   <= inst_fsgnj;
            inst_fsgnjn  <= inst_fsgnjn;
            inst_fsgnjx  <= inst_fsgnjx;
            inst_fmv_w_x <= inst_fmv_w_x;
            inst_fmv_x_w <= inst_fmv_x_w;
        end else begin
            inst_lui     <= (inst[6:0] == 7'b0110111);
            inst_auipc   <= (inst[6:0] == 7'b0010111);
            inst_jal     <= (inst[6:0] == 7'b1101111);
            inst_jalr    <= (inst[6:0] == 7'b1100111) && (funct3 == 3'b000);
            inst_beq     <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b000);
            inst_bne     <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b001);
            inst_blt     <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b100);
            inst_bge     <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b101);
            inst_bltu    <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b110);
            inst_bgeu    <= (inst[6:0] == 7'b1100011) && (funct3 == 3'b111);
            inst_lw      <= (inst[6:0] == 7'b0000011) && (funct3 == 3'b010);
            inst_sw      <= (inst[6:0] == 7'b0100011) && (funct3 == 3'b010);
            inst_addi    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b000);
            inst_slti    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b010);
            inst_sltiu   <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b011);
            inst_xori    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b100);
            inst_ori     <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b110);
            inst_andi    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b111);
            inst_slli    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b001);
            inst_srli    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
            inst_srai    <= (inst[6:0] == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
            inst_add     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
            inst_sub     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
            inst_sll     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b001);
            inst_slt     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b010);
            inst_sltu    <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b011);
            inst_xor     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b100);
            inst_srl     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
            inst_sra     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
            inst_or      <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b110);
            inst_and     <= (inst[6:0] == 7'b0110011) && (funct3 == 3'b111);
            inst_flw     <= (inst[6:0] == 7'b0000111) && (funct3 == 3'b010);
            inst_fsw     <= (inst[6:0] == 7'b0100111) && (funct3 == 3'b010);
            inst_fadd    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
            inst_fsub    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0000100);
            inst_fmul    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0001000);
            inst_fdiv    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0001100);
            inst_fsqrt   <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0101100);
            inst_ftoi    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b1100000);
            inst_itof    <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b1101000);
            inst_feq     <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b010) && (funct7 == 7'b1010000);
            inst_flt     <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b001) && (funct7 == 7'b1010000);
            inst_fle     <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b1010000);
            inst_fsgnj   <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b0010000);
            inst_fsgnjn  <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b001) && (funct7 == 7'b0010000);
            inst_fsgnjx  <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b010) && (funct7 == 7'b0010000);
            inst_fmv_w_x <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b1111000);
            inst_fmv_x_w <= (inst[6:0] == 7'b1010011) && (funct3 == 3'b000) && (funct7 == 7'b1110000);
        end    
    end

endmodule
