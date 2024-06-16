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
    method Action addSample (Complex#(FixedPoint#(4, 4))  sample);
    method ActionValue #(Complex#(FixedPoint#(4, 4)) ) getFixedSample;
    method Bool hasFixedSample;
endinterface: MMTED_IFC
/*[15, 14, 12, 12, 14]*/
module mkMMTED (MMTED_IFC);

    Reg#(FixedPoint#(10, 4)) mu <-mkReg(0);
    Vector#(445, Reg#(Complex#(FixedPoint#(4, 4)) )) samples <- replicateM(mkReg(0));
    FIFOF#(Complex#(FixedPoint#(4, 4)) ) outF  <- mkSizedFIFOF(445);
    Vector#(3, Reg#(Complex#(FixedPoint#(4, 4)) )) out  <- replicateM(mkReg(0));
    Vector#(3, Reg#(Complex#(FixedPoint#(4, 4)) )) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(10)) iIn <- mkReg(0);
    Reg#(UInt#(10)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 4))) x <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 4))) y <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 4))) conjO <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 4))) conjOR <- mkReg(0);

    FIFO#(Complex#(FixedPoint#(4, 4))) newSample  <- mkFIFO;
    Reg#(Complex#(FixedPoint#(4, 4))) mmVal <- mkReg(0);

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
            mmVal <= y-x;
            mu <= mu + fromInteger(sps) + fxptSignExtend(0.3 * mmVal.rel);
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            iOut <= iOut + 1;
        endseq
    endseq;

    FSM tedErrorCalc <- mkFSM(calcError);

    rule init;
        tedErrorCalc.start;
    endrule

    method Action addSample (Complex#(FixedPoint#(4, 4))  sample);
        newSample.enq(sample);
    endmethod

    /*
    method ActionValue #(FixedPoint#(8, 12)) getError;
        tedErrorCalc.waitTillDone();
        return mu;
    endmethod
    */
    
    method ActionValue #(Complex#(FixedPoint#(4, 4)) ) getFixedSample;
        let x = outF.first();
        outF.deq;
        return x;
    endmethod

    method hasFixedSample =  outF.notEmpty();

endmodule: mkMMTED

endpackage: MMTED_optimal
