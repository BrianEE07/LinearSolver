`timescale 1 ns/1 ps
`define CYCLE       10.0
`define MAX_CYCLE   10000

`define MAT_DATA "./pattern/matrix_6*6.dat"

module LDLT_tb;

    parameter WORD_LEN = 14;
    parameter NODE_NUM = 1;
    parameter FRACTION = 7;
    parameter MAT_SIZE = 6 * NODE_NUM * 6 * NODE_NUM;
    parameter L_SIZE   = (MAT_SIZE + 6 * NODE_NUM) / 2;
    integer i, j;

    reg clk, rst_n;
    reg i_start;
    reg signed [WORD_LEN - 1:0] i_Mat [0:MAT_SIZE - 1];
    reg [MAT_SIZE * WORD_LEN - 1:0] i_Mat_flat;
    wire o_valid;
    wire [L_SIZE * WORD_LEN - 1:0] o_L;
    
    LDLT u0 (
        .clk(clk),
        .rst_n(rst_n),
        .i_start(i_start),
        .i_Mat_flat(i_Mat_flat),
        .o_valid(o_valid),
        .o_L(o_L)
    );

    always #(`CYCLE * 0.5) clk = ~clk;

    initial begin
        $fsdbDumpfile("LDLT_tb.fsdb");
        $fsdbDumpvars(0, LDLT_tb, "+mda");
    end
        
    initial begin
        $readmemb(`MAT_DATA, i_Mat);
    end

    initial begin
        clk   = 0;
        rst_n = 1;
        i_start = 0;
        #(`CYCLE * 0.5) rst_n = 0;
        #(`CYCLE * 2.0) rst_n = 1;
        for (i = 0;i < 6 * NODE_NUM;i = i + 1) begin
            for (j = 0;j < 6 * NODE_NUM;j = j + 1) begin
                i_Mat_flat[(6 * NODE_NUM * i + j) * WORD_LEN +: WORD_LEN] = i_Mat[6 * NODE_NUM * i + j];
            end
        end
        #(`CYCLE * 0.5) i_start = 1;
    end

    initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("-------------------- FINISH --------------------");
        $finish;
    end

endmodule




