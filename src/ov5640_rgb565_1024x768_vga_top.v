

module ov5640_rgb565_1024x768_vga_top(    
    input                 sys_clk     ,  //系统时钟
    input                 sys_rst_n   ,  //系统复位，低电平有效
    //摄像头接口
    input                 cam_pclk    ,  //cmos 数据像素时钟
    input                 cam_vsync   ,  //cmos 场同步信号
    input                 cam_href    ,  //cmos 行同步信号
    input        [7:0]    cam_data    ,  //cmos 数据  
    output                cam_rst_n   ,  //cmos 复位信号，低电平有效
    output                cam_pwdn    ,  //cmos 电源休眠模式选择信号
    output                cam_scl     ,  //cmos SCCB_SCL线
    inout                 cam_sda     ,  //cmos SCCB_SDA线
/*    //SDRAM接口
    output                sdram_clk   ,  //SDRAM 时钟
    output                sdram_cke   ,  //SDRAM 时钟有效
    output                sdram_cs_n  ,  //SDRAM 片选
    output                sdram_ras_n ,  //SDRAM 行有效
    output                sdram_cas_n ,  //SDRAM 列有效
    output                sdram_we_n  ,  //SDRAM 写有效
    output       [1:0]    sdram_ba    ,  //SDRAM Bank地址
    output       [1:0]    sdram_dqm   ,  //SDRAM 数据掩码
    output       [12:0]   sdram_addr  ,  //SDRAM 地址
    inout        [15:0]   sdram_data  ,  //SDRAM 数据 
*/   
    //VGA接口                          
    output                vga_hs      ,  //行同步信号
    output                vga_vs      ,  //场同步信号
    output        [15:0]  vga_rgb     ,  //红绿蓝三原色输出 

    output          GM7123_sync_clk ,
    output          blk ,            //消隐

	output     [1:0]    O_psram_ck     ,
	output     [1:0]    O_psram_ck_n   ,
	inout      [1:0]    IO_psram_rwds  ,
	inout      [15:0]   IO_psram_dq    ,
	output     [1:0]    O_psram_reset_n,
	output     [1:0]    O_psram_cs_n,   

//    output  led_test,
    output  reg led1,
    output  reg led2
   
//    output led_test1,
 //   output led_test2,
 //   output reg led_test3


    );

//parameter define
parameter  SLAVE_ADDR = 7'h3c         ;  //OV5640的器件地址7'h3c
parameter  BIT_CTRL   = 1'b1          ;  //OV5640的字节地址为16位  0:8位 1:16位
parameter  CLK_FREQ   = 26'd65_000_000;  //i2c_dri模块的驱动时钟频率 65MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
parameter  CMOS_H_PIXEL = 24'd1024    ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
parameter  CMOS_V_PIXEL = 24'd768     ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小

//wire define
wire                  clk_65m         ;  //65mhz时钟,提供给IIC驱动时钟和vga驱动时钟
wire                  locked          ;
wire                  rst_n           ;

wire                  i2c_exec        ;  //I2C触发执行信号
wire   [23:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟
                                      
wire                  wr_en           ;  //sdram_ctrl模块写使能
wire   [15:0]         wr_data         ;  //sdram_ctrl模块写数据
wire                  rd_en           ;  //sdram_ctrl模块读使能
wire   [15:0]         rd_data         ;  //sdram_ctrl模块读数据
wire                  psram_init_calib ;  //PSRAM初始化完成标志
wire                  sys_init_done   ;  //系统初始化完成(psram初始化+摄像头初始化)
//wire         GM7123_sync_clk; 


assign GM7123_sync_clk = clk_65m ;
assign blk = 1'b1;


wire [7:0]H;
wire [7:0]S;
wire [7:0]V;

//*****************************************************
//**                    main code
//*****************************************************

assign  rst_n = sys_rst_n & locked;
//系统初始化完成：SDRAM和摄像头都初始化完成
//避免了在SDRAM初始化过程中向里面写入数据
assign  sys_init_done = psram_init_calib & cam_init_done;

//assign  sys_init_done = cam_init_done;

//不对摄像头硬件复位,固定高电平
assign  cam_rst_n = 1'b1;
//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn = 1'b0;

//锁相环
//pll_clk u_pll_clk(
//    .areset             (~sys_rst_n),
//   .inclk0             (sys_clk),
//    .c0                 (clk_100m),
//    .c1                 (clk_100m_shift),
//    .c2                 (clk_65m),
//    .locked             (locked)
//    );

Gowin_PLL Gowin_PLL_65M(
    .clkout(clk_65m),            //VGA  CLK
    .lock(locked), 
    .reset(~sys_rst_n), 
    .clkin(sys_clk)
);



//I2C配置模块
i2c_ov5640_rgb565_cfg 
   #(
     .CMOS_H_PIXEL      (CMOS_H_PIXEL),
     .CMOS_V_PIXEL      (CMOS_V_PIXEL)
    )   
   u_i2c_cfg(   
    .clk                (i2c_dri_clk),
    .rst_n              (rst_n),
    .i2c_done           (i2c_done),
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .init_done          (cam_init_done)
    );                                         

