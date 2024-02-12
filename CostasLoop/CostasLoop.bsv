package CostasLoop;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;

typedef FixedPoint#(7, 16)      SampleType;
typedef Complex#(SampleType)    ComplexSampleType;
Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface CostasLoop_IFC;
    method Action addSample (ComplexSampleType ns);
    method ActionValue #(ComplexSampleType) getFixedSample;
    method ActionValue #(SampleType) getError;
endinterface: CostasLoop_IFC

(* synthesize *)
module mkCostasLoop (CostasLoop_IFC);

    FIFO#(ComplexSampleType) inSample <- mkFIFO;
    FIFO#(ComplexSampleType) outSample <- mkFIFO;
    Reg#(ComplexSampleType) sample <- mkReg(0);

    Reg#(SampleType) phase <- mkReg(0);
    Reg#(SampleType) freq <- mkReg(0);
    Reg#(SampleType) error <- mkReg(0);    

    Cordic_IFC fixFxError <- mkRotate;
    
    Stmt calcError = seq
        //sample <= inSample.first;
        fixFxError.setPolar(inSample.first.rel, inSample.first.img, -phase);
        inSample.deq;
        action
        let x <- fixFxError.getX();
        sample.rel <= x;
        endaction
        action
        let y <- fixFxError.getY();
        sample.img <= y;
        endaction
        outSample.enq(sample);
        error <= sample.rel * sample.img;
        freq <= freq + (error * 0.00932);
        phase <= phase + freq + (error * 0.132);

        //the cordic works +45 to -45
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

    method Action addSample (ComplexSampleType ns);
        inSample.enq(ns);
    endmethod

    method ActionValue #(ComplexSampleType) getFixedSample;
        let ret = outSample.first;
        outSample.deq;
        return ret;
    endmethod

    method ActionValue #(SampleType) getError;
        return error;
    endmethod


endmodule: mkCostasLoop

endpackage: CostasLoop
