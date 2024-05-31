BSCFLAGS=-aggressive-conditions \
	-steps-warn-interval 6000000 -steps-max-intervals 9000000 \
	-opt-undetermined-vals -unspecified-to X +RTS -K100M -H100M -RTS

sim:
	bsc -verilog $(BSCFLAGS) -g mkTb -u -bdir obj -p +:../Cordic:../Constants Tb.bsv 
	bsc -verilog -e mkTb -bdir obj -o CostasLoop.exe -simdir obj_sim

hw:
	bsc -verilog $(BSCFLAGS) -g mkTb -u -bdir obj -p +:%/Libraries/FPGA/Misc/:../Cordic:../Constants Tb_Uart.bsv


clean:
	rm -f obj/*
	rm -f obj_sim/*
	rm -f *.exe*

