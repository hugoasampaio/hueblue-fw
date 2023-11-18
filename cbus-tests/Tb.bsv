package Tb;

import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import Vector::*;
import Operations::*;

(* synthesize *)
module mkTb (Empty);
    Operations plus <- mkPlus;
    Stmt sum = seq
        plus.putOperands(1, 1.5);
        action
        let r <-  plus.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        $display(" ");
        endaction
    endseq;

    mkAutoFSM(sum);

endmodule
endpackage