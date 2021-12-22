// behavioral
module sram_dp_262144x32 (
    QA,
    QB,
    CLK, // assume CLKA = CLKB
    // CLKA,
    CENA,
    WENA,
    AA,
    DA,
    // CLKB,
    CENB,
    WENB,
    AB,
    DB
);

    parameter BITS       = 32;
    // parameter WORD_DEPTH = 262144;
    // parameter ADDR_WIDTH = 18;
    parameter WORD_DEPTH = 8192;
    parameter ADDR_WIDTH = 13;
    // parameter WORD_DEPTH = 16; // for tb
    // parameter ADDR_WIDTH = 4;  // for tb
    integer i;

    input                     CLK;
    // input                     CLKA, CLKB;
    input                     CENA, CENB; // CEN 0:w/r | 1:standby
    input                     WENA, WENB; // WEN 0:write | 1:read
    input  [ADDR_WIDTH - 1:0] AA, AB;
    input  [BITS - 1:0]       DA, DB;

    output [BITS - 1:0]       QA, QB;

    reg [BITS - 1:0] QA_r, QA_w;
    reg [BITS - 1:0] QB_r, QB_w;

    reg [BITS - 1:0] mem_r [0:WORD_DEPTH - 1];
    reg [BITS - 1:0] mem_w [0:WORD_DEPTH - 1];

    assign QA = QA_r; 
    assign QB = QB_r;

    always @(*) begin
        // avoid w/w w/r r/w same address at the same time
        QA_w = QA_r;
        QB_w = QB_r;
        for (i = 0;i < WORD_DEPTH;i = i + 1) begin
            mem_w[i] = mem_r[i];
        end
        if (~CENA) begin
            QA_w      = (~WENA) ? DA : mem_r[AA];
            mem_w[AA] = (~WENA) ? DA : mem_r[AA];
        end
        if (~CENB) begin
            QB_w      = (~WENB) ? DB : mem_r[AB];
            mem_w[AB] = (~WENB) ? DB : mem_r[AB];
        end
    end

    always @(posedge CLK) begin
        QA_r <= QA_w;
        QB_r <= QB_w;
        for (i = 0;i < WORD_DEPTH;i = i + 1) begin
            mem_r[i] <= mem_w[i];
        end
    end

endmodule