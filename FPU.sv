module FPU (
    input  logic clk, rstn,
    input  logic [31:0] x1, x2,
    input  logic Stall, 
    input  logic inst_fadd, inst_fsub, inst_fmul, inst_fdiv, inst_fsqrt,
                 inst_ftoi, inst_itof,
                 inst_feq, inst_flt, inst_fle,
                 inst_fsgnj, inst_fsgnjn, inst_fsgnjx,
                 inst_fmv_w_x, inst_fmv_x_w,
    output logic [31:0] fpu_result,
    output logic Stall_fpu
);

    typedef enum {
        s_ready,
        s_busy
    } state_type;

    state_type state, n_state;

    logic [31:0] fadd, fsub, fmul, fdiv, fsqrt, ftoi, itof, feq, flt, fle, fsgnj, fsgnjn, fsgnjx, fmv_w_x, fmv_x_w;

    logic use_fadd, use_fsub, use_fmul, use_fdiv, use_fsqrt,
          use_ftoi, use_itof,
          use_feq, use_flt, use_fle,
          use_fsgnj, use_fsgnjn, use_fsgnjx,
          use_fmv_w_x, use_fmv_x_w;

    logic [1:0] cnt, n_cnt, cycle_num;

    assign cycle_num = (inst_fdiv | inst_fsqrt) ? 2'd2 : 2'd1;
    assign Stall_fpu = (cycle_num - 2'd1 != cnt);

    always_comb begin
        n_state = state;
        n_cnt   = cnt;
        if (state == s_ready) begin
            if (Stall_fpu) begin
                n_state = s_busy;
                n_cnt   = cnt + 2'd1;
            end
        end else if (state == s_busy) begin
            if (Stall_fpu) begin
                n_cnt = cnt + 2'd1;
            end else begin
                if (~Stall) begin
                    n_state = s_ready;
                    n_cnt   = 2'd0;
                end
            end
        end
    end

    fadd fadd_instance(.*, .y(fadd));
    fsub fsub_instance(.*, .y(fsub));
    fmul fmul_instance(.*, .y(fmul));
    fdiv fdiv_instance(.*, .y(fdiv));
    fsqrt fsqrt_instance(.*, .y(fsqrt));
    ftoi ftoi_instance(.*, .y(ftoi));
    itof itof_instance(.*, .y(itof));
    feq feq_instance(.*, .y(feq));
    flt flt_instance(.*, .y(flt));
    fle fle_instance(.*, .y(fle));
    fsgnj fsgnj_instance(.*, .y(fsgnj));
    fsgnjn fsgnjn_instance(.*, .y(fsgnjn));
    fsgnjx fsgnjx_instance(.*, .y(fsgnjx));
    fmv_w_x fmv_w_x_instance(.*, .y(fmv_w_x));
    fmv_x_w fmv_x_w_instance(.*, .y(fmv_x_w));


    assign fpu_result = (use_fadd) ? fadd :
                        (use_fsub) ? fsub :
                        (use_fmul) ? fmul :
                        (use_fdiv) ? fdiv :
                        (use_fsqrt) ? fsqrt :
                        (use_ftoi) ? ftoi :
                        (use_itof) ? itof :
                        (use_feq) ? feq :
                        (use_flt) ? flt :
                        (use_fle) ? fle :
                        (use_fsgnj) ? fsgnj :
                        (use_fsgnjn) ? fsgnjn :
                        (use_fsgnjx) ? fsgnjx :
                        (use_fmv_w_x) ? fmv_w_x :
                        (use_fmv_x_w) ? fmv_x_w : 32'd0;

    always_ff @( posedge clk or negedge rstn ) begin
        if (rstn == 1'b0) begin
            state       <= s_ready;
            cnt         <= 2'd0;
            use_fadd    <= 1'b0;
            use_fsub    <= 1'b0;
            use_fmul    <= 1'b0;
            use_fdiv    <= 1'b0;
            use_fsqrt   <= 1'b0;
            use_ftoi    <= 1'b0;
            use_itof    <= 1'b0;
            use_feq     <= 1'b0;
            use_flt     <= 1'b0;
            use_fle     <= 1'b0;
            use_fsgnj   <= 1'b0;
            use_fsgnjn  <= 1'b0;
            use_fsgnjx  <= 1'b0;
            use_fmv_w_x <= 1'b0;
            use_fmv_x_w <= 1'b0;
        end else if (Stall) begin
            state       <= n_state;
            cnt         <= n_cnt;
            use_fadd    <= use_fadd;
            use_fsub    <= use_fsub;
            use_fmul    <= use_fmul;
            use_fdiv    <= use_fdiv;
            use_fsqrt   <= use_fsqrt;
            use_ftoi    <= use_ftoi;
            use_itof    <= use_itof;
            use_feq     <= use_feq;
            use_flt     <= use_flt;
            use_fle     <= use_fle;
            use_fsgnj   <= use_fsgnj;
            use_fsgnjn  <= use_fsgnjn;
            use_fsgnjx  <= use_fsgnjx;
            use_fmv_w_x <= use_fmv_w_x;
            use_fmv_x_w <= use_fmv_x_w;
        end else begin
            state       <= n_state;
            cnt         <= n_cnt;
            use_fadd    <= inst_fadd;
            use_fsub    <= inst_fsub;
            use_fmul    <= inst_fmul;
            use_fdiv    <= inst_fdiv;
            use_fsqrt   <= inst_fsqrt;
            use_ftoi    <= inst_ftoi;
            use_itof    <= inst_itof;
            use_feq     <= inst_feq;
            use_flt     <= inst_flt;
            use_fle     <= inst_fle;
            use_fsgnj   <= inst_fsgnj;
            use_fsgnjn  <= inst_fsgnjn;
            use_fsgnjx  <= inst_fsgnjx;
            use_fmv_w_x <= inst_fmv_w_x;
            use_fmv_x_w <= inst_fmv_x_w;
        end
    end

endmodule
