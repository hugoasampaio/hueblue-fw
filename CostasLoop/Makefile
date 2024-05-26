BSCFLAGS=-aggressive-conditions \
	-steps-warn-interval 6000000 -steps-max-intervals 9000000 \
	-opt-undetermined-vals -unspecified-to X +RTS -K100M -H100M -RTS

sim:
	bsc -sim $(BSCFLAGS) -g mkTb -u -bdir obj -p .:%/Libraries:../Cordic:../Constants Tb.bsv 
	bsc -sim -e mkTb -bdir obj -o CostasLoop.exe -simdir obj_sim

vhdl:
	bsc -verilog $(BSCFLAGS) -u -bdir obj  -p +:../Cordic:../Constants -show-module-use Tb_tang.bsv
	bsc -verilog -e mkTb -bdir obj -p +:../Cordic 

clean:
	rm -f obj/*
	rm -f obj_sim/*
	rm -f *.exe*

