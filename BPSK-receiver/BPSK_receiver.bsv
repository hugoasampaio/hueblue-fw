package BPSK_receiver;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedBPSKReceiver;

Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;
Integer loopFix = 445;

interface BPSK_receiver_IFC;
    method Action addSample (COMPLEX_SAMPLE_TYPE sample);
    method ActionValue #(REAL_SAMPLE_TYPE) getError;
    //method ActionValue #(Vector#(64, Reg#(Sample_Type))) getFixedSamples;
endinterface: BPSK_receiver_IFC

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

module [LimitedOps] mkBPSK_receiver (BPSK_receiver_IFC);
    //delay & multiply
    Vector#(465, Reg#(COMPLEX_SAMPLE_TYPE)) samples <-replicateM(mkReg(0));
    FIFO#(COMPLEX_SAMPLE_TYPE) newSample <- mkFIFO;
    Reg#(COMPLEX_SAMPLE_TYPE) lastSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) currSample <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) accumError <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) fsError <- mkReg(0);
    
    Reg#(REAL_SAMPLE_TYPE) xFix <- mkReg(1.0);
    Reg#(REAL_SAMPLE_TYPE) yFix <- mkReg(0.0);

    Reg#(UInt#(12)) n <- mkReg(0);

    //mmted
    Vector#(465, Reg#(COMPLEX_SAMPLE_TYPE)) out  <- replicateM(mkReg(0));
    Vector#(465, Reg#(COMPLEX_SAMPLE_TYPE)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(12)) iIn <- mkReg(0);
    Reg#(UInt#(12)) iOut <- mkReg(2);
    Reg#(COMPLEX_SAMPLE_TYPE) x <- mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) y <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) mmVal <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) mu <-mkReg(0);

    //Costas Loop
    Reg#(REAL_SAMPLE_TYPE) phase <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) freq <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) error <- mkReg(0);

    //delay  & multiply
    Reg#(Bit#(CBDATASIZE)) limitCurrS  <- mkCBRegRW(CRAddr{a: 8'd11, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitLastS  <- mkCBRegRW(CRAddr{a: 8'd12, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitAccumE <- mkCBRegRW(CRAddr{a: 8'd13, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitDMError  <- mkCBRegRW(CRAddr{a: 8'd14, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitCpxFix <- mkCBRegRW(CRAddr{a: 8'd15, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitXFix   <- mkCBRegRW(CRAddr{a: 8'd16, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitYFix   <- mkCBRegRW(CRAddr{a: 8'd17, o:0}, fromInteger(cleanMask));
    //mmted
    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd5, o:0},  fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd6, o:0},  fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitMu <- mkCBRegRW(CRAddr{a: 8'd7, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitOut <- mkCBRegRW(CRAddr{a: 8'd8, o:0},fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitMM <- mkCBRegRW(CRAddr{a: 8'd9, o:0}, fromInteger(cleanMask));
    //Costas Loop
    Reg#(Bit#(CBDATASIZE)) limitPhase <- mkCBRegRW(CRAddr{a: 8'd3, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitCLError <- mkCBRegRW(CRAddr{a: 8'd4, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitFreqs <- mkCBRegRW(CRAddr{a: 8'd10, o:0},fromInteger(cleanMask));
    //delay & multiply
    Cordic_IFC cordic <- mkRotate;
    //Costas Loop
    Cordic_IFC fixFxError <- mkRotate;

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
        fsError.f <= fsError.f & limitDMError;

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
        endseq

        while (iOut < fromInteger(loopFix) && iIn+16 < fromInteger(loopFix)) seq
            out[iOut] <= samples[iIn];
            outRail[iOut] <= cmplx( (out[iOut].rel > 0.0 ? 1.0 : 0.0) ,  (out[iOut].img > 0.0 ? 1.0 : 0.0));
            x <= (outRail[iOut] - outRail[iOut-2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));
            y <= (out[iOut] - out[iOut-2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));

            //apply limits
            x.rel.f <= x.rel.f & limitX;
            x.img.f <= x.img.f & limitX;
            y.rel.f <= y.rel.f & limitY;
            y.img.f <= y.img.f & limitY;

            mmVal <= y.rel-x.rel;
            mmVal.f <= mmVal.f & limitMM;
            mu <= mu + fromInteger(sps) + (0.3 * mmVal);
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            mu.f <= mu.f & limitMu;
            iOut <= iOut + 1;
        endseq

        for (n <= 2; n < iOut; n <= n +1 ) seq
            fixFxError.setPolar(out[n].rel, out[n].img, -phase);
            action
            let x <- fixFxError.getX();
            out[n].rel <= x;
            endaction
            action
            let y <- fixFxError.getY();
            out[n].img <= y;
            endaction
            error <= out[n].rel * out[n].img;
            error.f <= error.f & limitCLError;
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

            fxptWrite(6, out[n].rel);
            $write(", ");
            fxptWrite(6, out[n].img);
            $display(" ");

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

endmodule: mkBPSK_receiver

endpackage: BPSK_receiver
