BOARD=tangnano9k
#FAMILY=GW2A-18
#DEVICE=GW2A-LV18PG256C8/I7
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: uart_pnr.json

#synth
uart.json:
#	yosys -p "read_verilog /opt/bluespec/lib/Verilog/FIFO2.v; \
		read_verilog mm-limit/mkTb.v; \
		synth_gowin -json uart.json"
#	yosys -p "read_verilog /opt/bluespec/lib/Verilog/FIFO2.v; \
		read_verilog cl-636/mkRotate.v; \
		read_verilog cl-636/mkCostasLoopO.v; \
		read_verilog cl-636/mkTb.v; \
		synth_gowin -json uart.json"

#	yosys -p "read_verilog /opt/bluespec/lib/Verilog/FIFO2.v; \
		read_verilog dma-limit/mkTb.v; \
		synth_gowin -json uart.json"

#	yosys -p "read_verilog /opt/bluespec/lib/Verilog/FIFO2.v; \
		read_verilog dma-all12/mkRotate.v; \
		read_verilog dma-all12/mkCoarseFreqO.v; \
		read_verilog dma-all12/mkTb.v; \
		synth_gowin -json uart.json"
		
	yosys -p "read_verilog /opt/bluespec/lib/Verilog/FIFO2.v; \
		read_verilog cl-636/mkRotate.v; \
		read_verilog cl-636/mkCostasLoopO.v; \
		read_verilog cl-636/mkTb.v; \
		synth_gowin -retime -json uart.json "
	
# Place and Route
uart_pnr.json: uart.json
	nextpnr-gowin --json uart.json --write uart_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst --pre-pack pre-pack.py

# Generate Bitstream
uart.fs: uart_pnr.json
	gowin_pack -d ${FAMILY} -o uart.fs uart_pnr.json

clean:
	rm -f *.json
