module systolic_controller #(
    parameter DATA_WIDTH = 8,
    parameter ACCUMULATE_WIDTH = 16, // FORMULA; ACC_WIDTH >= 2DATA_WIDTH + LOG2(N) (Do later)
    parameter N = 4
)(
    input  wire i_clk,
    input  wire i_rst,
    input  wire i_start,

    output wire o_rstAcc,
    output wire o_startFeed,
    output wire o_done,
    output wire o_busy
);
    // Number of run cycles for 0-index
    localparam integer RUN_CYCLES = 3 * N - 2;

    localparam integer COUNT_WIDTH = (RUN_CYCLES <= 1) ? 1 : $clog2(RUN_CYCLES);

    // Counter for number of cycles
    reg [COUNT_WIDTH - 1 : 0] run_count;

    // FSM State
    localparam IDLE     = 2'b00;
    localparam CLEAR    = 2'b01;
    localparam RUNNING  = 2'b10;
    localparam DONE     = 2'b11;

    reg [1:0] state;

    // Detect a rising edge on the start request.
    // Assumes i_start has already been synchronized
    // to i_clk and preferably debounced.
    reg start_prev;

    wire start_pulse = i_start && !start_prev;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            start_prev <= 1'b0;
        end else begin
            start_prev <= i_start;
        end
    end

    // State transitions and counter
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= IDLE;
            run_count <= 0;
        end else begin
            case (state)

                IDLE: begin
                    run_count <= 0;

                    if (start_pulse)
                        state <= CLEAR;
                end

                CLEAR: begin
                    run_count <= 0;
                    state <= RUN;
                end

                RUN: begin
                    if (run_count == RUN_CYCLES - 1) begin
                        state <= DONE;
                    end else begin
                        run_count <= run_count + 1'b1;
                    end
                end

                DONE: begin
                    if (start_pulse)
                        state <= CLEAR;
                end

                default: begin
                    state <= IDLE;
                    run_count <= 0;
                end
            endcase
        end
    end

    // Moore-style control outputs
    assign o_startFeed = (state == CLEAR);
    assign o_rstAcc    = (state == CLEAR);
    assign o_busy      = (state == CLEAR || state == RUN);
    assign o_done      = (state == DONE);

endmodule