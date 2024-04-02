package CostasLoop;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCostasLoop;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface CostasLoop_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE ns);
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
endinterface: CostasLoop_IFC

module [LimitedOps] mkCostasLoop (CostasLoop_IFC);

    FIFO#(COMPLEX_SAMPLE_TYPE) inSample <- mkFIFO;
    FIFO#(COMPLEX_SAMPLE_TYPE) outSample <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE) sample <- mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) phase <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) freq <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) error <- mkReg(0);  

    Reg#(Bit#(CBDATASIZE)) limitPhase <- mkCBRegRW(CRAddr{a: 8'd8, o:0}, 'hffff);
    Reg#(Bit#(CBDATASIZE)) limitError <- mkCBRegRW(CRAddr{a: 8'd9, o:0},  'hffff);
    Reg#(Bit#(CBDATASIZE)) limitFreqs <- mkCBRegRW(CRAddr{a: 8'd10, o:0},  'hffff);

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
        error.f <= error.f & limitError;
        freq <= freq + (error * 0.00932);
        freq.f <= freq.f & limitFreqs;
        phase <= phase + freq + (error * 0.132);
        phase.f <= phase.f & limitPhase;
        
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

    method Action addSample (COMPLEX_SAMPLE_TYPE ns);
        inSample.enq(ns);
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
        let ret = outSample.first;
        outSample.deq;
        return ret;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        return error;
    endmethod


endmodule: mkCostasLoop

endpackage: CostasLoop
