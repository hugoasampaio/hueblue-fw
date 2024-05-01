package CoarseFreq;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCoarseFreq;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 445;

interface CoarseFreq_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
    //method ActionValue #(Vector#(64, Reg#(Sample_Type))) getFixedSamples;
endinterface: CoarseFreq_IFC

//based on understanding dsp equation
function REAL_SAMPLE_TYPE atan(REAL_SAMPLE_TYPE x, REAL_SAMPLE_TYPE y);
 
    REAL_SAMPLE_TYPE xAbs = x;
    REAL_SAMPLE_TYPE yAbs = y;
    REAL_SAMPLE_TYPE x_ = x;
    REAL_SAMPLE_TYPE y_ = y;
    REAL_SAMPLE_TYPE ret = 0.0;

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

module [LimitedOps] mkCoarseFreq (CoarseFreq_IFC);
    Vector#(446, Reg#(COMPLEX_SAMPLE_TYPE)) samples <-replicateM(mkReg(0));
    FIFO#(COMPLEX_SAMPLE_TYPE) newSample <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE) lastSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) currSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) accumError <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) fsError <- mkReg(0);
    
    Reg#(REAL_SAMPLE_TYPE) xFix <- mkReg(1.0);
    Reg#(REAL_SAMPLE_TYPE) yFix <- mkReg(0.0);

    Reg#(UInt#(10)) n <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitCurrS  <- mkCBRegRW(CRAddr{a: 8'd11, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitLastS  <- mkCBRegRW(CRAddr{a: 8'd12, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitAccumE <- mkCBRegRW(CRAddr{a: 8'd13, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitError  <- mkCBRegRW(CRAddr{a: 8'd14, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitCpxFix <- mkCBRegRW(CRAddr{a: 8'd15, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitXFix   <- mkCBRegRW(CRAddr{a: 8'd16, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitYFix   <- mkCBRegRW(CRAddr{a: 8'd17, o:0}, fromInteger(cleanMask));

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
        for (n <= 30; n < (30+16*fromInteger(sps)); n <= n+1) seq
            currSample <= samples[n];
            /*
            $write(currSample.rel.f);
            $write(", ");
            $write(currSample.img.f);
            $display(" a");
            */
            currSample.rel.f <= currSample.rel.f & limitCurrS;
            currSample.img.f <= currSample.img.f & limitCurrS;
            /*
            $write(currSample.rel.f);
            $write(", ");
            $write(currSample.img.f);
            $display(" d");
            */
            lastSample.img <=  lastSample.img * -1.0; //conjugado
            lastSample.rel.f <= lastSample.rel.f & limitLastS;
            lastSample.img.f <= lastSample.img.f & limitLastS;

            accumError <= accumError + (currSample * lastSample);
            accumError.rel.f <= accumError.rel.f & limitAccumE;
            accumError.img.f <= accumError.img.f & limitAccumE;

            /*
            fxptWrite(6, accumError.rel);
            $write(", ");
            fxptWrite(6, accumError.img);
            $display(" ");
            */
            lastSample <= currSample;
            samples[n] <= currSample;
        endseq
        // 1/(2*pi)
        fsError <=  0.159155 * atan(accumError.rel, accumError.img);
        fsError.f <= fsError.f & limitError;

        /*
        $write("fs: ");
        fxptWrite(6, fsError);
        $display(" ");
        */

        for (n <= 0; n < fromInteger(loopFix); n <= n+1) seq
            samples[n] <= samples[n] * cmplx(xFix, yFix);
            samples[n].rel.f <= samples[n].rel.f & limitCpxFix;
            samples[n].img.f <= samples[n].img.f & limitCpxFix; 
            cordic.setPolar(xFix, yFix, -2.0 * 3.141593 * fsError);
            action
            let x_rot <- cordic.getX;
            let y_rot <- cordic.getY;
            xFix <= x_rot;
            yFix <= y_rot;
            endaction
            xFix.f <= xFix.f & limitXFix;
            yFix.f <= yFix.f & limitYFix;
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

    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getError;
        coarseErrorCalc.waitTillDone();
        return fsError;
    endmethod

endmodule: mkCoarseFreq

endpackage: CoarseFreq
