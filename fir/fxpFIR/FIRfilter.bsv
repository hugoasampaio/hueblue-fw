package FIRfilter;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIRcoeff::*;
import StmtFSM::*;
import FixedPoint::*;

typedef FIRtap_Type Sample_Type;

interface FIRfilter_type;
    method Action add_sample (Sample_Type sample);
    method Action set_fwl(UInt#(7) fwl);
    method ActionValue #(Sample_Type) get_value;
endinterface: FIRfilter_type

(* synthesize *)
module mkFIRfilter (FIRfilter_type);
    Vector#(43, Reg#(Sample_Type)) samples <-replicateM(mkReg(0));
    FIFO#(Sample_Type) acc <-mkFIFO;
    FIFO#(Sample_Type) newSample <- mkFIFO;
    Reg#(Sample_Type) sum <- mkReg(0);
    Reg#(UInt#(7)) n <- mkReg(0);
    Reg#(UInt#(7)) zeros <-mkReg(0);
    Reg#(Sample_Type) tap <-mkReg(0);

    Stmt convolve = seq
        for (n <= 42; n > 0; n<=n-1) action
            samples[n] <= samples[n-1];
        endaction

        samples[0] <= newSample.first;
        newSample.deq;
        
        for (n<= 0; n < 43; n<=n+1) seq
            tap.i <= coeff[n].i;
            tap.f <= coeff[n].f & ('hFFFF << zeros);
            sum <= sum + (samples[n] * tap);
        endseq
        acc.enq(sum);
        sum <= 0;
    endseq;

    FSM conv <- mkFSM(convolve);

    rule init;
        conv.start;
    endrule

    method Action add_sample (Sample_Type sample);
        newSample.enq(sample);
    endmethod

    method Action set_fwl(UInt#(7) fwl);
        zeros <= fwl;
    endmethod

    method ActionValue #(Sample_Type) get_value;
        let ret = acc.first;
        acc.deq;
        return ret;
    endmethod

endmodule: mkFIRfilter

endpackage: FIRfilter
