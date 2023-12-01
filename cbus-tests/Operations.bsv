package Operations;

import ModuleContextCore::*;
import FixedPoint::*;
import StmtFSM::*;
import FIFO::*;
import CBus::*;

typedef 3   CBADDRSIZE; //size of configuration address bus to decode
typedef 1   CBDATASIZE; //size of configuration data bus
typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)       LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCBus;

interface Operations#(type i, type frac);
    method Action putOperands(FixedPoint#(i, frac) a, FixedPoint#(i, frac) b);
    method ActionValue#(FixedPoint#(i, frac)) getResult();
endinterface

/*
//binding Cbus databus size to fractional size
//binding Address to Operation instanciation
(* synthesize *)
module [Module] mkPlusSynth(IWithCBus#(LimitedCBus, Operations#(3, CBDATASIZE)));
    let ifc <- exposeCBusIFC(mkPlus(3'd5));
    return ifc;
endmodule
*/

module [LimitedOps] mkPlus#(Bit#(CBADDRSIZE) addr) (Operations#(i, frac))
    provisos(Add#(frac, k, CBDATASIZE),
    Arith#(FixedPoint::FixedPoint#(i, frac)));

    //Bit#(CBADDRSIZE) addr_fix = fromInteger (valueOf (addr));

    Reg#(Bit#(frac)) limit <- mkCBRegRW(CRAddr{a: addr, o:0}, 0);
    FIFO#(FixedPoint#(i, frac)) sum <- mkFIFO;
    FIFO#(FixedPoint#(i, frac)) out <- mkFIFO;
    Reg#(FixedPoint#(i, frac)) ret <- mkReg(0);

    Stmt applyLimit = seq
        ret.i <= sum.first.i;
        ret.f <= sum.first.f & limit;
        sum.deq;
        out.enq(ret);
    endseq;
    FSM limitFSM <- mkFSM(applyLimit);

    method Action putOperands(FixedPoint#(i, frac) a, FixedPoint#(i, frac) b);
        sum.enq(a+b);
        limitFSM.start;
    endmethod

    method ActionValue#(FixedPoint#(i, frac)) getResult();
        let x = out.first;
        out.deq;
        return x;
    endmethod

endmodule

endpackage
