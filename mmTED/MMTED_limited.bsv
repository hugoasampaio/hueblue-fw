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
    Vector#(3, Reg#(COMPLEX_SAMPLE_TYPE)) out  <- replicateM(mkReg(0));
    Vector#(3, Reg#(COMPLEX_SAMPLE_TYPE)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) x <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) x2 <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y2 <- mkReg(0);
    FIFO#(COMPLEX_SAMPLE_TYPE) newSample  <- mkFIFO;
    Reg#(REAL_SAMPLE_TYPE) mmVal <- mkReg(0);

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
            samples[n].rel.f <= samples[n].rel.f & limitX;
            samples[n].img.f <= samples[n].img.f & limitX;
        endseq
        while (iOut < 440 && iIn+16 < 440) seq
            action
            out[2] <= out[1];
            out[1] <= out[0];
            out[0] <= samples[iIn];
            outRail[2] <= outRail[1];
            outRail[1] <= outRail[0];
            outRail[0] <= cmplx( (samples[iIn].rel > 0.0 ? 1.0 : 0.0) ,  
                                    (samples[iIn].img > 0.0 ? 1.0 : 0.0));
            if (iOut > 1) begin
                outF.enq(samples[iIn]);
            end
            endaction
            action
            x <= (outRail[0] - outRail[2]) * (outRail[1] * cmplx(1.0, -1.0));
            y <= (out[0] - out[2]) * (outRail[1] * cmplx(1.0, -1.0));
            endaction
            action
            //apply limits
            x2.rel.f <= x.rel.f & limitX;
            y2.rel.f <= y.rel.f & limitY;
            endaction
            action
            x2.img.f <= x.img.f & limitX;
            y2.img.f <= y.img.f & limitY;
            endaction
            mmVal <= y2.rel-x2.rel;
            mmVal.f <= mmVal.f & limitmm;
            mu <= mu + fromInteger(sps) + (0.3 * mmVal);
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            mu.f <= mu.f & limitMu;
            iOut <= iOut + 1;
        endseq
        //$display("iout: ", iOut);
        /*
        for (n <= 2; n < iOut; n <= n +1 ) action
            fxptWrite(6, out[n].rel);
            $write(", ");
            fxptWrite(6, out[n].img);
            $display(" ");
        endaction
        */
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
