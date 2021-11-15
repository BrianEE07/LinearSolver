module LDLT (
    clk,
    rst_n,
    i_start,
    i_Mat_flat,
    o_valid,
    o_L
    );

    parameter WORD_LEN = 14;
    parameter NODE_NUM = 1;
    parameter FRACTION = 7;
    parameter MAT_SIZE = 6 * NODE_NUM * 6 * NODE_NUM;
    parameter L_SIZE   = (MAT_SIZE + 6 * NODE_NUM) / 2;
    localparam IDLE = 1'b0 , BUSY = 1'b1;
    integer i, j;

    input clk, rst_n;
    input i_start;
    input [MAT_SIZE * WORD_LEN - 1:0] i_Mat_flat; // too large
    output o_valid;
    output [L_SIZE * WORD_LEN - 1:0] o_L;

    wire valid;
    reg state_r, state_w;

    reg [9:0] cnt_i_r, cnt_i_w; // cycle count i 
    reg [9:0] cnt_j_r, cnt_j_w; // cycle count j
    reg [9:0] cnt_k_r, cnt_k_w; // cycle count k

    reg signed [WORD_LEN - 1:0]     Mat_r [0:6 * NODE_NUM - 1] [0:6 * NODE_NUM - 1];
    reg signed [2 * WORD_LEN - 1:0] Mat_w [0:6 * NODE_NUM - 1] [0:6 * NODE_NUM - 1];
    
    reg signed [WORD_LEN + FRACTION - 1:0] quotient;
    reg signed [WORD_LEN + FRACTION - 1:0] mul1;
    reg signed [WORD_LEN + FRACTION - 1:0] mul2;

    assign valid = (cnt_i_r == 6 * NODE_NUM);

    assign o_valid = valid;
    assign o_L     = 0;

    // FSM
    always @(*) begin
        case (state_r)
            IDLE: begin
               if (i_start) begin
                   state_w = BUSY;
               end
               else begin
                   state_w = IDLE;
               end
            end
            BUSY: begin
                if (valid) begin
                    state_w = IDLE;
                end
                else begin
                    state_w = BUSY;
                end
            end
            default: state_w = IDLE;
        endcase
    end

    // Combinational
    always @(*) begin
        if (state_r == IDLE) begin
            cnt_i_w = 0;
            cnt_j_w = 0;
            cnt_k_w = 0;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_w[i][j] = i_Mat_flat[(6 * NODE_NUM * i + j) * WORD_LEN +: WORD_LEN];
                end
            end
        end
        else begin
            cnt_i_w = cnt_i_r;
            cnt_j_w = cnt_j_r;
            cnt_k_w = cnt_k_r;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_w[i][j] = Mat_r[i][j];
                end
            end
            if (cnt_i_r < 6 * NODE_NUM) begin
                if (cnt_j_r < cnt_i_r) begin
                    if (cnt_k_r < cnt_j_r) begin
                        cnt_k_w = cnt_k_r + 1;
                        mul1 = (Mat_r[cnt_i_r][cnt_k_r] * Mat_r[cnt_k_r][cnt_k_r]) >>> FRACTION;
                        mul2 = mul1 * Mat_r[cnt_j_r][cnt_k_r] >>> FRACTION;
                        Mat_w[cnt_i_r][cnt_j_r] = Mat_r[cnt_i_r][cnt_j_r] - mul2;
                    end
                    else begin
                        cnt_k_w = 0;
                        cnt_j_w = cnt_j_r + 1;
                        quotient = (Mat_r[cnt_i_r][cnt_j_r] << FRACTION) / Mat_r[cnt_j_r][cnt_j_r];
                        Mat_w[cnt_i_r][cnt_j_r] = quotient;
                        Mat_w[cnt_i_r][cnt_i_r] = Mat_r[cnt_i_r][cnt_i_r] - (Mat_r[cnt_i_r][cnt_j_r] * Mat_r[cnt_i_r][cnt_j_r]) / Mat_r[cnt_j_r][cnt_j_r];
                    end
                end
                else begin
                    cnt_j_w = 0;
                    cnt_i_w = cnt_i_r + 1;
                end
            end
            else begin
                cnt_i_w = 0;
            end
        end
    end


    // Sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= IDLE;
            cnt_i_r <= 0;
            cnt_j_r <= 0;
            cnt_k_r <= 0;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_r[i][j] <= 0;
                end
            end
        end
        else begin
            state_r <= state_w;
            cnt_i_r <= cnt_i_w;
            cnt_j_r <= cnt_j_w;
            cnt_k_r <= cnt_k_w;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_r[i][j] <= Mat_w[i][j];
                end
            end
        end
    end

endmodule