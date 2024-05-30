package MMTED_optimal;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 24;

interface MMTED_IFC;
    method Action addSample (Complex#(FixedPoint#(4, 12)) sample);
    method ActionValue #(FixedPoint#(12, 9)) getError;
endinterface: MMTED_IFC
(* synthesize *)
module mkMMTEDO (MMTED_IFC);

    Reg#(FixedPoint#(12, 9)) mu <-mkReg(0);
    Vector#(25, Reg#(Complex#(FixedPoint#(4, 12)))) samples <- replicateM(mkReg(0));
    Vector#(25, Reg#(Complex#(FixedPoint#(4, 6)))) out  <- replicateM(mkReg(0));
    Vector#(25, Reg#(Complex#(FixedPoint#(4, 12)))) outRail  <- replicateM(mkReg(0));
    Reg#(Complex#(FixedPoint#(4, 12))) xx <- mkReg (0);
    Reg#(Complex#(FixedPoint#(4, 12))) yy <- mkReg (0);
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(UInt#(12)) n <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 6))) x <- mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 6))) y <- mkReg(0);
    FIFO#(Complex#(FixedPoint#(4, 12))) newSample <- mkFIFO;
    Reg#(FixedPoint#(4, 6)) mmVal <- mkReg(0);

    Stmt calcError = seq
        for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            samples[n] <= newSample.first;
            newSample.deq;
        endseq
        while (iOut < fromInteger(loopFix) && iIn+16 < fromInteger(loopFix)) seq
            out[iOut] <= cmplx(fxptTruncate(samples[iIn].rel), fxptTruncate(samples[iIn].img));
            outRail[iOut] <= cmplx( (out[iOut].rel > 0.0 ? 1.0 : 0.0) ,  (out[iOut].img > 0.0 ? 1.0 : 0.0));

            xx <= ((outRail[iOut] - outRail[iOut-2]) * (outRail[iOut-1] * cmplx(1.0, -1.0)));
            x <= cmplx(fxptTruncate(xx.rel), fxptTruncate(xx.img));
            yy <= (outRail[iOut-1] * cmplx(1.0, -1.0));
            y <= (out[iOut] - out[iOut-2]) * cmplx(fxptTruncate(yy.rel), fxptTruncate(yy.img));

            mmVal <= y.rel - x.rel;
            mu <= mu + fromInteger(sps) + fxptSignExtend(0.3 * mmVal);
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
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

    method Action addSample (Complex#(FixedPoint#(4, 12)) sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(FixedPoint#(12, 9)) getError;
        tedErrorCalc.waitTillDone();
        return mu;
    endmethod

endmodule: mkMMTEDO

endpackage: MMTED_optimal
