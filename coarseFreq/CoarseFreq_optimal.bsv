package CoarseFreq_optimal;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic_cf::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 442;
/*
coarse freq 13, 13, 13, 8, 12, 12, 12, 12, 
rotate 9, 9, 6, 
atan  16, 13, 5
*/
interface CoarseFreq_IFC;
    method Action addSample (Complex#(FixedPoint#(4, 4)) sample);
    method ActionValue #(FixedPoint#(4, 8)) getError;
    method ActionValue #(Complex#(FixedPoint#(4, 4))) getFixedSamples;
    method Bool hasFixedSamples;
endinterface: CoarseFreq_IFC

module mkCoarseFreq (CoarseFreq_IFC);
    Vector#(446, Reg#(Complex#(FixedPoint#(4, 4)))) samples <-replicateM(mkReg(0));
    Reg#(Complex#(FixedPoint#(4, 4))) out <- mkReg(0);

    FIFO#(Complex#(FixedPoint#(4, 4))) newSample <- mkFIFO;
    FIFOF#(Complex#(FixedPoint#(4, 4))) outSample <- mkSizedFIFOF(445);
    Reg#(Complex#(FixedPoint#(4, 3))) lastSample <-mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 3))) currSample <-mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 3))) accumError <- mkReg(0);
    Reg#(FixedPoint#(4, 8)) fsError <- mkReg(0);
    
    Reg#(FixedPoint#(4, 4)) xFix <- mkReg(1.0);
    Reg#(FixedPoint#(4, 4)) yFix <- mkReg(0.0);

    Reg#(UInt#(10)) n <- mkReg(0);
    Reg#(UInt#(10)) m <- mkReg(0);

    Cordic_IFC cordic <- mkRotate;
    Cordic_IFC atan <- mkAtan;
    
    Stmt fixError = seq
        
    endseq;
    FSM coarseErrorFix <- mkFSM(fixError);

    Stmt calcError = seq
        action
        lastSample <= cmplx(0,0);
        currSample <= cmplx(0,0);
        accumError <= cmplx(0,0);
        fsError    <= 0;
        endaction
        for(n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            action
            samples[n] <= newSample.first;
            newSample.deq;
            endaction
        endseq
        for (n <= 30; n < (30+8*fromInteger(sps)); n <= n+1) seq
                action
                currSample <= cmplx(fxptTruncate(samples[n].rel), fxptTruncate(samples[n].img));                
                lastSample.img <=  lastSample.img * -1.0; //conjugado
                endaction
                action
                accumError <= accumError + (currSample * lastSample);
                lastSample <= currSample;
                endaction
        endseq
        // 1/(2*pi) = 0.159155
        atan.setPolar(accumError.rel, accumError.img, 0.0);
        action
        let z <- atan.getZ;
        fsError <=  0.159155 * fxptSignExtend(z);
        endaction
        
        for(n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            out <= samples[n] * cmplx(xFix, yFix); 
            outSample.enq(out);
            cordic.setPolar(fxptTruncate(xFix), fxptTruncate(yFix), (-2.0 * 3.141593 * fxptTruncate(fsError)));
            action
            let x_rot <- cordic.getX();
            let y_rot <- cordic.getY();
            xFix <= fxptSignExtend(x_rot);
            yFix <= fxptSignExtend(y_rot);
            endaction
        endseq
    endseq;
    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (Complex#(FixedPoint#(4, 4)) sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(FixedPoint#(4, 8)) getError;
        coarseErrorCalc.waitTillDone();
        return fsError;
    endmethod

    method ActionValue #(Complex#(FixedPoint#(4, 4))) getFixedSamples;
        let x = outSample.first;
        outSample.deq;
        return x;
    endmethod

    method hasFixedSamples = outSample.notEmpty;

endmodule: mkCoarseFreq

endpackage: CoarseFreq_optimal
