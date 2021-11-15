module Solver (
    i_Mat,
    o_X
);

    parameter WORD_LEN = 5;
	parameter NODE_NUM = 3;

    input  [6 * NODE_NUM * 6 * NODE_NUM * WORD_LEN] i_Mat;
    output [6 * NODE_NUM * WORD_LEN] o_X;
    reg [WORD_LEN - 1:0] H_r [0:6 * NODE_NUM] [0:6 * NODE_NUM];
    reg [WORD_LEN - 1:0] H_w [0:6 * NODE_NUM] [0:6 * NODE_NUM];


endmodule