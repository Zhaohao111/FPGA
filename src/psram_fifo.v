
module psram_fifo(
    
    input                 sys_clk     ,  //系统时钟 50M
    input                 sys_rst_n   , //系统复位，低电平有效

//wrfifo interface 用户写端口
    input [15:0] Data_input_wrfifo ,      //写端口FIFO: 写数据
    input WrClk_wrfifo ,            //写端口FIFO: 写时钟
    input WrEn_wrfifo ,             //写端口FIFO: 写请求//CMOS图像数据采集模块//数据有效使能信号
    input             wr_load,           //写端口复位: 复位写地址,清空写FIFO 


//rdfifo interface 用户读端口
    input RdClk_rdfifo ,            //读端口FIFO: 读时钟
    input RdEn_rdfifo ,             //读端口FIFO: 读请求//VGA驱动模块 //请求像素点颜色数据输入
    input             rd_load,           //读端口复位: 复位读地址,清空读FIFO

    output [15:0] Data_Out_rdfifo,   //读端口FIFO: 读数据
    output psram_init_calib,          //psram初始化完成标志

	output     [1:0]    O_psram_ck     ,
	output     [1:0]    O_psram_ck_n   ,
	inout      [1:0]    IO_psram_rwds  ,
	inout      [15:0]   IO_psram_dq    ,
	output     [1:0]    O_psram_reset_n,
	output     [1:0]    O_psram_cs_n,  


    output lock_o
);

wire clkout_o_160M;
wire clk_use_psram;

//wire lock_o;
wire       wr_load_flag;                 //wr_load      上升沿标志位      
wire       rd_load_flag;                 //rd_load      上升沿标志位      


wire [63:0] psram_din;          //从wrfifo读出的数据，应写到psram中
wire [63:0] psram_dout;         //从psram读出的数据，应写到rdfifo中
wire rd_data_valid;      //psram读（输出）数据有效信号
wire [8:0] wrf_use;    /* synthesis syn_keep = 1 */                  //写端口FIFO中的数据量
wire [8:0] rdf_use;    /* synthesis syn_keep = 1 */                  //读端口FIFO中的数据量


wire [20:0] psram_addr ;  /* synthesis syn_keep = 1 */
reg [20:0] psram_wr_addr = 21'd0;  /* synthesis syn_preserve = 1 */
reg [20:0] psram_rd_addr = 21'd0;  /* synthesis syn_preserve = 1 */

reg cmd;           /* synthesis syn_preserve = 1 */ //命令通道:Read:1'b0     Write:1'b1
wire cmd_en;         //命令与地址使能信号：0：无效  1：有效
reg sw_bank_en;    /* synthesis syn_preserve = 1 */               //切换BANK使能信号
reg rw_bank_flag;  /* synthesis syn_preserve = 1 */               //读写bank的标志
reg Tcmd_end;      /* synthesis syn_preserve = 1 */  //Tcmd时间结束标志

reg cmd_en_delay1;
reg cmd_en_delay2;
reg cmd_delay1;
reg cmd_delay2;

parameter  wr_length = 7'd 64 ; //写突发长度
parameter  rd_length = 7'd 64 ; //读突发长度
parameter  Read = 1'b0;       //cmd 读命令
parameter  Write = 1'b1;      //cmd 写命令
parameter  wr_min_addr = 21'd0;
parameter  wr_max_addr = 21'd 393216;    //1024*768*16/32    //393216
parameter  rd_min_addr = 21'd0;
parameter  rd_max_addr = 21'd 393216;    //1024*768*16/32
parameter sdram_pingpang_en = 1'b1;       //使能乒乓操作
///////////////////////////////////////////////////////////////////////////////////
reg write_done_fla;      /* synthesis syn_preserve = 1 */
//reg read_done_flag;       /* synthesis syn_preserve = 1 */
wire read_done_flag;       /* synthesis syn_keep = 1 */

reg        wr_load_r1;                   //写端口复位寄存器      
reg        wr_load_r2;                   
reg        rd_load_r1;                   //读端口复位寄存器      
reg        rd_load_r2;                   

