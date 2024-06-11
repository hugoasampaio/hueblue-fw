BSCFLAGS=-aggressive-conditions \
	-steps-warn-interval 6000000 -steps-max-intervals 9000000 \
	-opt-undetermined-vals -unspecified-to X +RTS -K100M -H100M -RTS 

all:
	bsc -sim $(BSCFLAGS) -g mkTb -u -bdir obj -p +:../Cordic:../Constants Tb.bsv 
	bsc -sim -e mkTb -bdir obj -o coarseFreq.exe  -simdir obj_sim

clean:
	rm -f obj/*
	rm -f obj_sim/*
	rm -f *.exe*

