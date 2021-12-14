module ALU (
    input  logic [31:0] op1, alu_op2, imm, pc_id,
    input  logic inst_lui, inst_auipc, inst_jal, inst_jalr,
                 inst_beq, inst_bne, inst_blt, inst_bge, inst_bltu, inst_bgeu,
                 inst_lw, inst_sw,
                 inst_addi, inst_slti, inst_sltiu, inst_xori, inst_ori, inst_andi, 
                 inst_slli, inst_srli, inst_srai,
                 inst_add, inst_sub, inst_sll, inst_slt, inst_sltu, 
                 inst_xor, inst_srl, inst_sra, inst_or, inst_and,
                 inst_flw, inst_fsw,

    output logic [31:0] alu_result,
    output logic alu_flush
);

    logic [31:0] alu_lui, alu_auipc, alu_jalr_s, alu_jalr;
    logic [31:0] alu_add_sub, alu_shl, alu_shr, alu_xor, alu_or, alu_and;
    logic [32:0] alu_shr_s;
    logic alu_eq, alu_lts, alu_ltu;
    logic [31:0] alu_beq, alu_bne, alu_blt, alu_bge, alu_bltu, alu_bgeu;

    always_comb begin
        alu_lui     = alu_op2;
        alu_auipc   = pc_id + alu_op2;
        alu_jalr_s  = op1 + alu_op2;
        alu_jalr    = {alu_jalr_s[31:1], 1'b0};
        alu_add_sub = (inst_sub) ? (op1 - alu_op2) : (op1 + alu_op2);
        alu_shl     = op1 << alu_op2[4:0];
        alu_shr_s   = $signed({(inst_sra | inst_srai) ? op1[31] : 1'b0, op1}) >>> alu_op2[4:0];
        alu_shr     = alu_shr_s[31:0];
        alu_xor     = op1 ^ alu_op2;
        alu_or      = op1 | alu_op2;
        alu_and     = op1 & alu_op2;
        alu_eq      = (op1 == alu_op2);
        alu_lts     = ($signed(op1) < $signed(alu_op2));
        alu_ltu     = (op1 < alu_op2);
        alu_beq     = (alu_eq) ? (pc_id + imm) : pc_id + 32'd4; // pc + 4 いらない！
        alu_bne     = !(alu_eq) ? (pc_id + imm) : pc_id + 32'd4;
        alu_blt     = (alu_lts) ? (pc_id + imm) : pc_id + 32'd4;
        alu_bge     = !(alu_lts) ? (pc_id + imm) : pc_id + 32'd4;
        alu_bltu    = (alu_ltu) ? (pc_id + imm) : pc_id + 32'd4;
        alu_bgeu    = !(alu_ltu) ? (pc_id + imm) : pc_id + 32'd4;

        alu_result  = (inst_lui) ? alu_lui :
                      (inst_auipc | inst_jal) ? alu_auipc :
                      (inst_jalr) ? alu_jalr :
                      (inst_addi | inst_add | inst_sub |
                       inst_lw | inst_sw | inst_flw | inst_fsw) ? alu_add_sub :
                      (inst_slti | inst_slt) ? {31'd0, alu_lts} :
                      (inst_sltiu | inst_sltu) ? {31'd0, alu_ltu} :
                      (inst_slli | inst_sll) ? alu_shl :
                      (inst_srli | inst_srai | inst_srl | inst_sra) ? alu_shr :
                      (inst_xori | inst_xor) ? alu_xor :
                      (inst_ori | inst_or) ? alu_or :
                      (inst_andi | inst_and) ? alu_and :
                      (inst_beq) ? alu_beq :
                      (inst_bne) ? alu_bne :
                      (inst_blt) ? alu_blt :
                      (inst_bge) ? alu_bge :
                      (inst_bltu) ? alu_bltu :
                      (inst_bgeu) ? alu_bgeu : 32'd0;

        alu_flush   = (inst_jal | inst_jalr) ? 1'b1 :
                      (inst_beq) ? alu_eq :
                      (inst_bne) ? !alu_eq :
                      (inst_blt) ? alu_lts :
                      (inst_bge) ? !alu_lts :
                      (inst_bltu) ? alu_ltu :
                      (inst_bgeu) ? !alu_ltu : 1'b0;
    end

endmodule
