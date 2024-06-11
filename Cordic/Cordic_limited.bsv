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

    Stmt cordicFSM = seq
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

    FSM atanCalc <- mkFSM(cordicFSM);

/*
    rule init;
        atanCalc.start;
    endrule
*/
    method Action setPolar(REAL_SAMPLE_TYPE x, 
    REAL_SAMPLE_TYPE y, 
    REAL_SAMPLE_TYPE z);
        x_in.enq(x);
        y_in.enq(y);
        z_in.enq(z);
        atanCalc.start;
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

    method ActionValue #(COMPLEX_SAMPLE_TYPE) getPolar();
       let a = x_out.first;
        x_out.deq;
        let b = y_out.first;
        y_out.deq;
        return (cmplx(a * 0.607253, b * 0.607253));
    endmethod

endmodule
endpackage : Cordic_limited

/*    
    if (y_ > 0) begin
    x_ <= x_ + (y_ >> n);
    y_ <= y_ - (x_ >> n);
    sumAngle <= sumAngle + angles[n];
    end
    else begin
    x_ <= x_ - (y_ >> n);
    y_ <= y_ + (x_ >> n);
    sumAngle <= sumAngle - angles[n];
    end

if (z > 1.570796) begin
            bigAngle<= True;
            z_ <= z - 2*(z - 1.570796);
        end else if (z < (-1.570796)) begin
            bigAngle<= True;
            z_ <= z + 2*(z + 1.570796);
        end else


*/