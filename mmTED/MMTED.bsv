package MMTED;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import StmtFSM::*;
import FixedPoint::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface MMTED_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
    method Bool hasFixedSample;
endinterface: MMTED_IFC

module mkMMTED (MMTED_IFC);

    Reg#(REAL_SAMPLE_TYPE) mu <-mkReg(0);
    Vector#(445, Reg#(COMPLEX_SAMPLE_TYPE)) samples <- replicateM(mkReg(0));
    FIFOF#(COMPLEX_SAMPLE_TYPE) outF  <- mkSizedFIFOF(445);
    Vector#(445, Reg#(COMPLEX_SAMPLE_TYPE)) out  <- replicateM(mkReg(0));
    Vector#(3, Reg#(COMPLEX_SAMPLE_TYPE)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) x <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y <- mkReg(0);
    FIFO#(COMPLEX_SAMPLE_TYPE) newSample  <- mkFIFO;
    Reg#(REAL_SAMPLE_TYPE) mmVal <- mkReg(0);

    Stmt calcError = seq
        for (n <= 0; n < 440; n <= n+1) action
            samples[n]<= newSample.first;
            newSample.deq;
        endaction
        while (iOut < 440 && iIn+16 < 440) seq
            /*
            action
            out[2] <= out[1];
            out[1] <= out[0];
            out[0] <= samples[iIn];
            outF.enq(samples[iIn]);
            endaction
            action
            outRail[2] <= outRail[1];
            outRail[1] <= outRail[0];
            outRail[0] <= cmplx( (samples[iIn].rel > 0.0 ? 1.0 : 0.0) ,  
                                    (samples[iIn].img > 0.0 ? 1.0 : 0.0));
            endaction
            */
            
            
            
            action
            x <= (outRail[0] - outRail[2]) * (outRail[1] * cmplx(1.0, -1.0));
            y <= (out[0] - out[2]) * (outRail[1] * cmplx(1.0, -1.0));
            endaction
            mmVal <= y.rel-x.rel;
            mu <= mu + fromInteger(sps) + (0.3 * mmVal);
            iIn <= iIn + signExtend(unpack(mu.i));
            action
            mu.i <= 0;
            iOut <= iOut + 1;
            endaction
        endseq
        for (n <= 2; n < iOut; n <= n +1 ) seq
            outF.enq(samples[iIn]);
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

endpackage: MMTED
