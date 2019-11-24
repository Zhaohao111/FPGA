//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2 Beta
//Created Time: 2019-10-28 16:49:33
create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
//create_clock -name cam_pclk -period 20.833 -waveform {0 10.416} [get_ports {cam_pclk}]
