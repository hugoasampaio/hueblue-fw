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

module mkLineReader(LineReader);
	function ord(s) = fromInteger(charToInteger(stringHead(s)));

	Reg#(Int#(32)) c <- mkRegU;

	Reg#(FixedPoint#(7, 16)) number <-mkReg(0.0);

	Reg#(Int#(7)) integerPart <- mkReg(0);
	Reg#(Int#(16)) fractionalPart <- mkReg(0);

	Reg#(Bool) dot <- mkReg(False);
	Reg#(Bool) neg <- mkReg(False);

	FSM fsm <- mkFSM(seq
		while (True) seq
			action
			let cin <- $fgetc(stdin);
			if (cin == -1) begin
				$display("Unexpected EOF");
				$finish(1);
			end
			c <= cin;
			endaction

			
			if (c == ord(",") || c == ord("\n") || c == 13) seq
				number.f <= pack(fractionalPart*32767);
				if (neg == True) number.i <= pack(integerPart * -1)[6:0];
				else number.i <= pack(integerPart)[6:0];
				//$display("final: ",pack(integerPart)[6:0], ".",pack(fractionalPart)[20:5]);
				
				break;
			endseq

			if (c > ord("9")) break;

			action
				case (c)
					ord("."): dot <= True;
					ord("-"): neg <= True;
					ord("0"),ord("1"),ord("2"),ord("3"),ord("4"),ord("5"),ord("6"),ord("7"),ord("8"),ord("9"): begin
						if(dot == False) integerPart <= integerPart * 10 + (truncate(c) - 48);
						else fractionalPart <= fractionalPart * 10 + (truncate(c) - 48);
						$display("c: ", c, " i: ", integerPart, " f: ", fractionalPart, " dot: ", dot, " neg: ", neg);						
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