module LDLT #(
	parameter DATA_LEN = 34,
	parameter NODE_NUM = 100,
	parameter FRACTION = 16
)(
    clk,
    rst_n,
    i_start,
    i_data,
    o_ready,
    o_valid,
    o_data
);

    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam PROC = 2'b10;
    localparam WRTE = 2'b11;

    integer i, j;

    input                   clk, rst_n;
    input                   i_start;
    input  [DATA_LEN - 1:0] i_data;
    output                  o_ready;
    output                  o_valid;
    output [DATA_LEN - 1:0] o_data;

    reg [1:0]             state_r, state_w;
    reg                   o_valid_r, o_valid_w;
    reg                   o_ready_r, o_ready_w;
    reg [DATA_LEN - 1:0]  o_data_r, o_data_w;

    reg [9:0] i_r, i_w; // cycle count i 
    reg [9:0] j_r, j_w; // cycle count j
    reg [9:0] k_r, k_w; // cycle count k

    reg signed [DATA_LEN - 1:0]     Mat_r [0:6 * NODE_NUM - 1] [0:6 * NODE_NUM - 1];
    reg signed [2 * DATA_LEN - 1:0] Mat_w [0:6 * NODE_NUM - 1] [0:6 * NODE_NUM - 1];
    
    reg signed [DATA_LEN + FRACTION - 1:0] quotient;
    reg signed [DATA_LEN + FRACTION - 1:0] mul1;
    reg signed [DATA_LEN + FRACTION - 1:0] mul2;
    reg signed [DATA_LEN + FRACTION - 1:0] tmp;

    assign o_ready = o_ready_r;
    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    // FSM
    always @(*) begin
        case (state_r)
            IDLE: begin
                if (i_start) state_w = READ;
                else         state_w = IDLE;
            end
            READ: begin
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) state_w = PROC;
                else                                                    state_w = READ;
            end
            PROC: begin
                if (i_r == 6 * NODE_NUM - 1 && j_r == i_r - 1 && k_r == j_r - 1) state_w = WRTE;
                else                                                             state_w = PROC;
            end
            WRTE: begin
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) state_w = IDLE;
                else                                                    state_w = WRTE;
            end
            default: state_w = state_r;
        endcase
    end

    // Combinational
    always @(*) begin
        i_w = i_r;
        j_w = j_r;
        k_w = k_r;
        o_data_w = 0;
        o_ready_w = 0;
        o_valid_w = 0;
        for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
            for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                Mat_w[i][j] = Mat_r[i][j];
            end
        end
        case (state_r)
            IDLE: begin
                if (i_start)
                    o_ready_w = 1;
                else
                    o_ready_w = 0;
            end
            READ: begin
                o_ready_w       = ~(j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1);
                Mat_w[i_r][j_r] = i_data;
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) begin
                    j_w = 0;
                    i_w = 0;
                end
                else begin
                    if (i_r == 6 * NODE_NUM - 1) begin
                        j_w = j_r + 1;
                        i_w = j_r + 1;
                    end
                    else begin
                        i_w = i_r + 1;
                    end
                end
            end
            PROC: begin
                mul1 = (Mat_r[i_r][k_r] * Mat_r[k_r][k_r]) >>> FRACTION;
                mul2 = (mul1            * Mat_r[j_r][k_r]) >>> FRACTION;
                if (i_r != 0 && j_r == 0) begin
                    Mat_w[i_r][j_r] = (Mat_r[i_r][j_r] << FRACTION) / Mat_r[j_r][j_r];
                    Mat_w[i_r][i_r] = Mat_r[i_r][i_r] - (Mat_r[i_r][j_r] * Mat_r[i_r][j_r]) / Mat_r[j_r][j_r];
                end
                else if (i_r != 0) begin
                    if (k_r != j_r - 1) begin
                        Mat_w[i_r][j_r] = Mat_r[i_r][j_r] - mul2;
                    end
                    else begin
                        Mat_w[i_r][j_r] = ((Mat_r[i_r][j_r] - mul2) << FRACTION) / Mat_r[j_r][j_r];
                        Mat_w[i_r][i_r] = Mat_r[i_r][i_r] - ((Mat_r[i_r][j_r] - mul2) * (Mat_r[i_r][j_r] - mul2)) / Mat_r[j_r][j_r];
                    end
                end
                if (i_r == 6 * NODE_NUM - 1 && j_r == i_r - 1 && k_r == j_r - 1) begin
                    i_w = 0;
                    j_w = 0;
                    k_w = 0;
                end
                else if (i_r == 0) begin
                    i_w = i_r + 1;
                end
                else begin
                    if (j_r == i_r - 1 && (j_r == 0 || k_r == j_r - 1)) begin
                        i_w = i_r + 1;
                        j_w = 0;
                        k_w = 0;
                    end
                    else if (j_r == 0) begin
                        j_w = j_r + 1;
                    end
                    else begin
                        if (k_r == j_r - 1) begin
                            j_w = j_r + 1;
                            k_w = 0;
                        end
                        else begin
                            k_w = k_r + 1;
                        end
                    end
                end
            end
            WRTE: begin
                o_valid_w = 1;
                o_data_w = Mat_r[i_r][j_r];
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) begin
                    j_w = 0;
                    i_w = 0;
                end
                else begin
                    if (i_r == 6 * NODE_NUM - 1) begin
                        j_w = j_r + 1;
                        i_w = j_r + 1;
                    end
                    else begin
                        i_w = i_r + 1;
                    end
                end
            end
            default: ;
        endcase
    end


    // Sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= IDLE;
            o_data_r <= 0;
            o_ready_r <= 0;
            o_valid_r <= 0;
            i_r <= 0;
            j_r <= 0;
            k_r <= 0;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_r[i][j] <= 0;
                end
            end
        end
        else begin
            state_r <= state_w;
            o_data_r <= o_data_w;
            o_valid_r <= o_valid_w;
            o_ready_r <= o_ready_w;
            i_r <= i_w;
            j_r <= j_w;
            k_r <= k_w;
            for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
                for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                    Mat_r[i][j] <= Mat_w[i][j];
                end
            end
        end
    end

endmodule