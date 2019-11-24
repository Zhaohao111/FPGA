module shibie
(
	input clk,
	input rst_n,

	input [15:0] Gray,//输入灰度颜色，RGB2HSV，B_V
	input	data_vaild,

	output  reg [10:0]  x_min,
    output  reg [10:0]  x_max,
    output  reg [10:0]  y_min,
    output  reg [10:0]  y_max
);

parameter ROW_CNT = 1024;
parameter COL_CNT = 768;

reg [10:0]	cnt_x;
reg [10:0]	cnt_y;

wire	row_flag;
wire	flag;

assign flag = (cnt_x == 1 && cnt_y == 1)? 1'b1:1'b0;

always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        cnt_x <= 0;
    end
    else if(data_vaild && cnt_x == ROW_CNT - 1)
        cnt_x <= 0;
    else if(data_vaild)begin
        cnt_x <= cnt_x + 1'b1;
    end
    else 
        cnt_x <= cnt_x;
end
assign  row_flag = (data_vaild && cnt_x == ROW_CNT - 1'b1)? 1'b1:1'b0;
//cnt_y
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        cnt_y <= 0;
    end
    else if(row_flag  &&  cnt_y == COL_CNT - 1'b1)
        cnt_y <= 0;
    else if(row_flag)begin
        cnt_y <= cnt_y + 1'b1;
    end
    else 
        cnt_y <= cnt_y;
end

//-------------------------------------------------------
//x_min lag 2clk
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        x_min <= ROW_CNT;
    end
    else if(flag)
        x_min <= ROW_CNT;
    else if(data_vaild && Gray == 16'b1111_1111_1111_1111 && x_min > cnt_x)
        x_min <= cnt_x;
    else 
        x_min <= x_min;
end
//x_max
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        x_max <= 0;
    end
    else if(flag)
        x_max <= 0;
    else if(data_vaild && Gray == 16'b1111_1111_1111_1111 && x_max < cnt_x)
        x_max <= cnt_x;
    else 
        x_max <= x_max;
end
//y_min
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        y_min <= COL_CNT;
    end
    else if(flag)
        y_min <= COL_CNT;
    else if(data_vaild && Gray == 16'b1111_1111_1111_1111 && y_min > cnt_y)
        y_min <= cnt_y;
    else 
        y_min <= y_min;
end
//y_max
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        y_max <= 0;
    end
    else if(flag)
        y_max <= 0;
    else if(data_vaild && Gray == 16'b1111_1111_1111_1111 && y_max < cnt_y)
        y_max <= cnt_y;
    else 
        y_max <= y_max;
end

endmodule