package CoarseFreq_limited;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic_limited::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCoarseFreq;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 442;

interface CoarseFreq_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSamples;
    method Bool hasFixedSamples;
endinterface: CoarseFreq_IFC

module [LimitedOps] mkCoarseFreq (CoarseFreq_IFC);
    Vector#(446, Reg#(COMPLEX_SAMPLE_TYPE)) samples <-replicateM(mkReg(0));
    Reg#(COMPLEX_SAMPLE_TYPE) out <- mkReg(0);

    FIFO#(COMPLEX_SAMPLE_TYPE) newSample <- mkFIFO;
    FIFOF#(COMPLEX_SAMPLE_TYPE) outSample <- mkSizedFIFOF(445);
    Reg#(COMPLEX_SAMPLE_TYPE) lastSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) currSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) accumError <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) fsError <- mkReg(0);
    
    Reg#(REAL_SAMPLE_TYPE) xFix <- mkReg(1.0);
    Reg#(REAL_SAMPLE_TYPE) yFix <- mkReg(0.0);

    Reg#(UInt#(10)) n <- mkReg(0);
    Reg#(UInt#(10)) m <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitCurrS  <- mkCBRegRW(CRAddr{a: 8'd11, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitLastS  <- mkCBRegRW(CRAddr{a: 8'd12, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitAccumE <- mkCBRegRW(CRAddr{a: 8'd13, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitError  <- mkCBRegRW(CRAddr{a: 8'd14, o:0}, fromInteger(cleanMask));
    //Reg#(Bit#(CBDATASIZE)) limitCpxFix <- mkCBRegRW(CRAddr{a: 8'd15, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitXFix   <- mkCBRegRW(CRAddr{a: 8'd16, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitYFix   <- mkCBRegRW(CRAddr{a: 8'd17, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitIn   <- mkCBRegRW(CRAddr{a: 8'd18, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitOut  <- mkCBRegRW(CRAddr{a: 8'd19, o:0}, fromInteger(cleanMask));

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
            samples[n] <= newSample.first;
            samples[n].rel.f <= newSample.first.rel.f & limitIn;
            samples[n].img.f <= newSample.first.img.f & limitIn;
            newSample.deq;
        endseq
        for (n <= 30; n < (30+8*fromInteger(sps)); n <= n+1) seq
                currSample <= samples[n];
                currSample.rel.f <= currSample.rel.f & limitCurrS;
                currSample.img.f <= currSample.img.f & limitCurrS;
                
                lastSample.img <=  lastSample.img * -1.0; //conjugado
                lastSample.rel.f <= lastSample.rel.f & limitLastS;
                lastSample.img.f <= lastSample.img.f & limitLastS;
                
                accumError <= accumError + (currSample * lastSample);
                accumError.rel.f <= accumError.rel.f & limitAccumE;
                accumError.img.f <= accumError.img.f & limitAccumE;
                lastSample <= currSample;
        endseq
        // 1/(2*pi) = 0.159155
        atan.setPolar(accumError.rel, accumError.img, 0.0);
        action
        let z <- atan.getZ;
        fsError <=  0.159155 * z;
        endaction
        fsError.f <= fsError.f & limitError;
        
        for(n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            out <= samples[n] * cmplx(xFix, yFix);
            out.rel.f <= out.rel.f & limitOut;
            out.img.f <= out.img.f & limitOut; 
            outSample.enq(out);
            cordic.setPolar(xFix, yFix, (-2.0 * 3.141593 * fsError));
            action
            let x_rot <- cordic.getX();
            let y_rot <- cordic.getY();
            xFix <= x_rot;
            yFix <= y_rot;
            endaction
            xFix.f <= xFix.f & limitXFix;
            yFix.f <= yFix.f & limitYFix;
        endseq
        //fxptWrite(6,fsError);
        //$display(" ");
    endseq;
    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        coarseErrorCalc.waitTillDone();
        return fsError;
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getFixedSamples;
        let x = outSample.first;
        outSample.deq;
        return x;
    endmethod

    method hasFixedSamples = outSample.notEmpty;

endmodule: mkCoarseFreq

endpackage: CoarseFreq_limited
