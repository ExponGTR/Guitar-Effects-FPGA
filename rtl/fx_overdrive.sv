`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.10.2026 23:24:10
// Design Name: 
// Module Name: fx_overdrive
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


module fx_overdrive #(
    parameter int SAMPLE_WDT = 24
    )(
    input logic clk,
    input logic rst,
    input logic sample_ce,
    input logic en,
    input logic [1:0] mode,
    input logic signed [SAMPLE_WDT-1:0] sample_in,
    output logic signed [SAMPLE_WDT-1:0] sample_out
    );
    
    //cutoff thresholds
    localparam logic signed [SAMPLE_WDT-1:0] THRESHOLD_MILD = {1'b0, 1'b1, 1'b0, {(SAMPLE_WDT-3){1'b1}}}; //75%
    localparam logic signed [SAMPLE_WDT-1:0] THRESHOLD_MED = {2'b00, {(SAMPLE_WDT-2){1'b1}}};             //50%
    localparam logic signed [SAMPLE_WDT-1:0] THRESHOLD_HARD = {3'b000, {(SAMPLE_WDT-3){1'b1}}};           //25%
    logic signed [SAMPLE_WDT-1:0] threshold;
    logic [1:0] drive_shift;
    logic signed [SAMPLE_WDT-1:0] clipped;
    logic signed [SAMPLE_WDT+2:0] amplified;
    logic signed [SAMPLE_WDT+2:0] threshold_ext;
    
    //sequential blk
    always_ff @(posedge clk) begin
        if (rst) begin
            sample_out <= '0;
        end
        else if (sample_ce) begin
            if (en) begin
                sample_out <= clipped;
            end
            else begin
                sample_out <= sample_in;
            end    
        end
    end
    
    //comb blk
    always_comb begin
        case (mode)
            2'b00: begin
                threshold = THRESHOLD_MILD;
                drive_shift = 2'd0;
            end
            2'b01: begin
                threshold = THRESHOLD_MED;
                drive_shift = 2'd1;
            end
            2'b10: begin
                threshold = THRESHOLD_HARD;
                drive_shift = 2'd2;
            end
            default: begin
                threshold = THRESHOLD_MED;
                drive_shift = 2'd1;
            end
        endcase
        amplified = {{3{sample_in[SAMPLE_WDT-1]}}, sample_in} <<< drive_shift; 
        threshold_ext = {3'b000, threshold};       
        if (amplified > threshold_ext) begin
            clipped = threshold;
        end
        else if (amplified < -threshold_ext) begin
            clipped = -threshold;
        end
        else begin
            clipped = amplified[SAMPLE_WDT-1:0];
        end
    end
    
endmodule
