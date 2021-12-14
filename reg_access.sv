module reg_access (
    input  logic CLK, RST_N, 
    input  logic [4:0] rs1_addr, rs2_addr, rd_addr_ex, 
    input  logic WE_reg, WE_freg, Stall, 
    input  logic [31:0] reg_write_data, 

    output logic [31:0] rs1_data, rs2_data, frs1_data, frs2_data, inst_num
);

    logic [31:0] regfile[32];
    logic [31:0] fregfile[32];

    always_comb begin
        rs1_data  = regfile[rs1_addr];
        rs2_data  = regfile[rs2_addr];
        frs1_data = fregfile[rs1_addr];
        frs2_data = fregfile[rs2_addr];
        inst_num  = regfile[3];
    end

    always_ff @( posedge CLK or negedge RST_N ) begin
        if (RST_N == 1'b0) begin
            regfile  <= '{default : 32'd0, 2 : 32'd1016}; //
            fregfile <= '{default : 32'd0};
        end else begin
            if (WE_reg && rd_addr_ex != 5'd0 && ~Stall) begin // zero-register
                regfile[rd_addr_ex] <= reg_write_data;
            end else if (WE_freg && ~Stall) begin
                fregfile[rd_addr_ex] <= reg_write_data;
            end
        end
    end
    
endmodule
