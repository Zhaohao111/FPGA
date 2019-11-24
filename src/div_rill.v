module div_rill  
(  
    input[31:0] a,   
    input[31:0] b,  
    input enable,
    output reg [31:0] yshang,  
    output reg [31:0] yyushu
);  
  
reg[31:0] tempa;  /* synthesis syn_preserve = 1 */
reg[31:0] tempb;  /* synthesis syn_preserve = 1 */
reg[63:0] temp_a;  /* synthesis syn_preserve = 1 */
reg[63:0] temp_b;  /* synthesis syn_preserve = 1 */
  
integer i;  
  
always @(a or b) begin  
    tempa <= a;  
    tempb <= b;  
end  
  
always @(tempa or tempb) begin  
if(enable) begin
    temp_a = {32'h00000000,tempa};  
    temp_b = {tempb,32'h00000000};  
    for(i = 0;i < 32;i = i + 1) begin  : abcdefg
        temp_a = {temp_a[62:0],1'b0};  
        if(temp_a[63:32] >= tempb)  
            temp_a = temp_a - temp_b + 1'b1;  
        else  
            temp_a = temp_a;  
    end  
    yshang = temp_a[31:0];  
    yyushu = temp_a[63:32]; 
  end
end  
  
endmodule
