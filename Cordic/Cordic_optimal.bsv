package Cordic_optimal;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Constants::*;

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
endinterface: Cordic_IFC
(* synthesize *)
module mkRotate (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) x_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) y_ <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) z_ <- mkReg(0);
    FIFO#(REAL_SAMPLE_TYPE) ix <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) iy <- mkFIFO;
    FIFO#(REAL_SAMPLE_TYPE) iz <- mkFIFO;

    Stmt cordicFSM = seq
        x_ <= ix.first;
        ix.deq;
        y_ <= iy.first;
        iy.deq;
        z_ <= iz.first;
        iz.deq;
        //45 degree
        while (z_ > angles[0]) action
                x_ <= (x_ - y_) * kForNinety;
                y_ <= (y_ + x_) * kForNinety;
                z_ <= z_ - angles[0];
        endaction
        
        while (z_ < angles[0]) action
                x_ <= (x_ + y_) * kForNinety;
                y_ <= (y_ - x_) * kForNinety;
                z_ <= z_ + angles[0];
        endaction
 
        for(n <= 0; n < fromInteger(nAngles); n <= n+1) seq
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
        endseq
    endseq;

    FSM atanCalc <- mkFSM(cordicFSM);

    method Action setPolar(REAL_SAMPLE_TYPE x, 
    REAL_SAMPLE_TYPE y, 
    REAL_SAMPLE_TYPE z);
        ix.enq(x);
        iy.enq(y);
        iz.enq(z);
        atanCalc.start;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getX();
        atanCalc.waitTillDone();
        return (x_ * 0.607253);
        //return x_;
    endmethod

    method ActionValue #(REAL_SAMPLE_TYPE) getY();
        atanCalc.waitTillDone();
        return (y_ * 0.607253);
        //return y_;
    endmethod

endmodule: mkRotate
endpackage : Cordic_optimal
