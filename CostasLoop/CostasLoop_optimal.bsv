package CostasLoop_optimal;

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

interface CostasLoopO_IFC;
    method Action addSample (Complex#(FixedPoint#(INTEGERSIZE, 12)) ns);
    method ActionValue #(Complex#(FixedPoint#(INTEGERSIZE, 12))) getFixedSample;
    method ActionValue #(FixedPoint#(INTEGERSIZE, 12)) getError;
endinterface: CostasLoopO_IFC

(* synthesize *)
module mkCostasLoopO (CostasLoopO_IFC);

    FIFO#(Complex#(FixedPoint#(INTEGERSIZE, 12))) inSample <- mkFIFO;
    FIFO#(Complex#(FixedPoint#(INTEGERSIZE, 12))) outSample <- mkFIFO;
    Reg#(Complex#(FixedPoint#(INTEGERSIZE, 12))) sample <- mkReg(0);

    Reg#(FixedPoint#(INTEGERSIZE, 6)) phase <- mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 3)) freq <- mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 6)) error <- mkReg(0);  

    Cordic_IFC fixFxError <- mkRotate;
    
    Stmt calcError = seq
        //sample <= inSample.first;
        fixFxError.setPolar(inSample.first.rel, inSample.first.img, fxptSignExtend(-phase));
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
        error <= fxptTruncate(sample.rel * sample.img);
        freq <= freq + fxptTruncate(error * 0.00932);
        phase <= phase + fxptSignExtend(freq) + (error * 0.132);
        
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

    method Action addSample (Complex#(FixedPoint#(INTEGERSIZE, 12)) ns);
        inSample.enq(ns);
    endmethod

    method ActionValue #(Complex#(FixedPoint#(INTEGERSIZE, 12))) getFixedSample;
        let ret = outSample.first;
        outSample.deq;
        return ret;
    endmethod

    method ActionValue #(FixedPoint#(INTEGERSIZE, 12)) getError;
        return fxptSignExtend(error);
    endmethod


endmodule: mkCostasLoopO

endpackage: CostasLoop_optimal
