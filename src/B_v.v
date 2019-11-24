module B_v(
	input clk,
	input sys_rst_n,
	input [7:0]H,
	input [7:0]S,
	input [7:0]V,
	output reg [15:0]VGA_out
);

	
/*
always @(posedge clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
         VGA_out <= 16'd0;                                  
    else begin
        if(H >=8'd26 && H <= 8'd34 && S >= 8'd100 &&S <= 8'd255 && V >= 8'd100 && V <= 8'd255)  
            VGA_out <= 16'b1111_1111_1111_1111;   
        else 
            VGA_out <= 16'b0;  
    end
end
*/
always @(posedge clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
         VGA_out <= 16'd0;                                  
    else begin
        if( (H >8'd0 && H< 8'd4 && S>43 &&S < 255 && V > 8'd46 && V< 8'd255)||(H >8'd156 && H< 8'd180 && S>43 &&S < 255 && V > 8'd46 && V< 8'd255))                                               
 //     if( ( H >=8'd0 && H <= 8'd10 && S >= 43 &&S <= 255 && V >= 8'd46 && V <= 8'd255)||(H >= 8'd156 && H <= 8'd180 && S >= 43 &&S <= 255 && V >= 8'd46 && V <= 8'd255))                                                                                           
            VGA_out <= 16'b1111_1111_1111_1111;   
        else 
            VGA_out <= 16'b0;  
    end
end



endmodule 

