`timescale 1 ns/1 ps
`define CYCLE       10.0
`define MAX_CYCLE   10000


module sram_wp2_tb;

    reg         CLK;
    reg         CENA, CENB;
    reg  [1:0]  WENA, WENB;
    reg  [63:0] DA, DB;
    reg  [3:0]  AA, AB;
    wire [63:0] QA, QB;

    // only test sram_dp_16x64_wp2
    sram_dp_131072x64_wp2 r0(
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
        $fsdbDumpfile("sram_wp2_tb.fsdb");
        $fsdbDumpvars(0, sram_wp2_tb, "+mda");
    end

    initial begin
        CLK  = 1'b1;
        CENA = 1'b0;
        CENB = 1'b0;
        WENA = 2'b11;
        WENB = 2'b11;
        DA   = 64'h0;
        DB   = 64'h0;
        AA   = 4'd0;
        AB   = 4'd0;
        #(`CYCLE * 2.0);
        // test write mask on
        WENA = 2'b00;
        WENB = 2'b10;
        AA   = 4'd0;
        AB   = 4'd1;
        DA   = 64'h00001111_00002222;
        DB   = 64'h00003333_00004444;
        #(`CYCLE); // Q 00001111_00002222 XXXXXXXX_00004444
        WENA = 2'b01;
        WENB = 2'b10;
        DA   = 64'h0000AAAA_0000BBBB;
        DB   = 64'h0000CCCC_0000DDDD;
        #(`CYCLE); // Q 0000AAAA_00002222 XXXXXXXX_0000DDDD
        WENA = 2'b01;
        WENB = 2'b01;
        #(`CYCLE); // Q 0000AAAA_00002222 0000CCCC_0000DDDD
        WENA = 2'b10;
        WENB = 2'b10;
        #(`CYCLE); // Q 0000AAAA_0000BBBB 0000CCCC_0000DDDD
        WENA = 2'b00;
        WENB = 2'b00;
        DA   = 64'h00001111_00002222;
        DB   = 64'h00003333_00004444;
        #(`CYCLE); // Q 00001111_00002222 00003333_00004444
        WENA = 2'b11;
        WENB = 2'b11;
        DA   = 64'h0000AAAA_0000BBBB;
        DB   = 64'h0000CCCC_0000DDDD;
        #(`CYCLE); // Q 00001111_00002222 00003333_00004444
        #(`CYCLE * 2.0);
        $finish;
    end

    initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("-------------------- FINISH --------------------");
        $finish;
    end

endmodule
