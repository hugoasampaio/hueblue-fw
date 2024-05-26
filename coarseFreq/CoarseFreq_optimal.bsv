package CoarseFreq_optimal;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic_optimal::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 20;

interface CoarseFreq_IFC;
    method Action addSample (Complex#(FixedPoint#(INTEGERSIZE, 6)) sample);
    method ActionValue #(FixedPoint#(INTEGERSIZE, CBDATASIZE)) getError;
endinterface: CoarseFreq_IFC

//based on understanding dsp equation
function FixedPoint#(INTEGERSIZE, CBDATASIZE) atan(FixedPoint#(INTEGERSIZE, CBDATASIZE) x, FixedPoint#(INTEGERSIZE, CBDATASIZE) y);
 
    FixedPoint#(INTEGERSIZE, CBDATASIZE) xAbs = x;
    FixedPoint#(INTEGERSIZE, CBDATASIZE) yAbs = y;
    FixedPoint#(INTEGERSIZE, CBDATASIZE) x_ = x;
    FixedPoint#(INTEGERSIZE, CBDATASIZE) y_ = y;
    FixedPoint#(INTEGERSIZE, CBDATASIZE) ret = 0.0;

    Bool yPos = True;

    if (yAbs < 0.0) begin
        yAbs = yAbs * -1.0;
        yPos = False;
    end

    if (xAbs < 0.0) begin
        xAbs = xAbs * -1.0;
    end

    //1th and 8th octants
    if (x >= 0.0 && (xAbs > yAbs)) begin
        ret = ((x_ * y_) / ((x_ * x_) + (y_ * y_ * 0.28125)));
    end

    //2nd and 3rd octants
    if (y >= 0.0 && (yAbs >= xAbs)) begin
        ret = 1.570796 - ((x_ * y_) / ((y_ * y_) + (x_ * x_ * 0.28125)));
    end
    //4th and 5th octants
    if (x < 0.0 && (xAbs > yAbs)) begin
        if (yPos == True) begin
            ret = 3.14159 + ((x_ * y_) / ((x_ * x_) + (y_ * y_ * 0.28125)));
        end 
        else begin
            ret = -3.14159 + ((x_ * y_) / ((x_ * x_) + (y_ * y_ * 0.28125)));
        end 
    end
    if (y < 0.0 && (yAbs >= xAbs)) begin
        ret = -1.570796 - ((x_ * y_) / ((y_ * y_) + (x_ * x_ * 0.28125)));
    end
    return fxptTruncate(ret);

endfunction: atan

module mkCoarseFreqO (CoarseFreq_IFC);
    Vector#(20, Reg#(Complex#(FixedPoint#(INTEGERSIZE, 6)))) samples <-replicateM(mkReg(0));
    FIFO#(Complex#(FixedPoint#(INTEGERSIZE, 6))) newSample <- mkFIFO;
    Reg#(Complex#(FixedPoint#(INTEGERSIZE, 6))) lastSample <-mkReg(0);
    Reg#(Complex#(FixedPoint#(INTEGERSIZE, 6))) currSample <-mkReg(0);
    Reg#(Complex#(FixedPoint#(INTEGERSIZE, 9))) accumError <- mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 12)) fsError <- mkReg(0);
    
    Reg#(FixedPoint#(INTEGERSIZE, 9)) xFix <- mkReg(1.0);
    Reg#(FixedPoint#(INTEGERSIZE, 9)) yFix <- mkReg(0.0);

    Reg#(UInt#(10)) n <- mkReg(0);

    Cordic_IFC cordic <- mkRotate;

    Stmt calcError = seq
        lastSample <= cmplx(0,0);
        currSample <= cmplx(0,0);
        accumError <= cmplx(0,0);
        fsError    <= 0;
        for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            samples[n] <= newSample.first;
            newSample.deq;
        endseq
        for (n <= 0; n < 20; n <= n+1) seq
            currSample <= samples[n];
            lastSample.img <=  lastSample.img * -1.0; //conjugado
            lastSample <= (currSample * lastSample);
            accumError <= accumError + cmplx(fxptSignExtend(lastSample.rel), fxptSignExtend(lastSample.img));
            lastSample <= currSample;
            samples[n] <= currSample;
        endseq
        // 1/(2*pi)
        fsError <=  0.159155 * atan(fxptSignExtend(accumError.rel), fxptSignExtend(accumError.img));

        for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            samples[n] <= samples[n] * cmplx(fxptTruncate(xFix), fxptTruncate(yFix));
            cordic.setPolar(fxptSignExtend(xFix), fxptSignExtend(yFix), -2.0 * 3.141593 * fsError);
            action
            let x_rot <- cordic.getX;
            let y_rot <- cordic.getY;
            xFix <= fxptTruncate(x_rot);
            yFix <= fxptTruncate(y_rot);
            endaction
            action
            fxptWrite(6, samples[n].rel);
            $write(", ");
            fxptWrite(6, samples[n].img);
            $display(" ");
            endaction
        endseq
    endseq;

    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (Complex#(FixedPoint#(INTEGERSIZE, 6)) sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(FixedPoint#(INTEGERSIZE, CBDATASIZE)) getError;
        coarseErrorCalc.waitTillDone();
        return fsError;
    endmethod

endmodule: mkCoarseFreqO

endpackage: CoarseFreq_optimal
