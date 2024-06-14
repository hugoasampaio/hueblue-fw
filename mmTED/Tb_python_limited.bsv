package Tb_python_limited;

import MMTED_limited::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedMMTED, MMTED_IFC) mmTed <- exposeCBusIFC(mkMMTED);
    LineReader lr <- mkLineReader;

    Reg#(REAL_SAMPLE_TYPE) realValue <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) imagValue <-mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) xV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) muV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) inV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) mmV <-mkReg(0);

    Reg#(UInt#(10)) n <- mkReg(0);

 
    Stmt test = seq
		lr.start;
		xV <= lr.result;

		lr.start;
		yV <= lr.result;
		
		lr.start;
		muV <= lr.result;
		
		lr.start;
		inV <= lr.result;
		
		lr.start;
		mmV <= lr.result;

		mmTed.cbus_ifc.write(21, fromInteger(cleanMask) << xV.i);
		mmTed.cbus_ifc.write(22, fromInteger(cleanMask) << yV.i);
		mmTed.cbus_ifc.write(23, fromInteger(cleanMask) << muV.i);
		mmTed.cbus_ifc.write(24, fromInteger(cleanMask) << inV.i);
		mmTed.cbus_ifc.write(25, fromInteger(cleanMask) << mmV.i);
		
		for (n <= 0; n < 445; n <= n+1) seq
			lr.start;
			realValue <= lr.result;
			lr.start;
			imagValue <= lr.result;
			mmTed.device_ifc.addSample(cmplx(realValue, imagValue));
		endseq
		while (mmTed.device_ifc.hasFixedSample() == True) action
			let fix <- mmTed.device_ifc.getFixedSample;
			fxptWrite(5, fix.rel);
			$write(", ");
			fxptWrite(5, fix.img);
			$display("  ");
		endaction

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
