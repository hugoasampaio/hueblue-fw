package CostasLoop_optimal;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic_cl::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
/*optimal: [11, 12, 6, 11, 11, 9, 9, 11]*/
interface CostasLoop_IFC;
    method Action addSample (Complex#(FixedPoint#(4, 7)) ns);
    method ActionValue #(Complex#(FixedPoint#(4, 7))) getFixedSample;
    method ActionValue #(FixedPoint#(4, 7)) getError;
endinterface: CostasLoop_IFC

module mkCostasLoop (CostasLoop_IFC);

    FIFO#(Complex#(FixedPoint#(4, 7))) inSample <- mkFIFO;
    FIFO#(Complex#(FixedPoint#(4, 7))) outSample <- mkFIFO;
    Reg#(Complex#(FixedPoint#(4, 7))) sample <- mkReg(0);

    Reg#(FixedPoint#(4, 6)) phase <- mkReg(0);
    Reg#(FixedPoint#(4, 9)) freq <- mkReg(0);
    Reg#(FixedPoint#(4, 6)) error <- mkReg(0);

    Cordic_IFC fixFxError <- mkRotate;
    
    Stmt calcError = seq
        //sample <= inSample.first;
        action
        fixFxError.setPolar(inSample.first.rel, inSample.first.img, fxptTruncate(-phase));
        inSample.deq;
        endaction
        action
        let polar <- fixFxError.getPolar();
        sample <= polar;
        endaction
        action
        outSample.enq(sample);
        error <= fxptTruncate(sample.rel * sample.img);
        endaction
        freq <= freq + fxptSignExtend(error * 0.00932);
        phase <= phase + fxptTruncate(freq) + (error * 0.132);
        
        //the cordic works +90 to -90
        while (phase > (3.14159/2)) seq
            phase <= phase - (3.14159/2);
        endseq

        while (phase < -(3.14159/2)) seq
            phase <= phase + (3.14159/2);
        endseq
    endseq;

    FSM costasL <- mkFSM(calcError);

    rule init;
        costasL.start;
    endrule

    method Action addSample (Complex#(FixedPoint#(4, 7)) ns);
        inSample.enq(ns);
    endmethod

    method ActionValue #(Complex#(FixedPoint#(4, 7))) getFixedSample;
        let ret = outSample.first;
        outSample.deq;
        return ret;
    endmethod

    method ActionValue #(FixedPoint#(4, 7)) getError;
        return fxptSignExtend(error);
    endmethod


endmodule: mkCostasLoop

endpackage: CostasLoop_optimal
