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

module bitwise_not #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a,
  output wire [WIDTH-1:0] a_not
);

  assign a_not = ~a;
endmodule

module comparator #(parameter WIDTH = 8) (
  input wire [WIDTH-1:0] a, b,
  output wire equal
);
  assign equal = (a == b);
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


module alu #(parameter WIDTH = 8, parameter OPCODE_WIDTH = 3) (
    input wire [WIDTH-1:0] a, b,
    input wire [OPCODE_WIDTH-1:0] opcode,
	output wire [WIDTH-1:0] result,
  	output wire equal_out, carry_out
);

    wire [WIDTH-1:0] result_add;
    wire [WIDTH-1:0] result_sub;
    wire [WIDTH-1:0] result_and;
    wire [WIDTH-1:0] result_or;
    wire [WIDTH-1:0] result_not;
    wire [WIDTH-1:0] result_l_shift;
    wire [WIDTH-1:0] result_r_shift;
  	 wire equal, carry;
 
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
  
    bitwise_not #(WIDTH) u_bitwise_not (
      a, result_not
    );
  
  comparator #(WIDTH) u_comparator (
      .a(a),
      .b(b),
      .equal(equal)
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

  assign  equal_out = (opcode == 3'b101) & equal ? 1'b1 : 1'b0;
  assign  carry_out = (opcode == 3'b000) & carry ? 1'b1 : 1'b0;
  
  assign result = (opcode == 3'b000) ? result_add :
                  (opcode == 3'b001) ? result_sub :
                  (opcode == 3'b010) ? result_and :
                  (opcode == 3'b011) ? result_or  :
                  (opcode == 3'b100) ? result_not :
                  (opcode == 3'b110) ? result_l_shift :
                  (opcode == 3'b111) ? result_r_shift :
                  {WIDTH{1'b0}};
endmodule
