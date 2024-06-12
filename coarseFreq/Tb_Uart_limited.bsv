package Tb_Uart_limited;

import CoarseFreq_limited::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;
import RS232::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;
import Connectable::*;

interface UartIface;
    interface RS232 rs232;
    interface Reset rs232_rst;    
endinterface

(* synthesize *)
module mkTb#(Clock clk_uart) (UartIface);
    IWithCBus#(LimitedCoarseFreq, CoarseFreq_IFC) coarseFreq <- exposeCBusIFC(mkCoarseFreq);
    //UART
    Reset rst_uart <- mkAsyncResetFromCR(2, clk_uart);
    UART#(16) uart <- mkUART(8, NONE, STOP_1, 1, clocked_by clk_uart, reset_by rst_uart);
    
    SyncFIFOIfc#(Bit#(8)) fifo_uart_rx <- mkSyncFIFOToCC(2, clk_uart, rst_uart);
    SyncFIFOIfc#(Bit#(8)) fifo_uart_tx <- mkSyncFIFOFromCC(2, clk_uart);
    //inverted so tx means out, rx means in
    mkConnection(toGet(fifo_uart_tx), uart.rx);
    mkConnection(toPut(fifo_uart_rx), uart.tx);
   
    Reg#(REAL_SAMPLE_TYPE) realValue <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) imagValue <-mkReg(0);
	Reg#(COMPLEX_SAMPLE_TYPE) fixValue <-mkReg(0);

	Reg#(Bit#(8)) currV <-mkReg(0);
	Reg#(Bit#(8)) lastV <-mkReg(0);
	Reg#(Bit#(8)) accumV <-mkReg(0);
	Reg#(Bit#(8)) errorV <-mkReg(0);

	Reg#(Bit#(8)) xFixV <-mkReg(0);
	Reg#(Bit#(8)) yFixV <-mkReg(0);
	Reg#(Bit#(8)) inV <-mkReg(0);
	Reg#(Bit#(8)) outV <-mkReg(0);

	Reg#(Bit#(8)) xV <-mkReg(0);
	Reg#(Bit#(8)) yV <-mkReg(0);
	Reg#(Bit#(8)) zV <-mkReg(0);

	Reg#(Bit#(32)) real_bytes <-mkReg(0);
    Reg#(Bit#(32)) imag_bytes <-mkReg(0);
    Reg#(Bit#(64)) fix_bytes <-mkReg(0);


    Reg#(UInt#(10)) n <- mkReg(0);
 
    Stmt test = seq
		
		action
        currV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        lastV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        accumV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        errorV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        xFixV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        yFixV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction		
		action
        inV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        outV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        xV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        yV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
        endaction
		action
        zV <= fifo_uart_rx.first;
        fifo_uart_rx.deq;
		endaction

		coarseFreq.cbus_ifc.write(11, fromInteger(cleanMask) << currV);
		coarseFreq.cbus_ifc.write(12, fromInteger(cleanMask) << lastV);
		coarseFreq.cbus_ifc.write(13, fromInteger(cleanMask) << accumV);
		coarseFreq.cbus_ifc.write(14, fromInteger(cleanMask) << errorV);

		coarseFreq.cbus_ifc.write(16, fromInteger(cleanMask) << xFixV);
		coarseFreq.cbus_ifc.write(17, fromInteger(cleanMask) << yFixV);
		coarseFreq.cbus_ifc.write(18, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(19, fromInteger(cleanMask) << outV);

		coarseFreq.cbus_ifc.write(41, fromInteger(cleanMask) << xV);
		coarseFreq.cbus_ifc.write(42, fromInteger(cleanMask) << yV);
		coarseFreq.cbus_ifc.write(43, fromInteger(cleanMask) << zV);
		
		for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
			
			action
            real_bytes[31:24] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[23:16] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[15:8] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[7:0] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            realValue.i <= unpack(real_bytes[valueOf(INTEGERSIZE)+15:16]);
            realValue.f <= unpack(real_bytes[15:16-valueOf(CBDATASIZE)]);

            action
            imag_bytes[31:24] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[23:16] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[15:8] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[7:0] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            imagValue.i <= unpack(imag_bytes[valueOf(INTEGERSIZE)+15:16]);
            imagValue.f <= unpack(imag_bytes[15:16-valueOf(CBDATASIZE)]);
			coarseFreq.device_ifc.addSample(cmplx(realValue, imagValue));
		endseq

		for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
			action
			let fix <- coarseFreq.device_ifc.getFixedSamples();
			fixValue <= fix;
			endaction
			fix_bytes <= 0;
            fix_bytes[59:48] <= pack(fixValue.rel.i);
            fix_bytes[47:32] <= pack(fixValue.rel.f);
            fix_bytes[27:16] <= pack(fixValue.img.i);
            fix_bytes[15:00] <= pack(fixValue.img.f);

            
            fifo_uart_tx.enq(fix_bytes[63:56]);
            fifo_uart_tx.enq(fix_bytes[55:48]);
            fifo_uart_tx.enq(fix_bytes[47:40]);
            fifo_uart_tx.enq(fix_bytes[39:32]);

            fifo_uart_tx.enq(fix_bytes[31:24]);
            fifo_uart_tx.enq(fix_bytes[23:16]);
            fifo_uart_tx.enq(fix_bytes[15:08]);
            fifo_uart_tx.enq(fix_bytes[07:00]);
        endseq

    endseq;
    mkAutoFSM(test);

	interface rs232 = uart.rs232;
    interface rs232_rst = rst_uart;
    
endmodule: mkTb

/*----------------------------------------------------------------------------------------*/

interface LineReader;
	method Action start;
	method REAL_SAMPLE_TYPE result;
endinterface

REAL_SAMPLE_TYPE fracDigits[8] = {
		0.1,
		0.01,
		0.001,
		0.0001,
		0.00001,
		0.000001,
		0.0000001,
		0.00000001
};

module mkLineReader(LineReader);
	function ord(s) = fromInteger(charToInteger(stringHead(s)));

	Reg#(Int#(7)) c <- mkRegU;
	Reg#(REAL_SAMPLE_TYPE) number <-mkReg(0.0);
	Reg#(UInt#(3)) fracDigit <- mkReg(0);

	Reg#(Bool) dot <- mkReg(False);
	Reg#(Bool) neg <- mkReg(False);

	FSM fsm <- mkFSM(seq
		dot <= False;
		neg <= False;
		fracDigit <= 0;
		number <= 0.0;
		while (True) seq
			action
			let cin <- $fgetc(stdin);
			if (cin == -1) begin
				$display("Unexpected EOF");
				$finish(1);
			end
			c <= truncate(cin);
			endaction

			
			if (c == ord(",") || c == ord("\n") || c == 13) seq
				if (neg == True) number <= number * -1.0;
				break;
			endseq

			if (c > ord("9")) break;

			action
				case (c)
					ord("."): dot <= True;
					ord("-"): neg <= True;
					ord("0"),ord("1"),ord("2"),ord("3"),ord("4"),ord("5"),ord("6"),ord("7"),ord("8"),ord("9"): begin
						if(dot == False) number <= number * 10 + fromInt(c - 48);
						else action
							number <= number + fxptTruncate(fracDigits[fracDigit] * fromInt(c - 48));
							fracDigit <= fracDigit + 1;
						endaction					
						end
					default: noAction;
				endcase
			endaction
		endseq
	endseq);

	method start = fsm.start;
	method result if (fsm.done) = number;

endmodule: mkLineReader
endpackage: Tb_Uart_limited
