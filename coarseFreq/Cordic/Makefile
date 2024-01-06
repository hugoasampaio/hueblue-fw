all:
	bsc -sim -g mkTb -u -bdir obj Tb.bsv 
	bsc -sim -e mkTb -bdir obj -o cordic.exe  -simdir obj_sim

clean:
	rm obj/*
	rm obj_sim/*
	rm *.exe

