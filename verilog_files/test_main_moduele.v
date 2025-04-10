module aad_pooling_2x2 (
    input  [31:0] x00, // Top-left pixel
    input  [31:0] x01, // Top-right pixel
    input  [31:0] x10, // Bottom-left pixel
    input  [31:0] x11, // Bottom-right pixel
    output [31:0] pool_out // Pooled output
);

  // Internal wires for absolute differences
  wire [31:0] abs_horiz0, abs_horiz1;
  wire [31:0] abs_vert0,  abs_vert1;

  wire [31:0] sub_horiz0_result1, sub_horiz0_result2;
  wire [31:0] sub_horiz1_result1, sub_horiz1_result2;
  wire [31:0] sub_vert0_result1, sub_vert0_result2;
  wire [31:0] sub_vert1_result1, sub_vert1_result2;

  fixed_point_subtractor fps0 (
      .a(x00),
      .b(x01),
      .result(sub_horiz0_result1)
  );

  fixed_point_subtractor fps1 (
      .a(x01),   
      .b(x00),
      .result(sub_horiz0_result2)
  );

  // Select the correct result based on comparison
  assign abs_horiz0 = (x00 >= x01) ? sub_horiz0_result1 : sub_horiz0_result2;

  // Repeat for other pairs
  fixed_point_subtractor fps2 (
      .a(x10),
      .b(x11),
      .result(sub_horiz1_result1)
  );

  fixed_point_subtractor fps3 (
      .a(x11),
      .b(x10),
      .result(sub_horiz1_result2)
  );

  assign abs_horiz1 = (x10 >= x11) ? sub_horiz1_result1 : sub_horiz1_result2;

  fixed_point_subtractor fps4 (
      .a(x00),
      .b(x10),
      .result(sub_vert0_result1)
  );

  fixed_point_subtractor fps5 (
      .a(x10),
      .b(x00),
      .result(sub_vert0_result2)
  );

  assign abs_vert0 = (x00 >= x10) ? sub_vert0_result1 : sub_vert0_result2;

  fixed_point_subtractor fps6 (
      .a(x01),
      .b(x11),
      .result(sub_vert1_result1)
  );

  fixed_point_subtractor fps7 (
      .a(x11),
      .b(x01),
      .result(sub_vert1_result2)
  );

  assign abs_vert1 = (x01 >= x11) ? sub_vert1_result1 : sub_vert1_result2;
  
  // Sum the absolute differences
  wire [31:0] sum_abs1; // 10-bit width to avoid overflow
  wire [31:0] sum_abs2;
  wire [31:0] sum_abs;

  fixed_point_adder fpa0 (abs_horiz0,abs_horiz1,sum_abs1);
  fixed_point_adder fpa1 (abs_vert0,abs_vert1,sum_abs2  );
  fixed_point_adder fpa2 (sum_abs1,sum_abs2,sum_abs     );  
  
  // Normalize by dividing the sum by 4 (right shift by 2)
  //assign pool_out = sum_abs / 4;
  assign pool_out = sum_abs >>> 2;  // Arithmetic right shift by 2

endmodule

module fixed_point_adder #(
    parameter WIDTH = 32,         // Total bit width
    parameter FRAC_BITS = 30       // Number of fractional bits
)(
    input wire [WIDTH-1:0] a,     // First operand
    input wire [WIDTH-1:0] b,     // Second operand
    output wire [WIDTH-1:0] result // Sum result
);
    // Simple addition - in fixed point we just add the binary representations
    // Overflow handling is not implemented here but could be added if needed
    assign result = a + b;
    
endmodule

module fixed_point_subtractor #(
    parameter WIDTH = 32,         // Total bit width
    parameter FRAC_BITS = 30       // Number of fractional bits
)(
    input wire [WIDTH-1:0] a,     // First operand (minuend)
    input wire [WIDTH-1:0] b,     // Second operand (subtrahend)
    output wire [WIDTH-1:0] result // Difference result
);
    // Simple subtraction - in fixed point we just subtract the binary representations
    // Underflow handling is not implemented here but could be added if needed
    assign result = a - b;
    
endmodule