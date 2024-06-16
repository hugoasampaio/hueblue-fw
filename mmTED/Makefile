BSCFLAGS=-aggressive-conditions \
	-steps-warn-interval 6000000 -steps-max-intervals 9000000 \
	-opt-undetermined-vals -unspecified-to X +RTS -K100M -H100M -RTS

sim:
	bsc -sim $(BSCFLAGS) -g mkTb -u -bdir obj -p +:../Constants Tb_python_limited.bsv 
	bsc -sim -e mkTb -bdir obj -o mmTED.exe -simdir obj_sim

hw_limited:
	bsc -verilog $(BSCFLAGS) -g mkTb -u -bdir obj -show-module-use \
	-p +:%/Libraries/FPGA/Misc/:../Constants Tb_Uart_limited.bsv
	mv mkTb.v mmted-limited-v2.2.v

hw_all12:
	bsc -verilog $(BSCFLAGS) -g mkTb -u -bdir obj -show-module-use \
	-p +:%/Libraries/FPGA/Misc/:../Constants Tb_Uart_all12.bsv
	mv mkTb.v mmted-all12-v2.2.v
	
hw_opt:
	bsc -verilog $(BSCFLAGS) -g mkTb -u -bdir obj -show-module-use \
	-p +:%/Libraries/FPGA/Misc/:../Constants Tb_Uart_optimal.bsv
	mv mkTb.v mmted-optimal-v2.1.v

clean:
	rm -f obj/*
	rm -f obj_sim/*
	rm -f *.exe*

