
#Begin clock constraint
define_clock -name {ov5640_rgb565_1024x768_vga_top|sys_clk} {p:ov5640_rgb565_1024x768_vga_top|sys_clk} -period 3.305 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 1.652 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {Gowin_PLL|clkout_inferred_clock} {n:Gowin_PLL|clkout_inferred_clock} -period 8.588 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 4.294 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {_~psram_top_PSRAM_Memory_Interface_Top__|clk_out_inferred_clock} {n:_~psram_top_PSRAM_Memory_Interface_Top__|clk_out_inferred_clock} -period 5.771 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 2.885 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {ov5640_rgb565_1024x768_vga_top|cam_pclk} {p:ov5640_rgb565_1024x768_vga_top|cam_pclk} -period 5.780 -clockgroup Autoconstr_clkgroup_3 -rise 0.000 -fall 2.890 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {_~psram_top_PSRAM_Memory_Interface_Top__|clk_x2p_inferred_clock} {n:_~psram_top_PSRAM_Memory_Interface_Top__|clk_x2p_inferred_clock} -period 66667.000 -clockgroup Autoconstr_clkgroup_4 -rise 0.000 -fall 33333.500 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {i2c_dri_Z1|dri_clk_derived_clock} {n:i2c_dri_Z1|dri_clk_derived_clock} -period 28417.432 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 14208.716 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {_~psram_wd_PSRAM_Memory_Interface_Top__|step_derived_clock[0]} {n:_~psram_wd_PSRAM_Memory_Interface_Top__|step_derived_clock[0]} -period 19095.151 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 9547.575 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {_~psram_init_PSRAM_Memory_Interface_Top__|VALUE_1_derived_clock[0]} {n:_~psram_init_PSRAM_Memory_Interface_Top__|VALUE_1_derived_clock[0]} -period 19095.151 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 9547.575 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {_~psram_init_PSRAM_Memory_Interface_Top__|VALUE_1_derived_clock[1]} {n:_~psram_init_PSRAM_Memory_Interface_Top__|VALUE_1_derived_clock[1]} -period 19095.151 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 9547.575 -route 0.000 
#End clock constraint
