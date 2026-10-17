module systolic_array_NxN #(
    parameter DATA_WIDTH = 8,
    parameter ACCUMULATE_WIDTH = 16, // FORMULA; ACC_WIDTH >= 2DATA_WIDTH + LOG2(N) (Do later)
    parameter N = 2
)(  
    // Systolic array just does processing after getting handed values from an external data manager, no need for regs
    
    // clock and reset signals
    input wire i_clk,
    input wire i_rst,
    input wire i_rstAcc,

    // N operands of Matrix A, one per PE row (left edge)
    input wire [(N * DATA_WIDTH)-1:0] i_MatrixA,

    // N operands of Matrix B, one per PE column (top edge)
    input wire [(N * DATA_WIDTH)-1:0] i_MatrixB,

    // Final accumulated matrix; probably need to do some bit masking to get output
    output wire [(N * N * ACCUMULATE_WIDTH)-1 : 0] o_MatrixAccumualte
);  

    // Horizontal A-connections
    wire [DATA_WIDTH - 1 : 0] a_wire [0:N-1][0:N];

    // Veritcal B-connections
    wire [DATA_WIDTH - 1 : 0] b_wire [0:N][0:N-1];

    // Accumulate wire
    wire [ACCUMULATE_WIDTH - 1 : 0] acc_wire [0:N-1][0:N-1];

    // Initialize processing elements;
    genvar row, col;
    generate
        for (row = 0; row < N; row = row + 1) begin : ROW
            // Assign A into the leftmost Processing element of each row
            assign a_wire[row][0] = i_MatrixA[row*DATA_WIDTH +: DATA_WIDTH];

            for (col = 0; col < N; col = col + 1) begin : COL
                if (row == 0) begin
                    // Assign A into the topmost Processing element of each col (Row 0)
                    assign b_wire[0][col] = i_MatrixB[col*DATA_WIDTH +: DATA_WIDTH];
                end

                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACCUMULATE_WIDTH(ACCUMULATE_WIDTH)
                ) pe_inst (
                    .i_clk(i_clk),
                    .i_rst(i_rst),
                    .i_rstAcc(i_rstAcc),

                    .i_aIn(a_wire[row][col]),
                    .i_bIn(b_wire[row][col]),

                    // A feeds horizotally; next column over, B feeds vertically; next row over
                    .o_aOut(a_wire[row][col+1]),
                    .o_bOut(b_wire[row+1][col]),

                    .o_accOut(acc_wire[row][col])
                );
                
                // Ensure values are in row major order; [63 -- C3 -- 48][47 -- C2 -- 32][31 -- C1 -- 16][15 -- C0 -- 0]
                assign o_MatrixAccumualte[(row * N + col) * ACCUMULATE_WIDTH +: ACCUMULATE_WIDTH] = acc_wire[row][col];
            end
        end

    endgenerate

endmodule
