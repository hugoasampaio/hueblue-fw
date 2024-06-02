package CostasLoop_optimal;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;
import Constants::*;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface CostasLoop_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE ns);
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
endinterface: CostasLoop_IFC

module mkCostasLoop (CostasLoop_IFC);

    FIFO#(COMPLEX_SAMPLE_TYPE) inSample <- mkFIFO;
    FIFO#(COMPLEX_SAMPLE_TYPE) outSample <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE) sample <- mkReg(0);

    Reg#(FixedPoint#(INTEGERSIZE, 6)) phase <- mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 9)) freq <- mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 6)) error <- mkReg(0);

    Cordic_IFC fixFxError <- mkRotate;
    
    Stmt calcError = seq
        //sample <= inSample.first;
        action
        fixFxError.setPolar(inSample.first.rel, inSample.first.img, fxptSignExtend(-phase));
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

    method Action addSample (COMPLEX_SAMPLE_TYPE ns);
        inSample.enq(ns);
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
        let ret = outSample.first;
        outSample.deq;
        return ret;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        return fxptSignExtend(error);
    endmethod


endmodule: mkCostasLoop

endpackage: CostasLoop_optimal
