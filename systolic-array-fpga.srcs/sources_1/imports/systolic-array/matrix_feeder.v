module matrix_feeder #(
    parameter DATA_WIDTH = 8,
    parameter N = 4
) (
    // Takes in a row-major matrix and staggers output depending on which row/col is selected
    // Row major formula : (row * N + col) * DATA_WIDTH +: DATAWIDTH
    input i_clk,
    input i_rst,
    input i_start,      // signal to start feeding

    input wire [(N*N*DATA_WIDTH)-1 : 0] i_MatrixA,
    input wire [(N*N*DATA_WIDTH)-1 : 0] i_MatrixB,

    output reg [(N*DATA_WIDTH)-1 : 0] o_aOut,
    output reg [(N*DATA_WIDTH)-1 : 0] o_bOut,

    output wire o_feeding
);
    localparam STAGES = (2 * N) - 1;
    localparam STAGE_WIDTH = (STAGES <= 1) ? 1 : $clog2(STAGES);

    reg [STAGE_WIDTH-1 : 0] stage;
    reg active; 

    assign o_feeding = active;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            stage <= 0;
            active <= 0;
        end else if (i_start) begin
            stage <= 0;
            active <= 1;
        end else if (active) begin
            if (stage == STAGES - 1) begin // end of stage is STAGES - 1
                active <= 0;
            end else begin
                stage <= stage + 1'b1;
            end
        end
    end

    integer row, col;

    always @(*) begin
        o_aOut = 0;
        o_bOut = 0; // default values

        if (active) begin

            // Matrix A Feeding;
            for (row = 0; row < N; row = row + 1) begin

                if ((stage >= row) && (stage < row + N)) begin
                    o_aOut[row*DATA_WIDTH +: DATA_WIDTH] = i_MatrixA[(row * N + (stage-row)) * DATA_WIDTH +: DATA_WIDTH]; // process in row major order;
                end
            end

            // Matrix B Feeding;
            for (col = 0; col < N; col = col + 1) begin

                if ((stage >= col) && (stage < col + N)) begin
                    o_bOut[col*DATA_WIDTH +: DATA_WIDTH] = 
                    i_MatrixB[((stage-col) * N + col) * DATA_WIDTH +: DATA_WIDTH]; // process in row major order; 
                end
            end
        end
    end

endmodule   