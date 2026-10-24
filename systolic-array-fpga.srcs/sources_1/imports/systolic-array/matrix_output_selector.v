module matrix_output_selector #(
    parameter ACC_WIDTH = 16,
    parameter N = 4
)(
    input wire [N*N*ACC_WIDTH-1:0] i_matrix,
    input wire [$clog2(N*N)-1:0] i_select,
    output wire [ACC_WIDTH-1:0] o_value
);

    assign o_value =
        i_matrix[i_select*ACC_WIDTH +: ACC_WIDTH];

endmodule