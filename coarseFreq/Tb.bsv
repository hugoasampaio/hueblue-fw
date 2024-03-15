package Tb;

import CoarseFreq::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;

(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedCoarseFreq, CoarseFreq_IFC) coarseFreq <- exposeCBusIFC(mkCoarseFreq);
    LineReader lr <- mkLineReader;
   
    Reg#(FixedPoint#(15, 16)) realValue <-mkReg(0);
    Reg#(FixedPoint#(15, 16)) imagValue <-mkReg(0);

	Reg#(FixedPoint#(15, 16)) currV <-mkReg(0);
	Reg#(FixedPoint#(15, 16)) lastV <-mkReg(0);
	Reg#(FixedPoint#(15, 16)) accumV <-mkReg(0);
	Reg#(FixedPoint#(15, 16)) errorV <-mkReg(0);

    Reg#(UInt#(8)) n <- mkReg(0);
	Reg#(UInt#(6)) m <- mkReg(0);
 
    Stmt test = seq
		lr.start;
		currV <= lr.result;
		lr.start;
		lastV <= lr.result;
		lr.start;
		accumV <= lr.result;
		lr.start;
		errorV <= lr.result;
		coarseFreq.cbus_ifc.write(11, 16'hffff << currV.i);
		coarseFreq.cbus_ifc.write(12, 16'hffff << lastV.i);
		coarseFreq.cbus_ifc.write(13, 16'hffff << accumV.i);
		coarseFreq.cbus_ifc.write(14, 16'hffff << errorV.i);
		
		for (m <= 0; m < 2; m <= m+1) seq
			for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
				lr.start;
				realValue <= lr.result;
				lr.start;
				imagValue <= lr.result;
				coarseFreq.device_ifc.addSample(cmplx(realValue, imagValue));
			endseq
			action
			let err <- coarseFreq.device_ifc.getError;
			//fxptWrite(5,err);
			//$display(" ");
			//coarseFreq.device_ifc.getError;
			endaction
		endseq
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb

/*----------------------------------------------------------------------------------------*/

interface LineReader;
	method Action start;
	method FixedPoint#(15, 16) result;
endinterface

FixedPoint#(15, 24) fracDigits[8] = {
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
	Reg#(FixedPoint#(15, 16)) number <-mkReg(0.0);
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
endpackage: Tb
     /* atan base test
        $display("  ");
        fxptWrite(5, atan(2.819, 1.026));//20 --- 0.349
        $display("  ");
        fxptWrite(5, atan(-1.026, 2.819));//110 --- 1.9198
        $display("  ");
        fxptWrite(5, atan(-2.819, -1.026));//200 --- 3.49
        $display("  ");
        fxptWrite(5, atan(1.026, -2.819));//290 --- 5.061
        $display("  ");
        fxptWrite(5, atan(-5.83674, 30.597488));//290 --- 5.061
        $display("  ");
        */