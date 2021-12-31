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
    reg         [9:0]            AC, AD;
    reg  signed [DATA_LEN - 1:0] DA, DB, DC, DD;
    wire signed [DATA_LEN - 1:0] QA, QB, QC, QD;
    wire                         CENA, CENB, CENC, CEND;
    wire                         WENA, WENB, WENC, WEND;

    wire [17:0] Lij;
    wire [17:0] Lik_1;
    wire [17:0] Ljk_1;

    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    assign CENA = 0;
    assign CENB = ~(WENA); // disable port B when port A is writing data
    assign CENC = 0;
    assign CEND = 0;

    assign WENA = (state_r == LOAD && i_r != j_r)         ? 0 : 
                  (state_r == SDIV && !l_r && i_r != j_r) ? 0 : 
                  (state_r == SDIV && l_r == 2)           ? 0 : 1;
    assign WENB = 1;
    assign WENC = (state_r == PREL && k_r != j_r) ? 0 : 1;
    assign WEND = (state_r == LOAD && i_r == j_r)         ? 0 :
                  (state_r == SDIV && !l_r && i_r == j_r) ? 0 : 1;

    assign mac      = (!l_r) ? mac1_r : mac2_r;
    assign submac   = ((!l_r && i_r == j_r) ? QD : QA) - (((mac < 0) ? mac + ROUND : mac) >>> 2 * FRACTION);
    assign quotient = (submac << FRACTION) / QD;

    assign Lij   = flat_addr(i_r, j_r);
    assign Lik_1 = flat_addr(i_r, k_r + 1);
    assign Ljk_1 = flat_addr(j_r, k_r + 1);

    function [17:0] flat_addr;
        input [9:0] i, j;
        begin
            flat_addr = ((6 * NODE_NUM * (6 * NODE_NUM - 1)) >> 1) - (((6 * NODE_NUM - j) * (6 * NODE_NUM - j - 1)) >> 1) + i - j - 1;
        end
    endfunction

    // for L
    sram_dp_262144x32 r0 (
        .QA(QA),
        .QB(QB),
        .CLK(clk),
        .CENA(CENA),
        .WENA(WENA),
        .AA(AA),
        .DA(DA),
        .CENB(CENB),
        .WENB(WENB),
        .AB(AB),
        .DB(DB)
    );

    // for stationary row
    sram_sp_1024x32 r1 (
        .Q(QC),
        .CLK(clk),
        .CEN(CENC),
        .WEN(WENC),
        .A(AC),
        .D(DC)
    );

    // for D
    sram_sp_1024x32 r2 (
        .Q(QD),
        .CLK(clk),
        .CEN(CEND),
        .WEN(WEND),
        .A(AD),
        .D(DD)
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
                if (k_r == j_r - 1) state_w = SDIV;
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
                k_w = k_r + 1;
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
        DA = 0;
        DB = 0;
        DC = 0;
        DD = 0;
        AA = 0;
        AB = 0;
        AC = 0;
        AD = 0;
        case (state_r)
            IDLE: ;
            LOAD: begin
                AA = Lij;
                AD = j_r;
                DA = i_data;
                DD = i_data;
            end
            WAIT: ;
            SDIV: begin
                if (j_r == 6 * NODE_NUM - 1 && l_r == 1) begin
                    AD = 0;
                end
                else if ((i_r == 6 * NODE_NUM - 2 && l_r == 3) || 
                         (i_r == 6 * NODE_NUM - 1 && l_r == 1)) begin
                    AA = j_r; // Lj_10
                end
                else if (l_r == 3) begin
                    AA = i_r + 1; // Li_20
                    AD = 0;
                    if (j_r) begin
                        AB = i_r + 2; // Li_30
                        AC = 0;
                    end
                end
                else begin
                    if (!l_r) begin
                        if (i_r == j_r) begin
                            AD = j_r;
                            DD = submac;
                        end
                        else begin
                            AA = Lij;
                            DA = quotient;
                        end
                    end
                    else if (l_r == 1) begin
                        AA = Lij + 1; // Li_1j
                        AD = j_r;
                    end
                    else begin // l_r == 2
                        AA = Lij + 1; // Li_1j
                        DA = quotient;
                    end
                end
            end
            SMAC: begin
                if (k_r == j_r - 1) begin
                    AD = j_r;
                    if (i_r != j_r) begin
                        AA = Lij;
                    end
                end
                else begin
                    AA = Lik_1;
                    AB = (i_r == 6 * NODE_NUM - 1) ? 0 : Lik_1 + 1; // Li_1k_1
                    AC = k_r + 1;
                    AD = k_r + 1;
                end
            end
            PREL: begin
                if (k_r == j_r) begin
                    AA = i_r - 1; // Li0
                    AB = (j_r == 6 * NODE_NUM - 1) ? 0 : i_r; // Li_10
                    AC = 0;
                    AD = 0;
                end
                else begin
                    AA = (k_r == j_r - 1) ? 0 : Ljk_1;
                    AC = k_r;
                    DC = QA;
                end
            end
            WRTE: begin
                AB = Lij + 1; // Li_1j
                AD = j_r + 1;
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
                mac1_w = mac1_r + (QA * QD) * QC;
                mac2_w = mac2_r + (QB * QD) * QC;
            end
            PREL: ;
            WRTE: begin
                o_valid_w = 1;
                o_data_w  = (i_r == j_r) ? QD : QB;
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
