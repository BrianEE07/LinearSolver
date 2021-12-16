module LDLT_sram #(
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
    localparam DIAG = 3'b011;
    localparam LTRI = 3'b100;
    localparam WRTE = 3'b101;
    
    parameter ADDR_LEN = 18;
    parameter ROUND    = ( (1 << 2 * FRACTION) - 1 );

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
    
    reg signed [3 * DATA_LEN - 1:0] mac_r, mac_w; // keep precision

    wire signed [DATA_LEN + FRACTION - 1:0] submac;
    wire signed [DATA_LEN * 2 - 1:0]        quotient;

    wire        [ADDR_LEN - 1:0] AA, AB, AC;
    wire signed [DATA_LEN - 1:0] DA, DB, DC;
    wire signed [DATA_LEN - 1:0] QA, QB, QC;
    wire CENA, CENB, CENC;
    wire WENA, WENB, WENC;

    wire [9:0]  addr_Dkk_1;
    wire [9:0]  addr_Djj;
    wire [17:0] addr_Lij;
    wire [17:0] addr_Lik_1;
    wire [17:0] addr_Ljk_1;

    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    assign addr_Dkk_1 = k_r + 1;
    assign addr_Djj   = j_r;
    assign addr_Lij   = ij2addr(i_r, j_r);
    assign addr_Lik_1 = ij2addr(i_r, k_r + 1);
    assign addr_Ljk_1 = ij2addr(j_r, k_r + 1);

    assign CENA = 0;
    assign CENB = ~(WENA); // disable port B when port A is writing data
    assign CENC = 0;

    assign WENA = (state_r == LOAD && i_r != j_r) ? 0 :
                  (state_r == LTRI && k_r == j_r) ? 0 : 1;
    assign WENB = 1;
    assign WENC = (state_r == LOAD && i_r == j_r) ? 0 :
                  (state_r == DIAG && k_r == j_r) ? 0 : 1;

    assign submac = ((state_r == DIAG) ? QC : QA) - (((mac_r < 0) ? mac_r + ROUND : mac_r) >>> 2 * FRACTION); // will mac overflow?
    assign quotient = (submac << FRACTION) / QC;

    assign DA = (state_r == LOAD) ? i_data :
                (state_r == LTRI) ? quotient : 0;
    assign DB = 0;
    assign DC = (state_r == LOAD) ? i_data :
                (state_r == DIAG) ? submac : 0;

    assign AA = (state_r == LOAD)                           ? addr_Lij :
                (k_r == j_r)                                ? addr_Lij :
                (j_r >= 1 && k_r == j_r - 1)                ? addr_Lij :
                (k_r == j_r + 1 && i_r == 6 * NODE_NUM - 1) ? j_r :
                (k_r == j_r + 1)                            ? i_r :
                (j_r >= 2 && k_r <= j_r - 2)                ? addr_Lik_1 : 0;
    assign AB = (state_r == WRTE)                            ? ij2addr(i_r + 1, j_r) :
                (k_r == j_r + 1 && j_r == 6 * NODE_NUM - 1)  ? 0 :
                (j_r >= 2 && k_r <= j_r - 2)                 ? addr_Ljk_1 :
                (j_r >= 1 && k_r == j_r + 1)                 ? j_r - 1 : 0;
    assign AC = (state_r == LOAD)               ? addr_Djj :
                (state_r == WRTE)               ? j_r + 1 :
                (k_r == j_r)                    ? addr_Djj :
                (j_r >= 1 && k_r == j_r - 1)    ? addr_Djj :
                (j_r >= 2 && k_r <= j_r - 2)    ? addr_Dkk_1 : 0;

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

    // for D
    sram_1024x32 r1 (
        .Q(QC),
        .CLK(clk),
        .CEN(CENC),
        .WEN(WENC),
        .A(AC),
        .D(DC)
    );

    function [17:0] ij2addr;
        input [9:0] i, j;
        begin
            ij2addr = ((6 * NODE_NUM * (6 * NODE_NUM - 1)) >> 1) - (((6 * NODE_NUM - j) * (6 * NODE_NUM - j - 1)) >> 1) + i - j - 1;
        end
    endfunction

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
                state_w = DIAG;
            end
            DIAG: begin
                if (k_r == j_r + 1) begin
                    if (j_r == 6 * NODE_NUM - 1) state_w = WRTE;
                    else                         state_w = LTRI;
                end
                else                             state_w = DIAG;
            end
            LTRI: begin
                if (i_r == 6 * NODE_NUM - 1 && k_r == j_r + 1) state_w = DIAG;
                else                                           state_w = LTRI;
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
            DIAG, LTRI: begin
                if (j_r == 6 * NODE_NUM - 1 && i_r == j_r && k_r == j_r + 1) begin
                    j_w = 0;
                    i_w = 0;
                    k_w = 0;
                end
                else begin
                    if (i_r == 6 * NODE_NUM - 1 && k_r == j_r + 1) begin
                        j_w = j_r + 1;
                        i_w = j_r + 1;
                        k_w = 0;
                    end
                    else begin
                        if (k_r == j_r + 1) begin
                            i_w = i_r + 1;
                            k_w = 0;
                        end
                        else begin
                            k_w = k_r + 1;
                        end
                    end
                end
            end
            default: ;
        endcase
    end

    // Combinational
    always @(*) begin
        o_valid_w = 0;
        o_data_w = 0;
        mac_w = mac_r;
        case (state_r)
            IDLE: ;
            LOAD: ;
            WAIT: ;
            DIAG, LTRI: begin
                if (k_r == j_r + 1) begin
                    mac_w = 0;
                end
                else begin
                    if (j_r >= 1 && k_r <= j_r - 1) begin
                        mac_w = mac_r + (QA * QC) * ((state_r == DIAG) ? QA : QB);
                    end
                end
            end
            WRTE: begin
                o_valid_w = 1;
                o_data_w  = (i_r == j_r) ? QC : QB;
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

            mac_r <= 0;
        end
        else begin
            state_r   <= state_w;
            o_data_r  <= o_data_w;
            o_valid_r <= o_valid_w;

            i_r <= i_w;
            j_r <= j_w;
            k_r <= k_w;

            mac_r <= mac_w;
        end
    end

endmodule
