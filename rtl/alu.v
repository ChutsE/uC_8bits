module adder #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire [WIDTH-1:0] sum,
  output wire co
);
  wire [WIDTH:0] result;
  assign result = a + b;
  assign co = result[WIDTH];
  assign sum = result[WIDTH-1:0];
endmodule

module subtractor #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire [WIDTH-1:0] diff
);

  assign diff = a - b;
endmodule

module bitwise_and #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire [WIDTH-1:0] b_and
);

  assign b_and = a & b;
endmodule

module bitwise_or #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire [WIDTH-1:0] b_or
);

  assign b_or = a | b;
endmodule

module bitwise_xor #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire [WIDTH-1:0] b_xor
);

  assign b_xor = a ^ b;
endmodule

module comparator #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire a_greater, a_equal
);
  assign a_greater = (a > b);
  assign a_equal = (a == b);
endmodule

module left_shift #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] shift,
  output wire [WIDTH-1:0] left_shift
);
  assign left_shift = (a << shift);
endmodule

module right_shift #(parameter WIDTH = 8)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] shift,
  output wire [WIDTH-1:0] right_shift
);
  assign right_shift = (a >> shift);
endmodule


module alu (
    input wire [7:0] a, b,
    input wire [2:0] opcode,
	  output wire [7:0] result,
  	output wire a_greater_out, a_equal_out, carry_out
);
    parameter WIDTH = 8;
    wire [WIDTH-1:0] result_add;
    wire [WIDTH-1:0] result_sub;
    wire [WIDTH-1:0] result_and;
    wire [WIDTH-1:0] result_or;
    wire [WIDTH-1:0] result_xor;
    wire [WIDTH-1:0] result_l_shift;
    wire [WIDTH-1:0] result_r_shift;
  	 wire a_greater, a_equal, carry;
 
  	adder #(WIDTH) u_adder (
      a, b, result_add, carry
    );
  
    subtractor #(WIDTH) u_subtractor (
      a, b, result_sub
    );
  
 	 bitwise_and #(WIDTH) u_bitwise_and (
      a, b, result_and
     );
  
  	bitwise_or #(WIDTH) u_bitwise_or (
      a, b, result_or
    );
  
    bitwise_xor #(WIDTH) u_bitwise_xor(
      a, b, result_xor
    );
  
  comparator #(WIDTH) u_comparator (
      .a(a),
      .b(b),
      .a_greater(a_greater),
      .a_equal(a_equal)
  	);
  
    left_shift #(WIDTH) u_left_shift (
      .a(a),
      .shift(b),
      .left_shift(result_l_shift)
    );
  
    right_shift #(WIDTH) u_right_shift (
      .a(a),
      .shift(b),
      .right_shift(result_r_shift)
    );

  assign  a_greater_out = (opcode == 3'b101) & a_greater ? 1'b1 : 1'b0;
  assign  a_equal_out = (opcode == 3'b101) & a_equal ? 1'b1 : 1'b0;
  assign  carry_out = (opcode == 3'b000) & carry ? 1'b1 : 1'b0;
  
  assign result = (opcode == 3'b000) ? result_add :
                  (opcode == 3'b001) ? result_sub :
                  (opcode == 3'b010) ? result_and :
                  (opcode == 3'b011) ? result_or :
                  (opcode == 3'b100) ? result_xor :
						(opcode == 3'b110) ? result_l_shift :
						(opcode == 3'b111) ? result_r_shift :
						{WIDTH{1'b0}};
endmodule
