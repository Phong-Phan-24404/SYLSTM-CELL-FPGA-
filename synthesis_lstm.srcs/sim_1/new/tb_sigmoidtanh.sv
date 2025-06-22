`timescale 1ns / 1ps

module tb_sigmoidtanh;

    localparam int DATA_WIDTH = 32;
    localparam int FIXED_POINT_SCALE = 32'h01000000;
    localparam int CLK_PERIOD = 10;

    logic clk, rst, start;
    logic done_sigmoid, done_tanh;
    logic ready_sigmoid, ready_tanh;
    logic signed [DATA_WIDTH-1:0] x;
    logic signed [DATA_WIDTH-1:0] y_sigmoid, y_tanh;

    // Instantiate modules
    sigmoid #(.DATA_WIDTH(DATA_WIDTH)) sigmoid_inst (
        .clk(clk), .rst(rst), .start(start),
        .done(done_sigmoid), .ready(ready_sigmoid),
        .x(x), .y(y_sigmoid)
    );

    tanh #(.DATA_WIDTH(DATA_WIDTH)) tanh_inst (
        .clk(clk), .rst(rst), .start(start),
        .done(done_tanh), .ready(ready_tanh),
        .x(x), .y(y_tanh)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // abs helper (not used anymore but kept if needed)
    function automatic logic signed [DATA_WIDTH-1:0] abs(input logic signed [DATA_WIDTH-1:0] val);
        return (val < 0) ? -val : val;
    endfunction

    localparam int NUM_TESTS = 5;
    logic signed [DATA_WIDTH-1:0] x_values [NUM_TESTS];

    real x_real, y_sigmoid_real, y_tanh_real;

    initial begin
        rst = 1; start = 0; x = 0;
        @(posedge clk); rst = 0; @(posedge clk);

        wait(ready_sigmoid && ready_tanh);
        @(posedge clk);

        // Test inputs: -1.0 → 1.0
        x_values[0] = 32'hff000000; // -1.0
        x_values[1] = 32'hff800000; // -0.5
        x_values[2] = 32'h00000000; //  0.0
        x_values[3] = 32'h00800000; //  0.5
        x_values[4] = 32'h01000000; //  1.0

        for (int i = 0; i < NUM_TESTS; i++) begin
            x = x_values[i];
            start = 1;
            @(posedge clk); start = 0;
            wait(done_sigmoid && done_tanh);
            @(posedge clk);

            x_real = real'(signed'(x)) / FIXED_POINT_SCALE;
            y_sigmoid_real = real'(signed'(y_sigmoid)) / FIXED_POINT_SCALE;
            y_tanh_real = real'(signed'(y_tanh)) / FIXED_POINT_SCALE;

            $display("\n=== Test %0d ===", i);
            $display("x        = %h (%f)", x, x_real);
            $display("Sigmoid  = %h (%f)", y_sigmoid, y_sigmoid_real);
            $display("Tanh     = %h (%f)", y_tanh, y_tanh_real);
        end

        $display("\nTestbench completed.");
        $finish;
    end

endmodule
