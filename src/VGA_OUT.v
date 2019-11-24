module VGA_OUT
(
	input clk,
	input rst_n,
	input [10:0] x_min,
	input [10:0] x_max,
	input [10:0] y_min,
	input [10:0] y_max,
	input [10:0] x,
	input [10:0] y,
	input [10:0] hcnt,
   input [10:0] vcnt,
	input	[15:0] data_in,
//	input en,
	output en,
	output	reg [15:0]VGA_RGB
);

parameter  H_SYNC   =  11'd136;   //行同步     
parameter  H_BACK   =  11'd160;   //行显示后沿
parameter  H_DISP   =  12'd1024;  //行有效数据
parameter  H_FRONT  =  11'd24;    //行显示前沿
parameter  H_TOTAL  =  12'd1344;  //行扫描周期  注意位宽长度,需要11位的位宽

parameter  V_SYNC   =  11'd6;     //场同步
parameter  V_BACK   =  11'd29;    //场显示后沿
parameter  V_DISP   =  12'd768;   //场有效数据
parameter  V_FRONT  =  11'd3;     //场显示前沿
parameter  V_TOTAL  =  12'd806;   //场扫描周期


assign en  = (((hcnt >= H_SYNC+H_BACK) && (hcnt < H_SYNC+H_BACK+H_DISP))
                 &&((vcnt >= V_SYNC+V_BACK) && (vcnt < V_SYNC+V_BACK+V_DISP)))
                 ?  1'b1 : 1'b0;
					
						
						
always @(posedge clk)begin
    if(y == y_max && x >= x_min && x <= x_max)
        VGA_RGB <= 16'b11111_000000_00000;
    else if(x == x_min && y >= y_min && y <= y_max)
        VGA_RGB <= 16'b11111_000000_00000;
    else if(x == x_max && y >= y_min && y <= y_max)
        VGA_RGB <= 16'b11111_000000_00000;
    else if(y == y_min && x >= x_min && x <= x_max)
        VGA_RGB <= 16'b11111_000000_00000;
    else if(en)
        VGA_RGB <= data_in;
    else 
        VGA_RGB <= 0;
end

endmodule 
