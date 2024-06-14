package Cordic_limited;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Complex::*;
import CBus::*;
import Constants::*;

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCordic;

Integer nAngles = 14;

REAL_SAMPLE_TYPE angles[nAngles] = {
    0.7853981634,           //2^0
    0.46364760905065,       //2^-1
    0.24497866316245,       //2^-2
    0.12435499454817,       //2^-3
    0.062418809995849,      
    0.031239833425896,      
    0.01562372861675,       
    0.0078123410625155,
    0.00390623012553,
    0.0019531225153184,
    0.00097656219141037,
    0.00048828121787823,
    0.00024414061766576,
    0.00012207031755953    //2^-13
};

REAL_SAMPLE_TYPE kForNinety = 0.70712;

interface Cordic_IFC;
    method Action setPolar(REAL_SAMPLE_TYPE x, REAL_SAMPLE_TYPE y, REAL_SAMPLE_TYPE z);
    method ActionValue #(REAL_SAMPLE_TYPE) getX();
    method ActionValue #(REAL_SAMPLE_TYPE) getY();
    method ActionValue #(REAL_SAMPLE_TYPE) getZ();
    method ActionValue #(COMPLEX_SAMPLE_TYPE) getPolar();
endinterface: Cordic_IFC

module [LimitedOps] mkRotate (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) x_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) y_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) z_ <- mkReg(0);

    /*
    Reg#(REAL_SAMPLE_TYPE) x2 <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) y2 <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) z2 <- mkReg(0);
    */
    FIFO#(REAL_SAMPLE_TYPE) x_in <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) y_in <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) z_in <- mkFIFO;

    FIFO#(REAL_SAMPLE_TYPE) x_out <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) y_out <- mkFIFO;

    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd41, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd42, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitZ <- mkCBRegRW(CRAddr{a: 8'd43, o:0}, fromInteger(cleanMask));

    Stmt rotateFSM = seq
        action
            x_ <= x_in.first;
            y_ <= y_in.first;
            z_ <= z_in.first;
            x_in.deq;
            y_in.deq;
            z_in.deq;
        endaction
        //45 degree
        while (z_ > angles[0]) seq
        action
                x_ <= (x_ - y_) * kForNinety;
                y_ <= (y_ + x_) * kForNinety;
                z_ <= z_ - angles[0];
        endaction
        action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
        endaction
        endseq
        
        while (z_ < angles[0]) seq
        action
                x_ <= (x_ + y_) * kForNinety;
                y_ <= (y_ - x_) * kForNinety;
                z_ <= z_ + angles[0];
        endaction
        action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
        endaction
        endseq

        for (n <=0; n < fromInteger(nAngles); n<=n+1) seq
            action
            if (z_ > 0.0) begin
                x_ <= x_ - (y_ >> n);
                y_ <= y_ + (x_ >> n);
                z_ <= z_ - angles[n];
            end else begin
                x_ <= x_ + (y_ >> n);
                y_ <= y_ - (x_ >> n);
                z_ <= z_ + angles[n];
            end
            endaction

            action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
            endaction
        endseq
        action
            x_out.enq(x_);
            y_out.enq(y_);
        endaction
    endseq;

    FSM rotateCalc <- mkFSM(rotateFSM);

    method Action setPolar(REAL_SAMPLE_TYPE x, 
    REAL_SAMPLE_TYPE y, 
    REAL_SAMPLE_TYPE z);
        x_in.enq(x);
        y_in.enq(y);
        z_in.enq(z);
        rotateCalc.start;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getX();
        let a = x_out.first;
        x_out.deq;
        return (a * 0.607253);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getY();
        let b = y_out.first;
        y_out.deq;
        return (b * 0.607253);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getZ();
        return (0.0);
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getPolar();
       let a = x_out.first;
        x_out.deq;
        let b = y_out.first;
        y_out.deq;
        return (cmplx(a * 0.607253, b * 0.607253));
    endmethod
endmodule: mkRotate

module [LimitedOps] mkAtan (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) x_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) y_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) z_ <- mkReg(0);

    FIFO#(REAL_SAMPLE_TYPE) x_in <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) y_in <- mkFIFO;

    FIFO#(REAL_SAMPLE_TYPE) z_out <- mkFIFO;

    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd44, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd45, o:0}, fromInteger(cleanMask));
    Reg#(Bit#(CBDATASIZE)) limitZ <- mkCBRegRW(CRAddr{a: 8'd46, o:0}, fromInteger(cleanMask));

    Stmt atanFSM = seq
        action
            x_ <= x_in.first;
            y_ <= y_in.first;
            x_in.deq;
            y_in.deq;
            z_ <= 0;
        endaction
        /*45 degree*/
        while (x_ < 0.0) seq
        action
            if (y_ > 0.0) begin
                x_ <= x_ + y_ ;
                y_ <= y_ - x_ ;
                z_ <= z_ + angles[0];
            end else begin
                x_ <= x_ - y_;
                y_ <= y_ + x_;
                z_ <= z_ - angles[0];
            end
            endaction
            action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
            endaction
        endseq
        
        for (n <=0; n < fromInteger(nAngles); n<=n+1) seq
            action
            if (y_ >= 0.0) begin
                x_ <= x_ + (y_ >> n);
                y_ <= y_ - (x_ >> n);
                z_ <= z_ + angles[n];
            end else begin
                x_ <= x_ - (y_ >> n);
                y_ <= y_ + (x_ >> n);
                z_ <= z_ - angles[n];
            end
            endaction
            action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
            endaction
        endseq
        action
        z_out.enq(z_);
        endaction
    endseq;

    FSM atanCalc <- mkFSM(atanFSM);

    method Action setPolar(REAL_SAMPLE_TYPE x, 
    REAL_SAMPLE_TYPE y, 
    REAL_SAMPLE_TYPE z);
        x_in.enq(x);
        y_in.enq(y);
        atanCalc.start;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getX();
        return (0.0);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getY();
        return (0.0);
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getZ();
        let c = z_out.first;
        z_out.deq;
        return (c);
    endmethod

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getPolar();
        return (cmplx(0.0, 0.0));
    endmethod

endmodule: mkAtan
endpackage : Cordic_limited

/*based on understanding dsp equation
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
*/