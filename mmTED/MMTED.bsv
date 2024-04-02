package MMTED;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedMMTED;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface MMTED_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
endinterface: MMTED_IFC

module [LimitedOps] mkMMTED (MMTED_IFC);

    Reg#(REAL_SAMPLE_TYPE) mu <-mkReg(0);
    Vector#(340, Reg#(COMPLEX_SAMPLE_TYPE)) samples <- replicateM(mkReg(0));
    Vector#(350, Reg#(COMPLEX_SAMPLE_TYPE)) out  <- replicateM(mkReg(0));
    Vector#(350, Reg#(COMPLEX_SAMPLE_TYPE)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) x <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y <- mkReg(0);
    FIFO#(COMPLEX_SAMPLE_TYPE) newSample <- mkFIFO;
    Reg#(REAL_SAMPLE_TYPE) mmVal <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd5, o:0}, 'hfffff);
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd6, o:0},  'hfffff);
    Reg#(Bit#(CBDATASIZE)) limitMu <- mkCBRegRW(CRAddr{a: 8'd7, o:0},  'hfffff);

    Stmt calcError = seq
        for (n <= 0; n < 340; n <= n+1) seq
            samples[n] <= newSample.first;
            newSample.deq;
        endseq
        while (iOut < 340 && iIn+16 < 340) seq
            out[iOut] <= samples[iIn];
            outRail[iOut] <= cmplx( (out[iOut].rel > 0.0 ? 1.0 : 0.0) ,  (out[iOut].img > 0.0 ? 1.0 : 0.0));
            x <= (outRail[iOut] - outRail[iOut-2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));
            y <= (out[iOut] - out[iOut-2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));

            //apply limits
            x.rel.f <= x.rel.f & limitX;
            x.img.f <= x.img.f & limitX;
            y.rel.f <= y.rel.f & limitY;
            y.img.f <= y.img.f & limitY;

            mmVal <= y.rel-x.rel;
            mu <= mu + fromInteger(sps) + (0.3 * mmVal);
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            mu.f <= mu.f & limitMu;
            iOut <= iOut + 1;
        endseq
        //$display("iout: ", iOut);
        for (n <= 2; n < iOut; n <= n +1 ) action
            fxptWrite(6, out[n].rel);
            $write(", ");
            fxptWrite(6, out[n].img);
            $display(" ");
        endaction
    endseq;

    FSM tedErrorCalc <- mkFSM(calcError);

    rule init;
        tedErrorCalc.start;
    endrule

    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        tedErrorCalc.waitTillDone();
        return mu;
    endmethod

endmodule: mkMMTED

endpackage: MMTED