//I2C驱动模块
i2c_dri 
   #(
    .SLAVE_ADDR         (SLAVE_ADDR),       //参数传递
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  )                
    )   
   u_i2c_dri(   
    .clk                (clk_65m   ),
    .rst_n              (rst_n     ),   
        
    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (1'b0),             //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr           (i2c_data[23:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (),   
    .i2c_done           (i2c_done  ),   
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   
        
    .dri_clk            (i2c_dri_clk)       //I2C操作时钟
);

//reg frame_val_flag;
//CMOS图像数据采集模块
wire cmos_frame_vsync;
wire cmos_frame_href;

cmos_capture_data u_cmos_capture_data(  //系统初始化完成之后再开始采集数据 
    .rst_n              (rst_n & sys_init_done),//    .rst_n              (rst_n & sys_init_done), 
        
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),
        
        
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href),
    .cmos_frame_valid   (wr_en),       //数据有效使能信号
    .cmos_frame_data    (wr_data)      //有效数据 
//    .frame_val_flag (frame_val_flag)
//  .led_test

    );

/*
//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
    .ref_clk            (clk_100m),                   //sdram 控制器参考时钟
    .out_clk            (clk_100m_shift),             //用于输出的相位偏移时钟
    .rst_n              (rst_n),                      //系统复位
                                                        
    //用户写端口                                        
    .wr_clk             (cam_pclk),                   //写端口FIFO: 写时钟
    .wr_en              (wr_en),                      //写端口FIFO: 写使能
    .wr_data            (wr_data),                    //写端口FIFO: 写数据
    .wr_min_addr        (24'd0),                      //写SDRAM的起始地址
    .wr_max_addr        (CMOS_H_PIXEL*CMOS_V_PIXEL),  //写SDRAM的结束地址
    .wr_len             (10'd512),                    //写SDRAM时的数据突发长度
    .wr_load            (~rst_n),                     //写端口复位: 复位写地址,清空写FIFO
                                                        
    //用户读端口                                        
    .rd_clk             (clk_65m),                    //读端口FIFO: 读时钟
    .rd_en              (rd_en),                      //读端口FIFO: 读使能
    .rd_data            (rd_data),                    //读端口FIFO: 读数据
    .rd_min_addr        (24'd0),                      //读SDRAM的起始地址
    .rd_max_addr        (CMOS_H_PIXEL*CMOS_V_PIXEL),  //读SDRAM的结束地址
    .rd_len             (10'd512),                    //从SDRAM中读数据时的突发长度
    .rd_load            (~rst_n),                     //读端口复位: 复位读地址,清空读FIFO
                                                
    //用户控制端口                                
    .sdram_read_valid   (1'b1),                       //SDRAM 读使能
    .sdram_pingpang_en  (1'b1),                       //SDRAM 乒乓操作使能
    .sdram_init_done    (sdram_init_done),            //SDRAM 初始化完成标志
                                                
    //SDRAM 芯片接口                                
    .sdram_clk          (sdram_clk),                  //SDRAM 芯片时钟
    .sdram_cke          (sdram_cke),                  //SDRAM 时钟有效
    .sdram_cs_n         (sdram_cs_n),                 //SDRAM 片选
    .sdram_ras_n        (sdram_ras_n),                //SDRAM 行有效
    .sdram_cas_n        (sdram_cas_n),                //SDRAM 列有效
    .sdram_we_n         (sdram_we_n),                 //SDRAM 写有效
    .sdram_ba           (sdram_ba),                   //SDRAM Bank地址
    .sdram_addr         (sdram_addr),                 //SDRAM 行/列地址
    .sdram_data         (sdram_data),                 //SDRAM 数据
    .sdram_dqm          (sdram_dqm)                   //SDRAM 数据掩码
    );
*/

////////////////////////////////////////////////////////////////////////

wire lock_o;

psram_fifo psram_fifo(
    
    .sys_clk  (sys_clk)   ,  //系统时钟 50M
    .sys_rst_n  (rst_n) , //系统复位，低电平有效

//wrfifo interface 用户写端口
    .Data_input_wrfifo(wr_data) ,      //写端口FIFO: 写数据
    .WrClk_wrfifo(cam_pclk) ,            //写端口FIFO: 写时钟
    .WrEn_wrfifo(wr_en) ,             //写端口FIFO: 写请求//CMOS图像数据采集模块//数据有效使能信号
    .wr_load(~rst_n),

//rdfifo interface 用户读端口
    .RdClk_rdfifo(clk_65m) ,            //读端口FIFO: 读时钟
    .RdEn_rdfifo(rd_en) ,             //读端口FIFO: 读请求//VGA驱动模块 //请求像素点颜色数据输入
    .Data_Out_rdfifo(rd_data),   //读端口FIFO: 读数据
    .rd_load(~rst_n),

    .psram_init_calib(psram_init_calib),

      .O_psram_ck(O_psram_ck),
      .O_psram_ck_n(O_psram_ck_n),
      .IO_psram_dq(IO_psram_dq),
      .IO_psram_rwds(IO_psram_rwds),
      .O_psram_cs_n(O_psram_cs_n),
      .O_psram_reset_n(O_psram_reset_n),

    .lock_o(lock_o)

);





