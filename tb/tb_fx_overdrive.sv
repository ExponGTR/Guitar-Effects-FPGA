`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.10.2026 23:59:21
// Design Name: 
// Module Name: tb_fx_overdrive
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_fx_overdrive;

    logic clk, rst;
    logic sample_ce;
    logic en;
    logic [1:0] mode;
    logic signed [23:0] sample_in;
    logic signed [23:0] sample_out;
    
    fx_overdrive #(
        .SAMPLE_WDT(24)
    ) dut (.*);
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    task check_sample (
        input logic signed [23:0] test_input,
        input logic [1:0] test_mode,
        input logic test_en,
        input logic signed [23:0] expected_output
    );
        begin
            @(negedge clk);
            sample_in = test_input;
            mode = test_mode;
            en = test_en;
            sample_ce = 1'b1;
            @(posedge clk);
            #1;
            if (sample_out !== expected_output) begin
                $error("FAIL: input=%0d mode=%b enable=%b expected=%0d got=%0d", test_input, test_mode, test_en, expected_output, sample_out);
                $fatal(1);
            end
            else begin
                $display("PASS: input=%0d mode=%b output=%0d", test_input, test_mode, sample_out);
            end
        end
    endtask
    
    initial begin
        rst       = 1'b1;
        sample_ce = 1'b0;
        en    = 1'b0;
        mode      = 2'b00;
        sample_in = '0;
    
        repeat (12) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
    
        // Test 1: Bypass.
        check_sample(
            24'sd3000000, 2'b00, 1'b0,
            24'sd3000000
        );
    
        // Test 2: Mild positive clipping.
        check_sample(
            24'sd7000000, 2'b00, 1'b1,
            24'sd6291455
        );
    
        // Test 3: Mild negative clipping.
        check_sample(
            -24'sd7000000, 2'b00, 1'b1,
            -24'sd6291455
        );
    
        // Test 4: Medium clipping.
        check_sample(
            24'sd5000000, 2'b01, 1'b1,
            24'sd4194303
        );
    
        // Test 5: Hard clipping.
        check_sample(
            24'sd3000000, 2'b10, 1'b1,
            24'sd2097151
        );
        
        // Test 6: Medium positive no clipping
        check_sample(
            24'sd1000000, 2'b01, 1'b1, 24'sd2000000
        );
        
        // Test 7: Medium negative no clipping
        check_sample(
            -24'sd1000000, 2'b01, 1'b1, -24'sd2000000
        );
        
        //additional tests
        check_sample( 24'sd6291455, 2'b00, 1'b1,  24'sd6291455);
        check_sample( 24'sd6291456, 2'b00, 1'b1,  24'sd6291455);
        check_sample(-24'sd6291455, 2'b00, 1'b1, -24'sd6291455);
        check_sample(-24'sd6291456, 2'b00, 1'b1, -24'sd6291455);
        // The preceding test leaves sample_out at -6291455.
        sample_in = 24'sd12345;
        sample_ce = 1'b0;
        
        @(posedge clk);
        #1;
        
        if (sample_out !== -24'sd6291455) begin
            $error("FAIL: sample_out changed while sample_ce was low");
            $fatal(1);
        end
        else begin
            $display("PASS: sample_out held while sample_ce was low");
        end
        $display("All overdrive tests passed.");
        $finish;
    end
endmodule
