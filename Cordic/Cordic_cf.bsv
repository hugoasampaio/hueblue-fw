package Cordic_cf;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Complex::*;
import Constants::*;

Integer nAngles = 14;

FixedPoint#(4, 7) angles[nAngles] = {
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

FixedPoint#(4, 3) kForNinety = 0.70712;

interface Cordic_IFC;
    method Action setPolar(FixedPoint#(4, 3) x, 
                           FixedPoint#(4, 3) y, 
                           FixedPoint#(4, 7) z);
    method ActionValue #(FixedPoint#(4, 3)) getX();
    method ActionValue #(FixedPoint#(4, 3)) getY();
    method ActionValue #(FixedPoint#(4, 7)) getZ();
    method ActionValue #(Complex#(FixedPoint#(4, 3))) getPolar();
endinterface: Cordic_IFC

module mkRotate (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(FixedPoint#(4, 3)) x_ <- mkReg(0);
    Reg#(FixedPoint#(4, 3)) y_ <- mkReg(0);
    Reg#(FixedPoint#(4, 6)) z_ <- mkReg(0);

    Reg#(FixedPoint#(4, 3)) x2 <- mkReg(0);
    Reg#(FixedPoint#(4, 3)) y2 <- mkReg(0);
    Reg#(FixedPoint#(4, 6)) z2 <- mkReg(0);

    FIFO#(FixedPoint#(4, 3)) x_in <- mkFIFO;
    FIFO#(FixedPoint#(4, 3)) y_in <- mkFIFO;
    FIFO#(FixedPoint#(4, 6)) z_in <- mkFIFO;
    
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
        while (z_ > fxptTruncate(angles[0])) action
                x_ <= (x_ - y_) * kForNinety;
                y_ <= (y_ + x_) * kForNinety;
                z_ <= z_ - fxptTruncate(angles[0]);
        endaction
        
        while (z_ < fxptTruncate(angles[0])) action
                x_ <= (x_ + y_) * kForNinety;
                y_ <= (y_ - x_) * kForNinety;
                z_ <= z_ + fxptTruncate(angles[0]);
        endaction
 
        action
        x2 <= x_;
        y2 <= y_;
        z2 <= z_;
        n <= 0;
        endaction

        while (n < fromInteger(nAngles)) seq
            action
            if (z2 > 0.0) begin
                x2 <= x2 - (y2 >> n);
                y2 <= y2 + (x2 >> n);
                z2 <= z2 - fxptTruncate(angles[n]);
            end else begin
                x2 <= x2 + (y2 >> n);
                y2 <= y2 - (x2 >> n);
                z2 <= z2 + fxptTruncate(angles[n]);
            end
            n <= n+1;
            endaction
        endseq
    endseq;

    FSM atanCalc <- mkFSM(cordicFSM);

    rule init;
        atanCalc.start;
    endrule

    method Action setPolar(FixedPoint#(4, 3) x, 
    FixedPoint#(4, 3) y, 
    FixedPoint#(4, 7) z);
        x_in.enq(x);
        y_in.enq(y);
        z_in.enq(fxptTruncate(z));
    endmethod

    method ActionValue #(FixedPoint#(4, 3)) getX();
        atanCalc.waitTillDone();
        return (x2 * 0.607253);
        //return x_;
    endmethod

    method ActionValue #(FixedPoint#(4, 3)) getY();
        atanCalc.waitTillDone();
        return (y2 * 0.607253);
        //return y_;
    endmethod

    method ActionValue #(FixedPoint#(4, 7)) getZ();
        return(0.0);
    endmethod

    method ActionValue #(Complex#(FixedPoint#(4, 3))) getPolar();
        atanCalc.waitTillDone();
        return (cmplx(x2 * 0.607253, y2 * 0.607253));
    endmethod

endmodule: mkRotate

module mkAtan (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(FixedPoint#(4, 0)) x_ <- mkReg(0);
    Reg#(FixedPoint#(4, 3)) y_ <- mkReg(0);
    Reg#(FixedPoint#(4, 7)) z_ <- mkReg(0);

    FIFO#(FixedPoint#(4, 0)) x_in <- mkFIFO;
    FIFO#(FixedPoint#(4, 3)) y_in <- mkFIFO;

    FIFO#(FixedPoint#(4, 7)) z_out <- mkFIFO;

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
                x_ <= x_ + fxptTruncate(y_) ;
                y_ <= y_ - fxptSignExtend(x_) ;
                z_ <= z_ + angles[0];
            end else begin
                x_ <= x_ - fxptTruncate(y_);
                y_ <= y_ + fxptSignExtend(x_);
                z_ <= z_ - angles[0];
            end
            endaction
        endseq
        
        for (n <=0; n < fromInteger(nAngles); n<=n+1) seq
            action
            if (y_ >= 0.0) begin
                x_ <= x_ + fxptTruncate(y_ >> n);
                y_ <= y_ - fxptSignExtend(x_ >> n);
                z_ <= z_ + angles[n];
            end else begin
                x_ <= x_ - fxptTruncate(y_ >> n);
                y_ <= y_ + fxptSignExtend(x_ >> n);
                z_ <= z_ - angles[n];
            end
            endaction
        endseq
        action
        z_out.enq(z_);
        endaction
    endseq;

    FSM atanCalc <- mkFSM(atanFSM);

    method Action setPolar(FixedPoint#(4, 3) x, 
    FixedPoint#(4, 3) y, 
    FixedPoint#(4, 7) z);
        x_in.enq(fxptTruncate(x));
        y_in.enq(y);
        atanCalc.start;
    endmethod

    method ActionValue #(FixedPoint#(4, 3)) getX();
        return (0.0);
    endmethod

    method ActionValue #(FixedPoint#(4, 3)) getY();
        return (0.0);
    endmethod

    method ActionValue #(FixedPoint#(4, 7)) getZ();
        let c = z_out.first;
        z_out.deq;
        return (c);
    endmethod

    method ActionValue #(Complex#(FixedPoint#(4, 3))) getPolar();
        return (cmplx(0.0, 0.0));
    endmethod

endmodule: mkAtan
endpackage: Cordic_cf
