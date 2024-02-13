package FIRfilter;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIRcoeff::*;
import StmtFSM::*;
import FixedPoint::*;
import CBus::*;

typedef FIRtap_Type Sample_Type;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCBus;

interface FIRfilter_type;
    method Action add_sample (Sample_Type sample);
    method ActionValue #(Sample_Type) get_value;
endinterface: FIRfilter_type

module [LimitedOps] mkFIRfilter (FIRfilter_type);
    Vector#(43, Reg#(Sample_Type)) samples <-replicateM(mkReg(0));
    FIFO#(Sample_Type) acc <-mkFIFO;
    FIFO#(Sample_Type) newSample <- mkFIFO;
    Reg#(Sample_Type) sum <- mkReg(0);
    Reg#(Sample_Type) m <- mkReg(0);
    Reg#(UInt#(7)) n <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitMult <- mkCBRegRW(CRAddr{a: 8'd1, o:0}, 'hffff);
    Reg#(Bit#(CBDATASIZE)) limitSum <- mkCBRegRW(CRAddr{a: 8'd2, o:0},  'hffff);


    Stmt convolve = seq
        for (n <= 42; n > 0; n <= n-1) action
            samples[n] <= samples[n-1];
        endaction

        samples[0] <= newSample.first;
        newSample.deq;
        
        for (n <= 0; n < 43; n <= n+1) seq
            m <= samples[n] * coeff[n];
            m.f <= m.f & limitMult;
            sum <= sum + m;
            sum.f <= sum.f & limitSum;
            //sum <= sum + (samples[n] * coeff[n]);
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

    method ActionValue #(Sample_Type) get_value;
        let ret = acc.first;
        acc.deq;
        return ret;
    endmethod

endmodule: mkFIRfilter

endpackage: FIRfilter
