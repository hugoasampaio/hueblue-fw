all:
	bsc -sim -g mkTb -u -bdir obj -p .:%/Prelude:%/Libraries:../Cordic Tb.bsv 
	bsc -sim -e mkTb -bdir obj -o coarseFreq.exe  -simdir obj_sim

clean:
	rm obj/*
	rm obj_sim/*
	rm *.exe

