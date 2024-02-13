package MMTED;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import CBus::*;

typedef 8    CBADDRSIZE; //size of configuration address bus to decode
typedef 16   CBDATASIZE; //size of configuration data bus
typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedMMTED;

typedef FixedPoint#(7, 16)      SampleType;
typedef Complex#(SampleType)    ComplexSampleType;
Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface MMTED_IFC;
    method Action addSample (ComplexSampleType sample);
    method ActionValue #(SampleType) getError;
endinterface: MMTED_IFC

module [LimitedOps] mkMMTED (MMTED_IFC);

    Reg#(SampleType) mu <-mkReg(0);
    Vector#(64, Reg#(ComplexSampleType)) samples <- replicateM(mkReg(0));
    Vector#(74, Reg#(ComplexSampleType)) out  <- replicateM(mkReg(0));
    Vector#(74, Reg#(ComplexSampleType)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(7)) iIn <- mkReg(0);
    Reg#(UInt#(7)) iOut <- mkReg(2);
    Reg#(UInt#(7)) n <- mkReg(0);
    Reg#(ComplexSampleType) x <- mkReg(0);
    Reg#(ComplexSampleType) y <- mkReg(0);
    FIFO#(ComplexSampleType) newSample <- mkFIFO;
    Reg#(SampleType) mmVal <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd5, o:0}, 'hffff);
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd6, o:0},  'hffff);
    Reg#(Bit#(CBDATASIZE)) limitMu <- mkCBRegRW(CRAddr{a: 8'd7, o:0},  'hffff);

    Stmt calcError = seq
        for (n <= 0; n < 64; n <= n+1) seq
            samples[n] <= newSample.first;
            newSample.deq;
        endseq
        while (iOut < 64 && iIn+16 < 64) seq
            out[iOut] <= samples[iIn];
            outRail[iOut] <= cmplx( (out[iOut].rel > 0.0 ? 1.0 : 0.0) ,  (out[iOut].img > 0.0 ? 1.0 : 0.0));
            x <= (outRail[iOut] - outRail[iOut -2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));
            y <= (out[iOut] - out[iOut -2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));

            //apply limits
            x.rel.f <= x.rel.f & limitX;
            x.img.f <= x.img.f & limitX;
            y.rel.f <= y.rel.f & limitY;
            y.img.f <= y.img.f & limitY;

            mmVal <= y.rel-x.rel;
            mu <= mu + fromInteger(sps) + 0.3 * mmVal;
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            mu.f <= mu.f & limitMu;
            iOut <= iOut + 1;
        endseq

    endseq;

    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (ComplexSampleType sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(SampleType) getError;
        return mu;
    endmethod

endmodule: mkMMTED

endpackage: MMTED
