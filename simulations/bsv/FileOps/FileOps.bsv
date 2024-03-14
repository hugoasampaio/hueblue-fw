package FileOps;

import StmtFSM::*;
import FixedPoint::*;

/*
file with complex data for processing
	0.234334,    1.123455
	1.000000,   -1.021323
  -23.234324,    0.000000
  893.293402, -134.023842
*/

interface LineReader;
	method Action start;
	method FixedPoint#(7, 16) result;
endinterface

FixedPoint#(7, 24) fracDigits[8] = {
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

	Reg#(FixedPoint#(7, 16)) number <-mkReg(0.0);

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
						//$display("c: ", c, " i: ", integerPart, " f: ", fractionalPart, " dot: ", dot, " neg: ", neg);						
						end
					default: noAction;
				endcase
			endaction
		endseq
	endseq);

	method start = fsm.start;
	
	method result if (fsm.done) = number;

endmodule
endpackage : FileOps


/*
			if (c == ord(".")) dot <= True;
			
			if (c == ord("-")) neg <= True;
*/