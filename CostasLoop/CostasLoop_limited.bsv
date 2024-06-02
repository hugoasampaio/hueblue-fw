package CostasLoop_limited;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic_limited::*;
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

    FIFO#(COMPLEX_SAMPLE_TYPE) inSampleF  <- mkFIFO;
    FIFO#(COMPLEX_SAMPLE_TYPE) outSampleF <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE)  inSample   <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE)  outSample  <- mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) phase <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) freq <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) error <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitPhase <- mkCBRegRW(CRAddr{a: 8'd31, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitError <- mkCBRegRW(CRAddr{a: 8'd32, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitFreqs <- mkCBRegRW(CRAddr{a: 8'd33, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitIn    <- mkCBRegRW(CRAddr{a: 8'd34, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitOut   <- mkCBRegRW(CRAddr{a: 8'd35, o:0}, fromInteger(cleanMask));

    

    Cordic_IFC fixFxError <- mkRotate;
    
    Stmt calcError = seq
        action
        inSample <= inSampleF.first;
        inSampleF.deq;
        endaction
        inSample.rel.f <= inSample.rel.f & limitIn;
        inSample.img.f <= inSample.img.f & limitIn;
        fixFxError.setPolar(inSample.rel, inSample.img, -phase);
        action
        let polar <- fixFxError.getPolar();
        outSample <= polar;
        endaction
        outSample.rel.f <= outSample.rel.f & limitOut;
        outSample.img.f <= outSample.img.f & limitOut;
        action
        outSampleF.enq(outSample);
        error <= outSample.rel * outSample.img;
        endaction
        error.f <= error.f & limitError;
        freq <= freq + (error * 0.00932);
        freq.f <= freq.f & limitFreqs;
        phase <= phase + freq + (error * 0.132);
        phase.f <= phase.f & limitPhase;
        
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
        inSampleF.enq(ns);
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSample;
        let ret = outSampleF.first;
        outSampleF.deq;
        return ret;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        return error;
    endmethod


endmodule: mkCostasLoop

endpackage: CostasLoop_limited
