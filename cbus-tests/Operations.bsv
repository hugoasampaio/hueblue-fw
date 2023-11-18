package Operations;

import FixedPoint::*;
import StmtFSM::*;
import FIFO::*;

typedef FixedPoint#(3, 1) Sample_Type;

interface Operations;
    method Action putOperands(Sample_Type a, Sample_Type b);
    method ActionValue#(Sample_Type) getResult();
endinterface

(* synthesize *)
module mkPlus (Operations);
    Reg#(Bit#(1)) limit <- mkReg(0);
    FIFO#(Sample_Type) sum <- mkFIFO;
    FIFO#(Sample_Type) out <- mkFIFO;
    Reg#(Sample_Type) ret <- mkReg(0);

    Stmt applyLimit = seq
        ret.i <= sum.first.i;
        ret.f <= sum.first.f & limit;
        sum.deq;
        out.enq(ret);
    endseq;
    FSM limitFSM <- mkFSM(applyLimit);

    method Action putOperands(Sample_Type a, Sample_Type b);
        sum.enq(a+b);
        limitFSM.start;
    endmethod

    method ActionValue#(Sample_Type) getResult();
        let x = out.first;
        out.deq;
        return x;
    endmethod

endmodule
endpackage