//同步写端口复位信号，用于捕获wr_load上升沿
always @(posedge clk_use_psram or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        wr_load_r1 <= 1'b0;
        wr_load_r2 <= 1'b0;
    end
    else begin
        wr_load_r1 <= wr_load;
        wr_load_r2 <= wr_load_r1;
    end
end

//同步读端口复位信号，同时用于捕获rd_load上升沿
always @(posedge clk_use_psram or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        rd_load_r1 <= 1'b0;
        rd_load_r2 <= 1'b0;
    end
    else begin
        rd_load_r1 <= rd_load;
        rd_load_r2 <= rd_load_r1;
    end
end

//检测上升沿
assign wr_load_flag    = ~wr_load_r2 & wr_load_r1;
assign rd_load_flag    = ~rd_load_r2 & rd_load_r1;

/////////////////////////////////////////////////////////////////////////////////////////////////////

//sdram写地址产生模块
always @(posedge clk_use_psram or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        psram_wr_addr <= 21'd0;
        sw_bank_en <= 1'b0;
        rw_bank_flag <= 1'b0;
    end
    else if(wr_load_flag) begin              //检测到写端口复位信号时，写地址复位
        psram_wr_addr <= wr_min_addr;   
        sw_bank_en <= 1'b0;
        rw_bank_flag <= 1'b0;
    end

    else if(write_done_fla) begin           //若突发写SDRAM结束，更改写地址/////////////////////////////////! ! ! ! ! ! ! ! !! !!!!!
                                             //若未到达写SDRAM的结束地址，则写地址累加
        if(sdram_pingpang_en) begin          //SDRAM 读写乒乓使能
            if((psram_wr_addr[19:0] < wr_max_addr - wr_length) )
                psram_wr_addr <= psram_wr_addr + wr_length;
            else begin                       //切换BANK
                rw_bank_flag <= ~rw_bank_flag;   
                sw_bank_en <= 1'b1;          //拉高切换BANK使能信号
            end            
        end       
                                             //若突发写SDRAM结束，更改写地址
        else if(psram_wr_addr < wr_max_addr - wr_length)
            psram_wr_addr <= psram_wr_addr + wr_length;
        else                                 //到达写SDRAM的结束地址，回到写起始地址
            psram_wr_addr <= wr_min_addr;
    end
    else if(sw_bank_en) begin                //到达写SDRAM的结束地址，回到写起始地址
        sw_bank_en <= 1'b0;
        if(rw_bank_flag == 1'b0)             //切换BANK
            psram_wr_addr <= {1'b0,wr_min_addr[19:0]};
        else
            psram_wr_addr <= {1'b1,wr_min_addr[19:0]};     
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//sdram读地址产生模块
always @(posedge clk_use_psram or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        psram_rd_addr <= 21'd0;
    end
 
    else if(rd_load_flag)                    //检测到读端口复位信号时，读地址复位
        psram_rd_addr <= rd_min_addr;

    else if(read_done_flag) begin            //突发读SDRAM结束，更改读地址
                                             //若未到达读SDRAM的结束地址，则读地址累加                 
        if(sdram_pingpang_en) begin          //SDRAM 读写乒乓使能  
            if((psram_rd_addr[19:0] < rd_max_addr - rd_length))
                psram_rd_addr <= psram_rd_addr + rd_length;
            else begin                       //到达读SDRAM的结束地址，回到读起始地址
                                             //读取没有在写数据的bank地址
                if(rw_bank_flag == 1'b0)     //根据rw_bank_flag的值切换读BANK地址
                    psram_rd_addr <= {1'b1,rd_min_addr[19:0]};
                else
                    psram_rd_addr <= {1'b0,rd_min_addr[19:0]};    
            end    
        end
                                             //若突发写SDRAM结束，更改写地址
        else if(psram_rd_addr < rd_max_addr - rd_length)  
            psram_rd_addr <= psram_rd_addr + rd_length;
        else                                 //到达写SDRAM的结束地址，回到写起始地址
            psram_rd_addr <= rd_min_addr;
    end
end
///////////////////////////////////////////////////////////////////////////////////
/*
always@(posedge clk_use_psram or negedge sys_rst_n) begin
    if(!sys_rst_n)
       psram_addr <= 21'd0; 
    else if(cmd_delay1)    
        psram_addr <= psram_wr_addr;
    else if(~cmd_delay1)
        psram_addr <= psram_rd_addr;
end
*/
assign psram_addr = cmd_delay2 ? psram_wr_addr  : psram_rd_addr;
//读写地址赋值块///////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////
reg temp_a;         /* synthesis syn_preserve = 1 */
reg temp_b;         /* synthesis syn_preserve = 1 */
reg s;              /* synthesis syn_preserve = 1 */
//psram 读写请求信号产生模块
always@(posedge clk_use_psram or negedge sys_rst_n) begin
    if(!sys_rst_n)begin 
            s <= s;
    end
    else if(psram_init_calib) begin       //SDRAM初始化完成后才能响应读写请求
                                         //优先执行写操作，防止写入SDRAM中的数据丢失
        if((wrf_use >= wr_length) && Tcmd_end) begin   //若写端口FIFO中的数据量达到了写突发长度
            cmd <= Write;           //发出写sdarm请求
            s <= ~s;
        end

        else if((rdf_use < rd_length)&& Tcmd_end) begin    //若读端口FIFO中的数据量小于读突发长度，
            cmd <= Read;                //发出读sdarm请求
            s <= ~s;
            end

        else begin
            s <= s;                   // 不使能读写信号              
        end
    end
    else begin                                                       
            s <= s;                  // 不使能读写信号 
    end
end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always@( posedge clk_use_psram)begin
    temp_a <= s;
end

assign cmd_en = temp_a ^ s;//cmd的上升下降都会生成脉冲
//assign a = ~temp_a & s;//S的上升会生成脉冲
//assign a = temp_a & ~s;//S的下降会生成脉冲


always@( posedge clk_use_psram or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        cmd_en_delay1 <= 1'b0;
        cmd_en_delay2 <= 1'b0;
    end
    else begin
       cmd_en_delay1 <= cmd_en; 
       cmd_en_delay2 <= cmd_en_delay1;
    end
end

always@( posedge clk_use_psram or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        cmd_delay1 <= 1'b0;
        cmd_delay2 <= 1'b0;
    end

    else begin
       cmd_delay1 <= cmd; 
       cmd_delay2 <= cmd_delay1;
    end
end

wire cmd_en_1clk;
always@( posedge clk_use_psram)begin
    temp_b <= cmd_en_delay2;
end

//assign cmd_en = temp_a ^ cmd_en_delay2;//cmd_en_delay2的上升下降都会生成脉冲
assign cmd_en_1clk = ~temp_b & cmd_en_delay2;//cmd_en_delay2的上升会生成脉冲
//assign a = temp_a & ~cmd_en_delay2;//cmd_en_delay2的下降会生成脉冲

reg temp_c;
wire cmd_en_1clk2;
always@( posedge clk_use_psram)begin
    temp_c <= cmd_en;
end

//assign cmd_en = temp_a ^ cmd_en_delay2;//cmd_en_delay2的上升下降都会生成脉冲
assign cmd_en_1clk2 = ~temp_c & cmd_en;//cmd_en的上升会生成脉冲
//assign a = temp_a & ~cmd_en_delay2;//cmd_en_delay2的下降会生成脉冲



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
parameter STAGE1 = 3'b 100;
parameter STAGE2 = 3'b 010;
parameter STAGE3 = 3'b 001;

reg [2:0]stage_buwr; /* synthesis syn_preserve = 1 */
reg [2:0]stage_burd; /* synthesis syn_preserve = 1 */
reg [5:0] cnt_wr;    /* synthesis syn_preserve = 1 */
reg psram_wr_ack;    /* synthesis syn_preserve = 1 */

always@(posedge clk_use_psram or negedge sys_rst_n)begin 
    if(!sys_rst_n)begin
        write_done_fla <= 1'b0;
        stage_buwr <= STAGE1;
        cnt_wr <= 6'd0;
        psram_wr_ack <= 1'b0;
    end
        
    else begin
        case(stage_buwr)
            STAGE1:
            begin
                write_done_fla <= 1'b0;
                if ((cmd == Write) && (cmd_en_1clk2 == 1'b1))begin    //说明写命令发出
                    stage_buwr <= STAGE2;                  //若写命令发出，到STAGE2计数
                    psram_wr_ack <= 1'b1;                 //psram写请求 ，传递给wrfifo读使能
                end
            end
            STAGE2:
            begin             
                cnt_wr <= cnt_wr + 1'b1;
                if(cnt_wr >= 6'd31)begin
                    cnt_wr <= 6'd0;
                    write_done_fla <= 1'b1;         // 一次突发写结束标志                
                    stage_buwr <= STAGE1;
                    psram_wr_ack <= 1'b0;            ////psram写请求 ，传递给wrfifo读使能

                end    
            end
            default:
            begin
                write_done_fla <= 1'b0;
                stage_buwr <= STAGE1;
                cnt_wr <= 6'd0;
            end
        endcase
    end
end


///////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////

reg temp_d;
always@( posedge clk_use_psram)begin
    temp_d <= rd_data_valid;
end

//assign cmd_en = temp_a ^ cmd_en_delay2;//cmd_en_delay2的上升下降都会生成脉冲
//assign rd_data_valid_1clk = ~temp_d & rd_data_valid;//cmd_en_delay2的上升会生成脉冲
assign read_done_flag = temp_d & ~rd_data_valid;//rd_data_valid的下降会生成脉冲


///////////////////////////////////////////////////////////////////////////////////

//cnt计数 突发长度128 命令间隔最小43个时钟周期
//cnt计数  Tcmd
reg [5:0] cnt_Tcmd;     /* synthesis syn_preserve = 1 */
reg [1:0] stage_Tcmd;   /* synthesis syn_preserve = 1 */

parameter STCNT = 2'b 10;
parameter WAIT_CMDEN_UP = 2'b 01;
always@(posedge clk_use_psram or negedge sys_rst_n)begin 
    if(!sys_rst_n) begin
        cnt_Tcmd <= 6'd0;
        Tcmd_end <= 1'b0;
        stage_Tcmd <= STCNT; 
    end
    else  begin
        case(stage_Tcmd)
            STCNT:
            begin
                Tcmd_end <= 1'b0;
                cnt_Tcmd <= cnt_Tcmd +1'b1;
                if (cnt_Tcmd == 6'd50)begin   //48      tufa64:45 160M
                    cnt_Tcmd <= 6'd0;
                    stage_Tcmd <= WAIT_CMDEN_UP;
                end
            end
            WAIT_CMDEN_UP:
            begin
                cnt_Tcmd <= 6'd0;
                Tcmd_end <= 1'b1;
                if(cmd_en == 1'b1)
                    stage_Tcmd <= STCNT; 
                    
            end  
            default:
            begin
                cnt_Tcmd <= 6'd0;
                Tcmd_end <= 1'b0;
                stage_Tcmd <= STCNT; 
            end
        endcase

    end
end

///////////////////////////////////////////////////////////////////////////////////

Gowin_PLL_160M Gowin_PLL_160M(
    .clkout(clkout_o_160M), //output clkout
    .lock(lock_o), //output lock
    .reset(~sys_rst_n), //input reset
    .clkin(sys_clk) //input clkin
);

PSRAM_Memory_Interface_Top PSRAM_Memory_Interface_Top(
  .clk(sys_clk),
  .memory_clk(clkout_o_160M),
  .pll_lock(lock_o),      //lock_o
  .rst_n(sys_rst_n),

  .O_psram_ck(O_psram_ck),
  .O_psram_ck_n(O_psram_ck_n),
  .IO_psram_dq(IO_psram_dq),
  .IO_psram_rwds(IO_psram_rwds),
  .O_psram_cs_n(O_psram_cs_n),
  .O_psram_reset_n(O_psram_reset_n),

  .wr_data(psram_din),             //写数据通道
  .rd_data(psram_dout),             //读数据通道
  .rd_data_valid(rd_data_valid),       //rd_data有效信号：0：无效      1：有效
  .addr(psram_addr),                //地址输入
  .cmd(cmd_delay2),                 //命令通道:read:1'b0     write:1'b1
  .cmd_en(cmd_en_1clk),              //命令与地址使能信号：0：无效     1：有效 
  .init_calib(psram_init_calib),          //psram初始化完成信号
  .data_mask(8'd0),            //掩码
  .clk_out(clk_use_psram)

);


//例化写端口FIFO
wrfifo u_wrfifo(
    //用户端口
  .Data(Data_input_wrfifo),   //写数据
  .WrClk(WrClk_wrfifo), //写时钟
  .WrEn(WrEn_wrfifo),   //写使能（请求）   ?????????

    //psram接口
  .RdClk(clk_use_psram), //读时钟   
  .RdEn(psram_wr_ack),   //读使能
  .Q(psram_din),                 //读数据

  .Rnum(wrf_use),              //rd端   FIFO中的数据量
  .Reset(~sys_rst_n | wr_load_flag)   //异步清零复位
//  .Wnum(),//没用
//  .Empty(),
//  .Full()
);


//例化读端口FIFO
rdfifo u_rdfifo(
    //psram端口
  .Data(psram_dout),  //写数据
  .WrClk(clk_use_psram),//写时钟
  .WrEn(rd_data_valid),   //写使能（请求）  ????????//psram读（输出）数据有效信号

    //用户端口
  .RdClk(RdClk_rdfifo), //读时钟
  .RdEn(RdEn_rdfifo),   //读使能      //VGA驱动模块 //请求像素点颜色数据输入
  .Q(Data_Out_rdfifo),  //读数据

  .Wnum(rdf_use),          //wr端  fifo中的数据量
  .Reset(~sys_rst_n | rd_load_flag)   //异步清零复位
//  .Rnum(),//没用
//  .Empty(),
//  .Full()
);





endmodule

