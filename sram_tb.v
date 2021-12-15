`timescale 1 ns/1 ps
`define CYCLE       10.0
`define MAX_CYCLE   10000


module sram_tb;

    reg         CLK;
    reg         CENA, CENB;
    reg         WENA, WENB;
    reg  [31:0] DA, DB;
    reg  [3:0]  AA, AB;
    wire [31:0] QA, QB;

    // only test sram_dp_16x32
    sram_dp_262144x32 r0(
        .QA(QA),
        .QB(QB),
        .CLK(CLK),
        .CENA(CENA),
        .WENA(WENA),
        .AA(AA),
        .DA(DA),
        .CENB(CENB),
        .WENB(WENB),
        .AB(AB),
        .DB(DB)
    );	

    always #(`CYCLE * 0.5) CLK = ~CLK;

    initial begin
        $fsdbDumpfile("sram_tb.fsdb");
        $fsdbDumpvars(0, sram_tb, "+mda");
    end

    initial begin
        CLK  = 1'b1;
        CENA = 1'b0;
        CENB = 1'b0;
        WENA = 1'b1;
        WENB = 1'b1;
        DA   = 32'd0;
        DB   = 32'd0;
        AA   = 4'd0;
        AB   = 4'd0;
        #(`CYCLE * 2.0);
        // test write
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 32'd10;
        DB   = 32'd20;
        #(`CYCLE); // Q 10 20
        AA   = 4'd2;
        AB   = 4'd3;
        DA   = 32'd30;
        DB   = 32'd40;
        #(`CYCLE); // Q 30 40
        AA   = 4'd4;
        AB   = 4'd5;
        DA   = 32'd50;
        DB   = 32'd60;
        #(`CYCLE); // Q 50 60
        AA   = 4'd6;
        AB   = 4'd7;
        DA   = 32'd70;
        DB   = 32'd80;
        #(`CYCLE); // Q 70 80
        // test read
        WENA = 1'b1;
        WENB = 1'b1;
        AA   = 4'd0;
        AB   = 4'd1;
        #(`CYCLE); // Q 10 20
        AA   = 4'd2;
        AB   = 4'd3;
        #(`CYCLE); // Q 30 40
        AA   = 4'd4;
        AB   = 4'd5;
        #(`CYCLE); // Q 50 60
        AA   = 4'd6;
        AB   = 4'd7;
        #(`CYCLE); // Q 70 80
        // test w/r, r/w
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 32'd15;
        DB   = 32'd25;
        #(`CYCLE); // Q 15 25
        WENA = 1'b1;
        WENB = 1'b1;
        AA   = 4'd0;
        AB   = 4'd1;
        #(`CYCLE); // Q 15 25
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 32'd35;
        DB   = 32'd45;
        #(`CYCLE); // Q 35 45
        WENA = 1'b1;
        WENB = 1'b0;
        AA   = 4'd0;
        AB   = 4'd1;
        DB   = 32'd55;
        #(`CYCLE); // Q 35 55
        WENA = 1'b0;
        WENB = 1'b1;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 32'd65;
        #(`CYCLE); // Q 65 55
        // test cen
        CENA = 1'b1;
        CENB = 1'b0;
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 32'd18;
        DB   = 32'd28;
        #(`CYCLE); // Q 65 28
        CENA = 1'b1;
        CENB = 1'b1;
        WENA = 1'b1;
        WENB = 1'b1;
        AA   = 4'd2;
        AB   = 4'd3;
        #(`CYCLE); // Q 65 28
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd2;
        AB   = 4'd3;
        DA   = 32'd38;
        DB   = 32'd48;
        #(`CYCLE); // Q 65 28
        CENA = 1'b0;
        CENB = 1'b0;
        WENA = 1'b1;
        WENB = 1'b1;
        AA   = 4'd2;
        AB   = 4'd3;
        #(`CYCLE); // Q 30 40
        WENA = 1'b0;
        WENB = 1'b0;
        AA   = 4'd2;
        AB   = 4'd3;
        DA   = 32'd38;
        DB   = 32'd48;
        #(`CYCLE); // Q 38 48
        #(`CYCLE * 2.0);
        $finish;
    end

    initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("-------------------- FINISH --------------------");
        $finish;
    end

endmodule
