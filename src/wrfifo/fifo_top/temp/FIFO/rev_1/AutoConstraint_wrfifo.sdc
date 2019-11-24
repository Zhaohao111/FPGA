
#Begin clock constraint
define_clock -name {wrfifo|WrClk} {p:wrfifo|WrClk} -period 4.822 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 2.411 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {wrfifo|RdClk} {p:wrfifo|RdClk} -period 5.254 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 2.627 -route 0.000 
#End clock constraint
