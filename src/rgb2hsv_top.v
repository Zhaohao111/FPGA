module rgb2hsv_top(  
    input clk,  
    input [15:0]RGB24, 
    output[15:0]HSV2,
    output [7:0] H,
    output [7:0] S,


    output [7:0] V 
);  

reg [7:0]max,min;  /* synthesis syn_preserve = 1 */
  
//input rgb  
wire [7:0] Red,Green,Blue;  /* synthesis syn_keep = 1 */
reg [7:0]R_reg,G_reg,B_reg;  /* synthesis syn_preserve = 1 */
wire [23:0]HSV24;           /* synthesis syn_keep = 1 */
assign Red = {RGB24[15:11],3'b0};  
assign Green = {RGB24[10:5],2'b0};  
assign Blue = {RGB24[4:0],3'b0};  


reg [7:0] Hue,Saturation,Value;   /* synthesis syn_preserve = 1 */

assign HSV24[23:16] = Hue;  
assign HSV24[15:8] = Saturation;  
assign HSV24[7:0] = Value;  

assign H = Hue;  
assign S = Saturation;  
assign V = Value; 

/*
assign H = Hue;  
assign S = Saturation;  
assign V = Value; 
*/
////////////////////////////////////////////////////////////////////////  


////////////////////////////////////////////////////////////////////////  


assign HSV2[15:11] = HSV24[23:19];  
assign HSV2[10:5] = HSV24[15:10];  
assign HSV2[4:0] = HSV24[7:3];    
  
always@(posedge clk)begin   
    R_reg <= Red;  
    G_reg <= Green;   
    B_reg <= Blue;  
end  
/*************find max,min***********/  
always@(posedge clk)begin  
 if(Red >= Green)  
   begin  
     if(Red >= Blue)  
     max <= Red;  
     else //r<b  
     max <= Blue;  
    end  
 else //r<g  
   begin   
    if(Green >= Blue)  
     max <= Green;  
     else //g<b  
     max <= Blue;  
    end   
end  
  
always@(posedge clk)begin  
 if(Red <= Green)  
   begin  
     if(Red <= Blue)  
     min <= Red;  
     else //r<b  
     min <= Blue;  
    end  
 else //r>g  
   begin   
    if(Green <= Blue)  
     min <= Green;  
     else //g>b  
     min <= Blue;  
    end   
end  
  
reg [14:0] h_dividend;      /* synthesis syn_preserve = 1 */
reg [7:0]  h_divisor;       /* synthesis syn_preserve = 1 */
wire [14:0] h_quotient;      /* synthesis syn_keep = 1 */
reg [8:0]  h_add;            /* synthesis syn_preserve = 1 */
reg [16:0]  s_dividend;      /* synthesis syn_preserve = 1 */
reg [7:0]  s_divisor;        /* synthesis syn_preserve = 1 */
wire [16:0]  s_quotient;      /* synthesis syn_keep = 1 */
reg [7:0]  v;                 /* synthesis syn_preserve = 1 */
reg sign_flag;               /* synthesis syn_preserve = 1 */
always@(posedge clk)begin  //按公式一步一步写，直接使用*/会消耗资源，但是效果挺好
 if(max == min)  
  begin  
   sign_flag <= 1'd0;  
   h_dividend <=15'd0;  
   h_divisor <= 8'd1;//  
   h_add <= 9'd0;  
   s_dividend <= 17'd0;  
   s_divisor <= 8'd1;  
    v <= max;  
  end  
 else if(max == R_reg && G_reg >= B_reg)  
  begin  
    sign_flag <= 1'd0;  
    h_dividend <= ((G_reg - B_reg)<<6) - ((G_reg - B_reg)<<2) ;  
//    h_dividend <= 60 * (G_reg - B_reg);  
    h_divisor <= max - min;  
    h_add <= 9'd0;  
    s_dividend <= ((max - min)<<8)-(max - min); 
//    s_dividend <= 255 * (max - min);   
    s_divisor <= max;   
    v <= max;  
  end  
 else if(max == R_reg && G_reg < B_reg )  
  begin  
   sign_flag <= 1'd1;  
   h_dividend <= ((B_reg - G_reg)<<6) - ((B_reg - G_reg)<<2);  
//   h_dividend <= 60 * (B_reg - G_reg);  
    h_divisor <= max - min;  
    h_add <= 9'd360;  
    s_dividend <= ((max - min)<<8)-(max - min);  
//    s_dividend <= 255 * (max - min);  
    s_divisor <= max;  
    v <= max;  
  end   
 else if(max == G_reg)  
  begin  
   if(B_reg >= R_reg)  
    begin  
    sign_flag <= 1'd0;  
    h_dividend <= ((B_reg - R_reg)<<6) - ((B_reg - R_reg)<<2);  
//    h_dividend <= 60 * (B_reg - R_reg);  
    end  
    else  
    begin   
    sign_flag <= 1'd1;  
    h_dividend <= ((R_reg - B_reg)<<6) - ((R_reg - B_reg)<<2);  
//    h_dividend <= 60 * (R_reg - B_reg);  
    end  
      
    h_divisor <= max - min;  
    h_add <= 9'd120;  
    s_dividend <= ((max - min)<<8)-(max - min); 
//    s_dividend <= 255 * (max - min) ;   
    s_divisor <= max;  
    v <= max;  
  end  
  else if(max == B_reg)  
  begin  
   if(R_reg >= G_reg)  
    begin  
    sign_flag <= 1'd0;  
    h_dividend <= ((R_reg - G_reg)<<6) -((R_reg - G_reg)<<2) ;  
//    h_dividend <= 60 * (R_reg - G_reg);  
    end  
    else  
    begin   
    sign_flag <= 1'd1;  
    h_dividend <= ((G_reg - R_reg)<<6) - ((G_reg - R_reg)<<2) ;  
//    h_dividend <= 60 * (G_reg - R_reg);  
    end  
      
    h_divisor <= max - min;  
    h_add <= 9'd240;  
    s_dividend <= ((max - min)<<8)-(max - min);  
//    s_dividend <= 255 * (max - min);  
    s_divisor <= max;  
    v <= max;  
  end  
end  

wire [16:0]yshang_h;
wire [16:0]yshang_s;    /* synthesis syn_keep = 1 */

assign h_quotient = yshang_h[14:0];  
assign s_quotient = yshang_s[16:0];  

//wire complete_s; /* synthesis syn_keep = 1 */
//wire complete_h; /* synthesis syn_keep = 1 */

Divider_Top Divider_Top_h(
  .dividend({2'd0,h_dividend}),
  .divisor({9'd0,h_divisor}),
  .start(1'b1),
  .clk(clk),
  .quotient_out(yshang_h),
  .complete(complete_h)
);
/*
div_rill u_div_h (  
    .a({17'b0,h_dividend}),   
    .b({24'b0,h_divisor}), 
	 .enable(1'b1),
    .yshang(yshang_h),   
    .yyushu()  
); 
*/

Divider_Top Divider_Top_s(
  .dividend(s_dividend),
  .divisor({9'd0,s_divisor}),
  .start(1'b1),
  .clk(clk),
  .quotient_out(yshang_s),
  .complete(complete_s)
);
/*
div_rill u_div_s (  
    .a({15'b0,s_dividend}),    
    .b({24'b0,s_divisor}),
	 .enable(1'b1),	 
    .yshang(yshang_s),   
    .yyushu()  
);  
 */ 
  
always@(posedge clk)begin  
    if(sign_flag == 1'd0)  
        Hue <= (h_quotient + h_add)>> 1;  
    else  
        Hue <= (h_add - h_quotient)>> 1;  
        Saturation <= s_quotient;  
        Value <= v;  
end  
/*
always@(posedge clk)begin  
    if(sign_flag == 1'd0)  
        Hue <= (h_quotient + h_add)/2;  
    else  
        Hue <= (h_add - h_quotient)/2;  
        Saturation <= s_quotient;  
        Value <= v;  
end  
*/
  
endmodule 

