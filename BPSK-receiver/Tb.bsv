package Tb;

import BPSK_receiver::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedBPSKReceiver, BPSK_receiver_IFC) bpskReceiver <- exposeCBusIFC(mkBPSK_receiver);
    LineReader lr <- mkLineReader;

    Reg#(REAL_SAMPLE_TYPE) realValue <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) imagValue <-mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) currV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) lastV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) accumV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) errorV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) cpxfixV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) xFixV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yFixV <-mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) xV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) yV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) muV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) outV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) mmV <-mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) phV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) errV <-mkReg(0);
	Reg#(REAL_SAMPLE_TYPE) frV <-mkReg(0);

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
		cpxfixV <= lr.result;
		lr.start;
		xFixV <= lr.result;
		lr.start;
		yFixV <= lr.result;

		lr.start;
		xV <= lr.result;
		lr.start;
		yV <= lr.result;
		lr.start;
		muV <= lr.result;
		lr.start;
		outV <= lr.result;
		lr.start;
		mmV <= lr.result;

        lr.start;
		phV <= lr.result;
		lr.start;
		errV <= lr.result;
		lr.start;
		frV <= lr.result;

		bpskReceiver.cbus_ifc.write(5, fromInteger(cleanMask) << xV.i);
		bpskReceiver.cbus_ifc.write(6, fromInteger(cleanMask) << yV.i);
		bpskReceiver.cbus_ifc.write(7, fromInteger(cleanMask) << muV.i);
		bpskReceiver.cbus_ifc.write(8, fromInteger(cleanMask) << outV.i);
		bpskReceiver.cbus_ifc.write(9, fromInteger(cleanMask) << mmV.i);

        bpskReceiver.cbus_ifc.write(3, fromInteger(cleanMask) << phV.i);
		bpskReceiver.cbus_ifc.write(4, fromInteger(cleanMask) << errV.i);
		bpskReceiver.cbus_ifc.write(10, fromInteger(cleanMask) << frV.i);

        bpskReceiver.cbus_ifc.write(11, fromInteger(cleanMask) << currV.i);
		bpskReceiver.cbus_ifc.write(12, fromInteger(cleanMask) << lastV.i);
		bpskReceiver.cbus_ifc.write(13, fromInteger(cleanMask) << accumV.i);
		bpskReceiver.cbus_ifc.write(14, fromInteger(cleanMask) << errorV.i);
		bpskReceiver.cbus_ifc.write(15, fromInteger(cleanMask) << cpxfixV.i);
		bpskReceiver.cbus_ifc.write(16, fromInteger(cleanMask) << xFixV.i);
		bpskReceiver.cbus_ifc.write(17, fromInteger(cleanMask) << yFixV.i);

		for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
			lr.start;
			realValue <= lr.result;
			lr.start;
			imagValue <= lr.result;
			bpskReceiver.device_ifc.addSample(cmplx(realValue, imagValue));
		endseq
		action
		let err <- bpskReceiver.device_ifc.getError;
		//fxptWrite(5,err);
		//$display(" ");
		//coarseFreq.device_ifc.getError;
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
endpackage: Tb
