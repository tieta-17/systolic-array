module seven_segment_controller (
    input  wire        i_clk,      // 100 MHz Basys 3 clock
    input  wire        i_rst,
    input  wire [15:0] i_value,

    output reg  [3:0]  o_an,
    output reg  [6:0]  o_seg,
    output wire        o_dp
);

    // Refresh each digit at approximately 1 kHz
    localparam integer REFRESH_COUNT = 25000;

    reg [14:0] refresh_counter;
    reg [1:0] digit_select;
    reg [3:0] hex_digit;

    assign o_dp = 1'b1; // Decimal point off

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end else if (refresh_counter == REFRESH_COUNT - 1) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1'b1;
        end else begin
            refresh_counter <= refresh_counter + 1'b1;
        end
    end

    // Digit selection
    always @(*) begin
        case (digit_select)
            2'd0: begin
                o_an = 4'b1110;
                hex_digit = i_value[3:0];
            end
            2'd1: begin
                o_an = 4'b1101;
                hex_digit = i_value[7:4];
            end
            2'd2: begin
                o_an = 4'b1011;
                hex_digit = i_value[11:8];
            end
            default: begin
                o_an = 4'b0111;
                hex_digit = i_value[15:12];
            end
        endcase
    end

    // Hexadecimal decoder: segments {a,b,c,d,e,f,g}
    always @(*) begin
        case (hex_digit)
            4'h0: o_seg = 7'b0000001;
            4'h1: o_seg = 7'b1001111;
            4'h2: o_seg = 7'b0010010;
            4'h3: o_seg = 7'b0000110;
            4'h4: o_seg = 7'b1001100;
            4'h5: o_seg = 7'b0100100;
            4'h6: o_seg = 7'b0100000;
            4'h7: o_seg = 7'b0001111;
            4'h8: o_seg = 7'b0000000;
            4'h9: o_seg = 7'b0000100;
            4'hA: o_seg = 7'b0001000;
            4'hB: o_seg = 7'b1100000;
            4'hC: o_seg = 7'b0110001;
            4'hD: o_seg = 7'b1000010;
            4'hE: o_seg = 7'b0110000;
            4'hF: o_seg = 7'b0111000;
            default: o_seg = 7'b1111111;
        endcase
    end

endmodule
