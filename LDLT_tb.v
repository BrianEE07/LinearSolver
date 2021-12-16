`timescale 1 ns/1 ps
`define CYCLE       10.0
`define MAX_CYCLE   10000

`define L_DATA "./pattern/matrix_6x6.dat"
`define L_GOLD "./pattern/golden_6x6.dat"

module LDLT_tb;

    parameter DATA_LEN = 32;
    parameter NODE_NUM = 1;
    parameter FRACTION = 16;

    parameter L_SIZE   = 6 * NODE_NUM * (6 * NODE_NUM + 1) / 2;


    reg                         clk, rst_n;
    reg                         i_start;
    reg signed [DATA_LEN - 1:0] i_data;

    wire                         o_valid;
    wire signed [DATA_LEN - 1:0] o_data;
    
    reg signed [DATA_LEN - 1:0] L_data [0:L_SIZE - 1];
    reg signed [DATA_LEN - 1:0] L_gold [0:L_SIZE - 1];

    LDLT_sram #(.DATA_LEN(DATA_LEN), .NODE_NUM(NODE_NUM), .FRACTION(FRACTION)) u0 (
        .clk(clk),
        .rst_n(rst_n),
        .i_start(i_start),
        .i_data(i_data),
        .o_valid(o_valid),
        .o_data(o_data)
    );

    always #(`CYCLE * 0.5) clk = ~clk;

    initial begin
        $fsdbDumpfile("LDLT_tb.fsdb");
        $fsdbDumpvars(0, LDLT_tb, "+mda");
    end
        
    initial begin
        $readmemb(`L_DATA, L_data);
        $readmemb(`L_GOLD, L_gold);
    end

    integer i, error;
    initial begin
        clk     = 0;
        rst_n   = 1;
        i_start = 0;
        #(`CYCLE * 0.5) rst_n   = 0;
        #(`CYCLE * 2.0) rst_n   = 1;
        #(`CYCLE * 0.5) i_start = 1;
        #(`CYCLE * 1.0) i_start = 0;
        i = 0;
        error = 0;
        while (i < L_SIZE) begin
            i_data = L_data[i];
            i = i + 1;
            #(`CYCLE * 1.0);
        end
        i_data = 0;
        while (!o_valid) #(`CYCLE * 1.0);
        i = 0;
        while (i < L_SIZE) begin
            if (o_data !== L_gold[i]) begin
                $display ("L[%d]: Error! golden=%d, yours=%d"
                , i, L_gold[i], o_data);
                error = error + 1;
            end
            i = i + 1;
            #(`CYCLE * 1.0);
        end

        $display("Pattern: ", `L_DATA);
        if(error == 0) begin
            $display("----------------------------------------------");
            $display("-                 ALL PASS!                  -");
            $display("----------------------------------------------");
        end else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total error: %d                      ", error);
            $display("----------------------------------------------");
        end
        # (`CYCLE * 2.0);
        $finish;
    end
    
    initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("-------------EXCEED-MAX-TIME-FINISH -------------");
        $finish;
    end

endmodule




