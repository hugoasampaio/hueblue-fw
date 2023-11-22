package Operations;

import FixedPoint::*;
import StmtFSM::*;
import FIFO::*;
import CBus::*;

typedef 3   CBADDRSIZE; //size of configuration address bus to decode
typedef 1   CBDATASIZE; //size of configuration data bus
typedef FixedPoint#(3, 1)   Sample_Type;

interface Operations;
    method Action putOperands(Sample_Type a, Sample_Type b);
    method ActionValue#(Sample_Type) getResult();
endinterface

(* synthesize *)
module mkPlusSynth(IWithCBus#(CBus#(CBADDRSIZE, CBDATASIZE), Operations));
    let ifc();
    exposeCBusIFC#(mkPlus) _temp(ifc);
    return (ifc);
endmodule

module [ModWithCBus#(CBADDRSIZE, CBDATASIZE)] mkPlus(Operations)
    provisos(Add#(1, k, CBDATASIZE));

    Reg#(Bit#(1)) limit <- mkCBRegRW(CRAddr{a: 3'd5, o:0}, 0);
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
