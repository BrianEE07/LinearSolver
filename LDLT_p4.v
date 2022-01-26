module LDLT #(
	parameter DATA_LEN = 32,
	parameter NODE_NUM = 100,
	parameter FRACTION = 16
)(
    clk,
    rst_n,
    i_start,
    i_data,
    o_valid,
    o_data
);

    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam WAIT = 3'b010;
    localparam SMAC = 3'b011;
    localparam SDIV = 3'b100;
    localparam PREL = 3'b101;
    localparam WRTE = 3'b110;

    parameter ROUND = ((1 << 2 * FRACTION) - 1);

    input                   clk, rst_n;
    input                   i_start;
    input  [DATA_LEN - 1:0] i_data;
    output                  o_valid;
    output [DATA_LEN - 1:0] o_data;

    reg [2:0]             state_r, state_w;
    reg                   o_valid_r, o_valid_w;
    reg [DATA_LEN - 1:0]  o_data_r, o_data_w;

    reg [9:0] i_r, i_w; // cycle counter i
    reg [9:0] j_r, j_w; // cycle counter j
    reg [9:0] k_r, k_w; // cycle counter k
    reg [1:0] l_r, l_w; // cycle counter l
    
    reg signed [3 * DATA_LEN - 1:0] mac1_r, mac1_w;
    reg signed [3 * DATA_LEN - 1:0] mac2_r, mac2_w;

    wire signed [3 * DATA_LEN - 1:0]        mac;
    wire signed [DATA_LEN + FRACTION - 1:0] submac;
    wire signed [DATA_LEN * 2 - 1:0]        quotient;

    reg         [17:0]           AA, AB;
    reg         [9:0]            AC1, AC2, AD1, AD2;
    reg  signed [DATA_LEN - 1:0] DA1, DA2, DB1, DB2, DC1, DC2, DD1, DD2;
    wire signed [DATA_LEN - 1:0] QA1, QA2, QB1, QB2, QC1, QC2, QD1, QD2;
    wire                         CENA, CENB, CENC1, CENC2, CEND1, CEND2;
    wire        [1:0]            WENA, WENB;
    wire                         WENC1, WENC2, WEND1, WEND2;

    wire [17:0] Lim;
    wire [17:0] Lin_2;
    wire [17:0] Ljn_1;

    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    assign CENA  = 0;
    assign CENB  = ~(WENA == 2'b11); // disable port B when port A is writing data
    assign CENC1 = 0;
    assign CENC2 = ~(WENC1);
    assign CEND1 = 0;
    assign CEND2 = ~(WEND1);

    assign WENA  = (state_r == LOAD && i_r != j_r && j_r[0])          ? 2'b10 :
                   (state_r == LOAD && i_r != j_r && !j_r[0])         ? 2'b01 :
                   (state_r == SDIV && !l_r && i_r != j_r && j_r[0])  ? 2'b10 : 
                   (state_r == SDIV && !l_r && i_r != j_r && !j_r[0]) ? 2'b01 :
                   (state_r == SDIV && l_r == 2 && j_r[0])            ? 2'b10 :
                   (state_r == SDIV && l_r == 2 && !j_r[0])           ? 2'b01 : 2'b11;
    assign WENB  = 2'b11;
    assign WENC1 = (state_r == PREL && k_r != j_r) ? 0 : 1;
    assign WENC2 = 1;
    assign WEND1 = (state_r == LOAD && i_r == j_r)         ? 0 :
                   (state_r == SDIV && !l_r && i_r == j_r) ? 0 : 1;
    assign WEND2 = 1;

    assign mac      = (!l_r) ? mac1_r : mac2_r;
    assign submac   = ((!l_r && i_r == j_r) ? QD1 : ((j_r[0]) ? QA2 : QA1)) - (((mac < 0) ? mac + ROUND : mac) >>> 2 * FRACTION);
    assign quotient = (submac << FRACTION) / QD1;

    assign Lim   = flat_addr(i_r, j_r >> 1);
    assign Lin_2 = flat_addr(i_r, (k_r + 2) >> 1);
    assign Ljn_1 = flat_addr(j_r, (k_r + 1) >> 1);

    function [17:0] flat_addr;
        input [9:0] i, j;
        begin
            flat_addr = ((6 * NODE_NUM * (6 * NODE_NUM - 1)) >> 1) - (((6 * NODE_NUM - j) * (6 * NODE_NUM - j - 1)) >> 1) + i - j - 1;
        end
    endfunction

    // for L
    sram_dp_131072x64_wp2 r0 (
        .QA({QA1, QA2}),
        .QB({QB1, QB2}),
        .CLK(clk),
        .CENA(CENA),
        .WENA(WENA),
        .AA(AA),
        .DA({DA1, DA2}),
        .CENB(CENB),
        .WENB(WENB),
        .AB(AB),
        .DB({DB1, DB2})
    );

    // for stationary row
    sram_dp_1024x32 r1 (
        .QA(QC1),
        .QB(QC2),
        .CLK(clk),
        .CENA(CENC1),
        .WENA(WENC1),
        .AA(AC1),
        .DA(DC1),
        .CENB(CENC2),
        .WENB(WENC2),
        .AB(AC2),
        .DB(DC2)
    );

    // for D
    sram_dp_1024x32 r2 (
        .QA(QD1),
        .QB(QD2),
        .CLK(clk),
        .CENA(CEND1),
        .WENA(WEND1),
        .AA(AD1),
        .DA(DD1),
        .CENB(CEND2),
        .WENB(WEND2),
        .AB(AD2),
        .DB(DD2)
    );

    // FSM
    always @(*) begin
        case (state_r)
            IDLE: begin
                if (i_start) state_w = LOAD;
                else         state_w = IDLE;
            end
            LOAD: begin
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) state_w = WAIT;
                else                                                    state_w = LOAD;
            end
            WAIT: begin
                state_w = SDIV;
            end
            SMAC: begin
                if (k_r + 2 >= j_r) state_w = SDIV;
                else                state_w = SMAC;
            end
            SDIV: begin
                if (j_r == 6 * NODE_NUM - 1 && l_r == 1)        state_w = WRTE;
                else if ((i_r == 6 * NODE_NUM - 2 && l_r == 3) || 
                         (i_r == 6 * NODE_NUM - 1 && l_r == 1)) state_w = PREL;
                else if (j_r && l_r == 3)                       state_w = SMAC;
                else                                            state_w = SDIV; 
            end
            PREL: begin
                if (k_r == j_r) state_w = SMAC;
                else            state_w = PREL;
            end
            WRTE: begin
                if (j_r == 6 * NODE_NUM - 1 && i_r == 6 * NODE_NUM - 1) state_w = IDLE;
                else                                                    state_w = WRTE;
            end
            default: state_w = state_r;
        endcase
    end

    // Index Control
    always @(*) begin
        i_w = i_r;
        j_w = j_r;
        k_w = k_r;
        l_w = l_r;
        case (state_r)
            IDLE: ;
            LOAD, WRTE: begin
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
            WAIT: ;
            SDIV: begin
                if (j_r == 6 * NODE_NUM - 1 && l_r == 1) begin
                    j_w = 0;
                    i_w = 0;
                    k_w = 0;
                    l_w = 0;
                end
                else if ((i_r == 6 * NODE_NUM - 2 && l_r == 3) || 
                         (i_r == 6 * NODE_NUM - 1 && l_r == 1)) begin
                    j_w = j_r + 1;
                    i_w = j_r + 1;
                    k_w = 0;
                    l_w = 0;
                end
                else if (l_r == 3) begin
                    i_w = i_r + 2;
                    k_w = 0;
                    l_w = 0;
                end
                else begin
                    l_w = l_r + 1;
                end
            end
            SMAC: begin
                if (k_r + 1 >= j_r) begin
                    k_w = k_r + 1;
                end
                else begin
                    k_w = k_r + 2;
                end
            end
            PREL: begin
                if (k_r == j_r) begin
                    k_w = 0;
                end
                else begin
                    k_w = k_r + 1;
                end
            end
            default: ;
        endcase
    end

    // Address/Data Control
    always @(*) begin
        DA1 = 0;
        DA2 = 0;
        DB1 = 0;
        DB2 = 0;
        DC1 = 0;
        DC2 = 0;
        DD1 = 0;
        DD2 = 0;
        AA  = 0;
        AB  = 0;
        AC1 = 0;
        AC2 = 0;
        AD1 = 0;
        AD2 = 0;
        case (state_r)
            IDLE: ;
            LOAD: begin
                AA         = Lim;
                AD1        = j_r;
                DA1        = (j_r[0]) ? 0 : i_data;
                DA2        = (j_r[0]) ? i_data : 0;
                DD1        = i_data;
            end
            WAIT: ;
            SDIV: begin
                if (j_r == 6 * NODE_NUM - 1 && l_r == 1) begin
                    AD1 = 0;
                end
                else if ((i_r == 6 * NODE_NUM - 2 && l_r == 3) || 
                         (i_r == 6 * NODE_NUM - 1 && l_r == 1)) begin
                    AA = j_r; // Lj_10
                end
                else if (l_r == 3) begin
                    AA  = i_r + 1; // Li_20
                    AD1 = 0;
                    if (j_r) begin
                        AB = i_r + 2; // Li_30
                        AC1 = 0;
                        AC2 = 1;
                        AD2 = 1;
                    end
                end
                else begin
                    if (!l_r) begin
                        if (i_r == j_r) begin
                            AD1 = j_r;
                            DD1 = submac;
                        end
                        else begin
                            AA = Lim;
                            DA1 = (j_r[0]) ? 0 : quotient;
                            DA2 = (j_r[0]) ? quotient : 0;
                        end
                    end
                    else if (l_r == 1) begin
                        AA  = Lim + 1; // Li_1j
                        AD1 = j_r;
                    end
                    else begin // l_r == 2
                        AA  = Lim + 1; // Li_1j
                        DA1 = (j_r[0]) ? 0 : quotient;
                        DA2 = (j_r[0]) ? quotient : 0;
                    end
                end
            end
            SMAC: begin
                if (k_r + 2 >= j_r) begin
                    AD1 = j_r;
                    if (i_r != j_r) begin
                        AA = Lim;
                    end
                end
                else begin
                    AA  = Lin_2;
                    AB  = (i_r == 6 * NODE_NUM - 1) ? 0 : Lin_2 + 1; // Li_1k_2
                    AC1 = k_r + 2;
                    AC2 = k_r + 3;
                    AD1 = k_r + 2;
                    AD2 = k_r + 3;
                end
            end
            PREL: begin
                if (k_r == j_r) begin
                    AA  = i_r - 1; // Li0
                    AB  = (j_r == 6 * NODE_NUM - 1) ? 0 : i_r; // Li_10
                    AC1 = 0;
                    AC2 = 1;
                    AD1 = 0;
                    AD2 = 1;
                end
                else begin
                    AA  = (k_r == j_r - 1) ? 0 : Ljn_1;
                    AC1 = k_r;
                    DC1 = (k_r[0]) ? QA2 : QA1;
                end
            end
            WRTE: begin
                AB  = Lim + 1; // Li_1j
                AD1 = j_r + 1;
            end
            default: ;
        endcase
    end

    // Combinational
    always @(*) begin
        o_valid_w = 0;
        o_data_w  = 0;
        mac1_w    = mac1_r;
        mac2_w    = mac2_r;
        case (state_r)
            IDLE: ;
            LOAD: ;
            WAIT: ;
            SDIV: begin
                if ((i_r == 6 * NODE_NUM - 1 && l_r == 1) || l_r == 3) begin
                    mac1_w = 0;
                    mac2_w = 0;
                end
            end
            SMAC: begin
                // mac1_w = mac1_r + (((k_r[0]) ? QA2 : QA1) * QD1) * QC1;
                // mac2_w = mac2_r + (((k_r[0]) ? QB2 : QB1) * QD1) * QC1;
                mac1_w = mac1_r + (QA1 * QD1) * QC1 + ((k_r + 2 <= j_r) ? (QA2 * QD2) * QC2 : 0);
                mac2_w = mac2_r + (QB1 * QD1) * QC1 + ((k_r + 2 <= j_r) ? (QB2 * QD2) * QC2 : 0);
            end
            PREL: ;
            WRTE: begin
                o_valid_w = 1;
                if (i_r != j_r)
                    o_data_w = (j_r[0]) ? QB2 : QB1;
                else 
                    o_data_w = QD1;
            end
            default: ;
        endcase
    end

    // Sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r   <= IDLE;
            o_data_r  <= 0;
            o_valid_r <= 0;

            i_r <= 0;
            j_r <= 0;
            k_r <= 0;
            l_r <= 0;

            mac1_r <= 0;
            mac2_r <= 0;
        end
        else begin
            state_r   <= state_w;
            o_data_r  <= o_data_w;
            o_valid_r <= o_valid_w;

            i_r <= i_w;
            j_r <= j_w;
            k_r <= k_w;
            l_r <= l_w;

            mac1_r <= mac1_w;
            mac2_r <= mac2_w;
        end
    end

endmodule
