package MMTED_limited;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
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
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
    method Bool hasFixedSample;
endinterface: MMTED_IFC

module [LimitedOps] mkMMTED (MMTED_IFC);

    Reg#(REAL_SAMPLE_TYPE) mu <-mkReg(0);
    Vector#(445, Reg#(COMPLEX_SAMPLE_TYPE)) samples <- replicateM(mkReg(0));
    FIFOF#(COMPLEX_SAMPLE_TYPE) outF  <- mkSizedFIFOF(445);
    Vector#(445, Reg#(COMPLEX_SAMPLE_TYPE)) out  <- replicateM(mkReg(0));
    Vector#(445, Reg#(COMPLEX_SAMPLE_TYPE)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);

    Reg#(COMPLEX_SAMPLE_TYPE) x <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) conjO <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) conjOR <- mkReg(0);

    FIFO#(COMPLEX_SAMPLE_TYPE) newSample  <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE) mmVal <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitX  <- mkCBRegRW(CRAddr{a: 8'd21, o:0},fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitY  <- mkCBRegRW(CRAddr{a: 8'd22, o:0},fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitMu <- mkCBRegRW(CRAddr{a: 8'd23, o:0},fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitIn <- mkCBRegRW(CRAddr{a: 8'd24, o:0},fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitmm <- mkCBRegRW(CRAddr{a: 8'd25, o:0},fromInteger(cleanMask));

    Stmt calcError = seq
        for (n <= 0; n < 440; n <= n+1) seq
            action
            samples[n]<= newSample.first;
            newSample.deq;
            endaction
            samples[n].rel.f <= samples[n].rel.f & limitIn;
            samples[n].img.f <= samples[n].img.f & limitIn;
        endseq
        while (iOut < 440 && iIn+16 < 440) seq
            action
            out[2] <= out[1];
            out[1] <= out[0];
            out[0] <= samples[iIn];
            outRail[2] <= outRail[1];
            outRail[1] <= outRail[0];
            outRail[0] <= cmplx((samples[iIn].rel > 0.0 ? 1.0 : 0.0),
                                (samples[iIn].img > 0.0 ? 1.0 : 0.0));
            if (iOut > 1) begin
                outF.enq(samples[iIn]);
            end
            endaction
            action
            conjO <= out[1];
            conjOR <= outRail[1];
            endaction
            action
            conjO.img <= conjO.img * -1.0;
            conjOR.img <= conjOR.img * -1.0;
            endaction
            action
            x <= (outRail[0] - outRail[2]) * conjO;
            y <= (out[0] - out[2])         * conjOR;
            endaction
            /* apply limits */
            action
            x.rel.f <= x.rel.f & limitX;
            y.rel.f <= y.rel.f & limitY;
            endaction
            action
            x.img.f <= x.img.f & limitX;
            y.img.f <= y.img.f & limitY;
            endaction            
            mmVal <= y-x;
            mmVal.rel.f <= mmVal.rel.f & limitmm;
            mu <= mu + fromInteger(sps) + (0.3 * mmVal.rel);
            iIn <= iIn + signExtend(unpack(mu.i));
            mu.i <= 0;
            mu.f <= mu.f & limitMu;
            iOut <= iOut + 1;
        endseq

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

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
        let x = outF.first();
        outF.deq;
        return x;
    endmethod

    method hasFixedSample =  outF.notEmpty();

endmodule: mkMMTED

endpackage: MMTED_limited
