BSCFLAGS=-aggressive-conditions \
	-steps-warn-interval 6000000 -steps-max-intervals 9000000 \
	-opt-undetermined-vals -unspecified-to X +RTS -K100M -H100M -RTS

sim:
	bsc -sim $(BSCFLAGS) -g mkTb -u -bdir obj -p .:%/Libraries:../Constants Tb.bsv 
	bsc -sim -e mkTb -bdir obj -o mmTED.exe -simdir obj_sim


vhdl:
	bsc -verilog $(BSCFLAGS) -u -bdir obj  -p +:../Constants Tb_tang.bsv
	bsc -verilog -e mkTb -bdir obj

clean:
	rm -f obj/*
	rm -f obj_sim/*
	rm -f *.exe*

