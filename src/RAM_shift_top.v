module RAM_shift_top(

	input clock,
	input clken,	//pixel enable clock
//	.aclr		(1'b0),
	input shiftin,	//Current data input

	output taps0x,	//Last row data
	output taps1x,	//Up a row data
	output shiftout 
);

wire clk;
assign clk = clken ? clock : 1'b0;

RAM_based_shift_reg_top taps0x1(
  .clk(clk),
  .Reset(1'b0),
  .Din(shiftin),
  .Q(taps0x)
);


RAM_based_shift_reg_top taps1x1(
  .clk(clk),
  .Reset(1'b0),
  .Din(taps0x),
  .Q(taps1x)
);



endmodule
