package MMTED_optimal;

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
    method Action addSample (Complex#(FixedPoint#(3, 12))  sample);
    //method ActionValue #(FixedPoint#(8, 12)) getError;
    method ActionValue #(Complex#(FixedPoint#(3, 12)) ) getFixedSample;
    method Bool hasFixedSample;
endinterface: MMTED_IFC

module mkMMTED (MMTED_IFC);

    Reg#(FixedPoint#(10, 12)) mu <-mkReg(0);
    Vector#(445, Reg#(Complex#(FixedPoint#(3, 12)) )) samples <- replicateM(mkReg(0));
    FIFOF#(Complex#(FixedPoint#(3, 12)) ) outF  <- mkSizedFIFOF(445);
    Vector#(3, Reg#(Complex#(FixedPoint#(3, 12)) )) out  <- replicateM(mkReg(0));
    Vector#(3, Reg#(Complex#(FixedPoint#(3, 12)) )) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(10)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(Complex#(FixedPoint#(3, 12)) ) x <- mkReg(0);
    Reg#(Complex#(FixedPoint#(3, 12)) ) y <- mkReg(0);
    Reg#(Complex#(FixedPoint#(3, 12)) ) x2 <- mkReg(0);
    Reg#(Complex#(FixedPoint#(3, 12)) ) y2 <- mkReg(0);
    FIFO#(Complex#(FixedPoint#(3, 12)) ) newSample  <- mkFIFO;
    Reg#(FixedPoint#(3, 12)) mmVal <- mkReg(0);

    Stmt calcError = seq
        for (n <= 0; n < 440; n <= n+1) action
            samples[n]<= newSample.first;
            newSample.deq;
        endaction
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
            mmVal <= y2.rel-x2.rel;
            mu <= mu + fromInteger(sps) + fxptSignExtend(0.3 * mmVal);
            iIn <= iIn + unpack(mu.i);
            action
            mu.i <= 0;
            iOut <= iOut + 1;
            endaction
        endseq
    endseq;

    FSM tedErrorCalc <- mkFSM(calcError);

    rule init;
        tedErrorCalc.start;
    endrule

    method Action addSample (Complex#(FixedPoint#(3, 12))  sample);
        newSample.enq(sample);
    endmethod

    /*
    method ActionValue #(FixedPoint#(8, 12)) getError;
        tedErrorCalc.waitTillDone();
        return mu;
    endmethod
    */
    
    method ActionValue #(Complex#(FixedPoint#(3, 12)) ) getFixedSample;
        let x = outF.first();
        outF.deq;
        return x;
    endmethod

    method hasFixedSample =  outF.notEmpty();

endmodule: mkMMTED

endpackage: MMTED_optimal