///////////////////////////////////////////////////////////////////////
//VGA驱动模块
wire [15:0]vga_driver_output;
wire vga_en;
wire [10:0]x;
wire [10:0]y;
wire [10:0]cnt_h;
wire [10:0]cnt_v;

wire vga_hs_d0,vga_vs_d0,vga_en_d0;

vga_driver u_vga_driver(
    .vga_clk            (clk_65m),    
    .sys_rst_n          (rst_n & sys_init_done),    
    
    .vga_hs             (vga_hs_d0),       
    .vga_vs             (vga_vs_d0),       
    .vga_rgb            (vga_driver_output),      
        
    .pixel_data         (rd_data), 
    .data_req           (rd_en),                      //请求像素点颜色数据输入
    .pixel_xpos         (x), 
    .pixel_ypos         (y),
    .cnt_h(cnt_h),
    .cnt_v(cnt_v),

    .vga_en(vga_en_d0)

    ); 

RAM_based_shift_reg_top_sync RAM_based_shift_reg_top_sync_hs16(
  .clk(clk_65m),
  .Reset(~rst_n),
  .Din(vga_hs_d0),
  .Q(vga_hs)
);

RAM_based_shift_reg_top_sync RAM_based_shift_reg_top_sync_vs16(
  .clk(clk_65m),
  .Reset(~rst_n),
  .Din(vga_vs_d0),
  .Q(vga_vs)
);

RAM_based_shift_reg_top_sync RAM_based_shift_reg_top_sync_vgaen16(
  .clk(clk_65m),
  .Reset(~rst_n),
  .Din(vga_en_d0),
  .Q(vga_en)
);





///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////TEST
//assign led_test1 = ~cam_pclk;
//assign led_test2 = cam_pclk;
//assign led_test3 = sys_clk;

always@(posedge sys_clk)begin
    if (psram_init_calib)begin
        led1 <= 1'b0;
        led2 <= 1'b1;
        end
    else if (~psram_init_calib)begin
        led1 <= 1'b1;
        led2 <= 1'b0;
    end
end
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////算法处理算法处理算法处理算法处理


rgb2hsv_top rgb2hsv_top1(  
    .clk(clk_65m),  
    .RGB24(vga_driver_output),   //wr_data
    .HSV2(  ),   //一般没用
    .H(H),
    .S(S),
    .V(V)
); 

wire [0:0] B_v_output;
B_v B_v(
        .clk(clk_65m),
        .sys_rst_n(sys_rst_n),
        .H(H),
        .S(S),
        .V(V),
        .VGA_out(B_v_output)
); 

wire	post2_frame_vsync;
wire	post2_frame_href;
wire	post2_frame_clken;
wire	post2_img_Bit;
/*
VIP_Bit_Erosion_Detector VIP_Bit_Erosion_Detector
(
	//global clock
	.clk(cam_pclk),  				//cmos video pixel clock
	.rst_n(sys_rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync(cmos_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href(cmos_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken(wr_en),	//Prepared Image data output/capture enable clock
	.per_img_Bit(B_v_output),		//Prepared Image Bit flag outout(1: Value, 0:inValid)
	
	//Image data has been processd
	.post_frame_vsync(post2_frame_vsync),	//Processed Image data vsync valid signal
	.post_frame_href(post2_frame_href),	//Processed Image data href vaild  signal
	.post_frame_clken(post2_frame_clken),	//Processed Image data output/capture enable clock
	.post_img_Bit(post2_img_Bit)		//Processed Image Bit flag outout(1: Value, 0:inValid)
);
*/
wire	[15:0]	rgb;
assign vga_rgb = {16{B_v_output}};

wire [10:0] x_min,x_max,y_min,y_max;
shibie shibie_1
(
	.clk(clk_65m),
	.rst_n(sys_rst_n),

	.Gray(rgb),//输入灰度颜色，RGB2HSV，B_V
	.data_vaild(wr_en),

	.x_min(x_min),
    .x_max(x_max),
    .y_min(y_min),
    .y_max(y_max)
);

VGA_OUT	VGA_OUT_1
(
	.clk(clk_65m),
	.rst_n(),
	.x_min(x_min),
	.x_max(x_max),
	.y_min(y_min),
	.y_max(y_max),
	.x(x),
	.y(y),
	.hcnt(cnt_h),
    .vcnt(cnt_v),
	.data_in(rd_data),
	.en(),
	.VGA_RGB(vga_rgb)
);







endmodule 


