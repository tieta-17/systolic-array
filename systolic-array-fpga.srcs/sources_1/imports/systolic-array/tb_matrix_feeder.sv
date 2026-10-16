`timescale 1ns / 1ps

// ============================================================
// Parameterized test for one matrix_feeder instance
// ============================================================
module feeder_test #(
    parameter int N = 2,
    parameter int DATA_WIDTH = 8
)(
    input  logic clk,
    output logic done
);

    localparam int STAGES = 2*N - 1;
    localparam int MATRIX_BITS = N*N*DATA_WIDTH;
    localparam int OUTPUT_BITS = N*DATA_WIDTH;

    // DUT signals
    logic rst;
    logic start;

    logic [MATRIX_BITS-1:0] matrixA;
    logic [MATRIX_BITS-1:0] matrixB;

    wire [OUTPUT_BITS-1:0] a_out;
    wire [OUTPUT_BITS-1:0] b_out;
    wire feeding;

    integer checks = 0;

    // ========================================================
    // Device Under Test
    // ========================================================
    matrix_feeder #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_start(start),

        .i_MatrixA(matrixA),
        .i_MatrixB(matrixB),

        .o_aOut(a_out),
        .o_bOut(b_out),
        .o_feeding(feeding)
    );

    // ========================================================
    // Reference Model / Scoreboard
    //
    // For each stage t:
    //
    // A[row][k] enters at stage row + k
    // B[k][col] enters at stage col + k
    //
    // Uses independent traversal of matrix elements.
    // ========================================================
    task automatic check_outputs(
        input int expected_stage,
        input bit expected_active
    );

        logic [OUTPUT_BITS-1:0] expectedA;
        logic [OUTPUT_BITS-1:0] expectedB;

        expectedA = '0;
        expectedB = '0;

        if (expected_active) begin

            // Expected A operands
            for (int row = 0; row < N; row++) begin
                for (int k = 0; k < N; k++) begin

                    if (expected_stage == row + k) begin
                        expectedA[row*DATA_WIDTH +: DATA_WIDTH] =
                            matrixA[
                                (row*N + k)*DATA_WIDTH
                                +: DATA_WIDTH
                            ];
                    end
                end
            end

            // Expected B operands
            for (int col = 0; col < N; col++) begin
                for (int k = 0; k < N; k++) begin

                    if (expected_stage == col + k) begin
                        expectedB[col*DATA_WIDTH +: DATA_WIDTH] =
                            matrixB[
                                (k*N + col)*DATA_WIDTH
                                +: DATA_WIDTH
                            ];
                    end
                end
            end

        end

        // Case inequality detects mismatches AND unknown values.
        if (a_out !== expectedA ||
            b_out !== expectedB ||
            feeding !== expected_active) begin

            $display("\n========== TEST FAILED ==========");
            $display("Time:           %0t", $time);
            $display("Matrix size:    %0d x %0d", N, N);
            $display("Expected stage: %0d", expected_stage);

            $display("Expected A:     %h", expectedA);
            $display("Actual A:       %h", a_out);

            $display("Expected B:     %h", expectedB);
            $display("Actual B:       %h", b_out);

            $display("Expected feed:  %b", expected_active);
            $display("Actual feed:    %b", feeding);

            $fatal(1, "Matrix feeder verification failed");
        end

        checks++;

    endtask

    // ========================================================
    // Generate input matrices
    //
    // Pattern 0: Sequential values
    // Pattern 1: All zeros
    // Pattern 2: All ones
    // Pattern 3: Alternating bits
    // Pattern 4: One-hot patterns
    // Pattern 5: Random values
    // ========================================================
    task automatic load_matrices(input int pattern);

        matrixA = '0;
        matrixB = '0;

        case (pattern)

            0: begin
                for (int row = 0; row < N; row++) begin
                    for (int col = 0; col < N; col++) begin

                        matrixA[
                            (row*N + col)*DATA_WIDTH
                            +: DATA_WIDTH
                        ] = row*N + col + 1;

                        matrixB[
                            (row*N + col)*DATA_WIDTH
                            +: DATA_WIDTH
                        ] = row*N + col + 5;

                    end
                end
            end

            1: begin
                matrixA = '0;
                matrixB = '0;
            end

            2: begin
                matrixA = '1;
                matrixB = '1;
            end

            3: begin
                for (int bit_idx = 0;
                     bit_idx < MATRIX_BITS;
                     bit_idx++) begin

                    matrixA[bit_idx] = (bit_idx % 2 == 0);
                    matrixB[bit_idx] = (bit_idx % 2 != 0);
                end
            end

            4: begin
                matrixA[0] = 1'b1;
                matrixB[MATRIX_BITS-1] = 1'b1;
            end

            default: begin
                for (int bit_idx = 0;
                     bit_idx < MATRIX_BITS;
                     bit_idx++) begin

                    matrixA[bit_idx] = $urandom_range(0, 1);
                    matrixB[bit_idx] = $urandom_range(0, 1);
                end
            end

        endcase

    endtask

    // ========================================================
    // Execute and verify one complete multiplication feed
    // ========================================================
    task automatic run_test(input int pattern);

        // Set inputs before starting
        @(negedge clk);
        load_matrices(pattern);
        start = 1;

        // Start edge: stage 0 becomes active
        @(posedge clk);
        #1;
        check_outputs(0, 1);

        // Start is a one-cycle pulse
        @(negedge clk);
        start = 0;

        // Verify every remaining injection stage
        for (int t = 1; t < STAGES; t++) begin
            @(posedge clk);
            #1;
            check_outputs(t, 1);
        end

        // One more edge: feeder must become inactive
        @(posedge clk);
        #1;
        check_outputs(0, 0);

        // Verify feeder remains inactive
        repeat (2) begin
            @(posedge clk);
            #1;
            check_outputs(0, 0);
        end

    endtask

    // ========================================================
    // Verify asynchronous reset during an active operation
    // ========================================================
    task automatic test_mid_reset();

        @(negedge clk);
        load_matrices(0);
        start = 1;

        @(posedge clk);
        #1;
        check_outputs(0, 1);

        // Assert reset between clock edges
        @(negedge clk);
        start = 0;
        rst = 1;

        #1;
        check_outputs(0, 0);

        @(negedge clk);
        rst = 0;

        #1;
        check_outputs(0, 0);

    endtask

    // ========================================================
    // Verify i_start restarts the feeder
    // ========================================================
    task automatic test_restart();

        @(negedge clk);
        load_matrices(0);
        start = 1;

        @(posedge clk);
        #1;
        check_outputs(0, 1);

        @(negedge clk);
        start = 0;

        // Advance into the operation, when possible
        if (N > 1) begin
            @(posedge clk);
            #1;
            check_outputs(1, 1);
        end

        // Restart before normal completion
        @(negedge clk);
        start = 1;

        @(posedge clk);
        #1;
        check_outputs(0, 1);

        @(negedge clk);
        start = 0;

        // Verify the restarted sequence
        for (int t = 1; t < STAGES; t++) begin
            @(posedge clk);
            #1;
            check_outputs(t, 1);
        end

        @(posedge clk);
        #1;
        check_outputs(0, 0);

    endtask

    // ========================================================
    // Test sequence
    // ========================================================
    initial begin

        done = 0;
        rst = 1;
        start = 0;

        matrixA = '0;
        matrixB = '0;

        // Initial reset
        repeat (2) @(posedge clk);
        #1;
        check_outputs(0, 0);

        @(negedge clk);
        rst = 0;

        $display("[N=%0d] Starting directed tests", N);

        // Directed data patterns
        for (int pattern = 0; pattern < 5; pattern++) begin
            run_test(pattern);
        end

        $display("[N=%0d] Starting randomized tests", N);

        // Randomized matrix tests
        repeat (50) begin
            run_test(5);
        end

        $display("[N=%0d] Testing asynchronous reset", N);

        test_mid_reset();

        // Verify normal operation after reset
        run_test(5);

        $display("[N=%0d] Testing restart behavior", N);

        test_restart();

        $display(
            "[N=%0d] PASS: %0d checks completed",
            N, checks
        );

        done = 1;

    end

endmodule


// ============================================================
// Top-level regression testbench
// ============================================================
module tb_matrix_feeder;

    logic clk = 0;

    always #5 clk = ~clk;

    wire done1, done2, done3, done4;

    feeder_test #(.N(1)) test_N1 (
        .clk(clk),
        .done(done1)
    );

    feeder_test #(.N(2)) test_N2 (
        .clk(clk),
        .done(done2)
    );

    feeder_test #(.N(3)) test_N3 (
        .clk(clk),
        .done(done3)
    );

    feeder_test #(.N(4)) test_N4 (
        .clk(clk),
        .done(done4)
    );

    // Successful termination
    initial begin
        wait (done1 && done2 && done3 && done4);

        $display("\n=================================");
        $display(" ALL MATRIX FEEDER TESTS PASSED");
        $display("=================================\n");

        $finish;
    end

    // Prevent simulations from hanging indefinitely
    initial begin
        #1000000;
        $fatal(1, "TESTBENCH TIMEOUT");
    end

endmodule