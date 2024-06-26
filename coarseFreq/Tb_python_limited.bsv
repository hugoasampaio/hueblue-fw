package Tb_python_limited;

import CoarseFreq_limited::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedCoarseFreq, CoarseFreq_IFC) coarseFreq <- exposeCBusIFC(mkCoarseFreq);
    LineReader lr <- mkLineReader;
   
    Reg#(REAL_SAMPLE_TYPE) realValue <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) imagValue <-mkReg(0);

	Reg#(REAL_SAMPLE_TYPE) currV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) lastV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) accumV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) errorV <-mkReg(0);

	Reg#(REAL_SAMPLE_TYPE) xFixV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yFixV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) inV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) outV <-mkReg(0);

	Reg#(REAL_SAMPLE_TYPE) xV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) zV <-mkReg(0);

	Reg#(REAL_SAMPLE_TYPE) xaV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yaV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) zaV <-mkReg(0);


    Reg#(UInt#(10)) n <- mkReg(0);
 
    Stmt test = seq
		lr.start;
		currV <= lr.result;
		lr.start;
		lastV <= lr.result;
		lr.start;
		accumV <= lr.result;
		lr.start;
		errorV <= lr.result;

		lr.start;
		xFixV <= lr.result;
		lr.start;
		yFixV <= lr.result;
		lr.start;
		inV <= lr.result;
		lr.start;
		outV <= lr.result;

		lr.start;
		xV <= lr.result;
		lr.start;
		yV <= lr.result;
		lr.start;
		zV <= lr.result;

		lr.start;
		xaV <= lr.result;
		lr.start;
		yaV <= lr.result;
		lr.start;
		zaV <= lr.result;

		coarseFreq.cbus_ifc.write(11, fromInteger(cleanMask) << currV.i);
		coarseFreq.cbus_ifc.write(12, fromInteger(cleanMask) << lastV.i);
		coarseFreq.cbus_ifc.write(13, fromInteger(cleanMask) << accumV.i);
		coarseFreq.cbus_ifc.write(14, fromInteger(cleanMask) << errorV.i);

		coarseFreq.cbus_ifc.write(16, fromInteger(cleanMask) << xFixV.i);
		coarseFreq.cbus_ifc.write(17, fromInteger(cleanMask) << yFixV.i);
		coarseFreq.cbus_ifc.write(18, fromInteger(cleanMask) << inV.i);
		coarseFreq.cbus_ifc.write(19, fromInteger(cleanMask) << outV.i);

		coarseFreq.cbus_ifc.write(41, fromInteger(cleanMask) << xV.i);
		coarseFreq.cbus_ifc.write(42, fromInteger(cleanMask) << yV.i);
		coarseFreq.cbus_ifc.write(43, fromInteger(cleanMask) << zV.i);

		coarseFreq.cbus_ifc.write(44, fromInteger(cleanMask) << xaV.i);
		coarseFreq.cbus_ifc.write(45, fromInteger(cleanMask) << yaV.i);
		coarseFreq.cbus_ifc.write(46, fromInteger(cleanMask) << zaV.i);
		
		for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
			lr.start;
			realValue <= lr.result;
			lr.start;
			imagValue <= lr.result;
			coarseFreq.device_ifc.addSample(cmplx(realValue, imagValue));
		endseq
		/*
		action
			let fix <- coarseFreq.device_ifc.getError();
			fxptWrite(6, fix);
			$display(" ");
		endaction
		*/

		for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
			action
			let fix <- coarseFreq.device_ifc.getFixedSamples();
			fxptWrite(5, fix.rel);
			$write(", ");
			fxptWrite(5, fix.img);
			$display(" ");
			endaction
		endseq
		
		
	endseq;
    
    mkAutoFSM(test);
    
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
endpackage: Tb_python_limited
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