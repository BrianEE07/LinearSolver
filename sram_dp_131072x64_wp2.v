// behavioral
module sram_dp_131072x64_wp2 (
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

    parameter BITS       = 64;
    // parameter WORD_DEPTH = 131072;
    // parameter ADDR_WIDTH = 17;
    parameter WORD_DEPTH = 8192;
    parameter ADDR_WIDTH = 13;
    // parameter WORD_DEPTH = 16; // for tb
    // parameter ADDR_WIDTH = 4;  // for tb
    parameter HBITS      = BITS / 2;

    integer i;

    input                     CLK;
    // input                     CLKA, CLKB;
    input                     CENA, CENB; // CEN    0:w/r | 1:standby
    input  [1:0]              WENA, WENB; // WEN[k] 0:write | 1:read (word write mask is on)
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
            QA_w[BITS - 1:HBITS]       = (~WENA[1]) ? DA[BITS - 1:HBITS] : mem_r[AA][BITS - 1:HBITS];
            mem_w[AA][BITS - 1:HBITS]  = (~WENA[1]) ? DA[BITS - 1:HBITS] : mem_r[AA][BITS - 1:HBITS];
            QA_w[HBITS - 1:0]          = (~WENA[0]) ? DA[HBITS - 1:0]  : mem_r[AA][HBITS - 1:0];
            mem_w[AA][HBITS - 1:0]     = (~WENA[0]) ? DA[HBITS - 1:0]  : mem_r[AA][HBITS - 1:0];
        end
        if (~CENB) begin
            QB_w[BITS - 1:HBITS]       = (~WENB[1]) ? DB[BITS - 1:HBITS] : mem_r[AB][BITS - 1:HBITS];
            mem_w[AB][BITS - 1:HBITS]  = (~WENB[1]) ? DB[BITS - 1:HBITS] : mem_r[AB][BITS - 1:HBITS];
            QB_w[HBITS - 1:0]          = (~WENB[0]) ? DB[HBITS - 1:0]  : mem_r[AB][HBITS - 1:0];
            mem_w[AB][HBITS - 1:0]     = (~WENB[0]) ? DB[HBITS - 1:0]  : mem_r[AB][HBITS - 1:0];
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