package CoarseFreq;

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
        for (n <= 30; n < (30+4*fromInteger(sps)); n <= n+1) seq
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
        fsError <=  0.159155 * atan(accumError.rel, accumError.img);
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

endpackage: CoarseFreq
