// behavioral
module sram_1024x32 (
    Q,
    CLK,
    CEN,
    WEN,
    A,
    D
);

    parameter BITS       = 32;
    // parameter WORD_DEPTH = 1024;
    // parameter ADDR_WIDTH = 10;
    parameter WORD_DEPTH = 128;
    parameter ADDR_WIDTH = 7;
    integer i;

    input                     CLK;
    input                     CEN; // CEN 0:w/r | 1:standby
    input                     WEN; // WEN 0:write | 1:read
    input  [ADDR_WIDTH - 1:0] A;
    input  [BITS - 1:0]       D;

    output [BITS - 1:0]       Q;

    reg [BITS - 1:0] Q_r, Q_w;

    reg [BITS - 1:0] mem_r [0:WORD_DEPTH - 1];
    reg [BITS - 1:0] mem_w [0:WORD_DEPTH - 1];

    assign Q = Q_r;

    always @(*) begin
        Q_w = Q_r;
        for (i = 0;i < WORD_DEPTH;i = i + 1) begin
            mem_w[i] = mem_r[i];
        end
        if (~CEN) begin
            Q_w      = (~WEN) ? D : mem_r[A];
            mem_w[A] = (~WEN) ? D : mem_r[A];
        end
    end

    always @(posedge CLK) begin
        Q_r <= Q_w;
        for (i = 0;i < WORD_DEPTH;i = i + 1) begin
            mem_r[i] <= mem_w[i];
        end
    end

endmodule