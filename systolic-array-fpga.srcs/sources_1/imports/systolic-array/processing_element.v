module processing_element #(
    parameter DATA_WIDTH = 8,
    parameter ACCUMULATE_WIDTH = 16
)(
    input wire  i_clk,
    input wire  i_rst,      // reset is active high
    input wire  i_rstAcc,   // reset accumulator
    input wire  [DATA_WIDTH-1 : 0]  i_aIn,          // data fr left of array
    input wire  [DATA_WIDTH-1 : 0]  i_bIn,          // data fr top of array
    output reg  [DATA_WIDTH-1 : 0]  o_aOut,         // a out; equal to a in
    output reg  [DATA_WIDTH-1 : 0]  o_bOut,         // b out; equal to b in
    output reg  [ACCUMULATE_WIDTH-1 : 0] o_accOut,   // accumulate out
);
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_aOut <= 0;ß
            o_bOut <= 0;
            o_accOut <= 0;
        end else begin
            o_aOut <= i_aIn;
            o_bOut <== i_bIn;
            if (i_accRst) begin
                o_accOut <= 0;
            end else begin
                o_accOut <= o_accOut + (i_aIn * i_bIn);
            end
        end
    end
endmodule