package Cordic;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;

//typedef FixedPoint#(4, 16)  FixedPoint#(4, 16);
Integer nAngles = 14;

FixedPoint#(7, 16) angles[nAngles] = {
    0.785398,
    0.46364760905065,
    0.24497866316245,
    0.12435499454817,
    0.062418809995849,
    0.031239833425896,
    0.01562372861675,
    0.0078123410625155,
    0.00390623012553,
    0.0019531225153184,
    0.00097656219141037,
    0.00048828121787823,
    0.00024414061766576,
    0.00012207031755953
};

interface Cordic_IFC;
    method Action setPolar(FixedPoint#(7, 16) x, FixedPoint#(7, 16) y, FixedPoint#(7, 16) z);
    //method ActionValue #(Fasor) getRotate;
    method ActionValue #(FixedPoint#(7, 16)) getX();
    method ActionValue #(FixedPoint#(7, 16)) getY();
endinterface: Cordic_IFC

(* synthesize *)
module mkRotate (Cordic_IFC);
    Reg#(FixedPoint#(7, 16)) sumAngle <-mkReg(0);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(FixedPoint#(7, 16)) x_ <- mkReg(0);
    Reg#(FixedPoint#(7, 16)) y_ <- mkReg(0);
    Reg#(FixedPoint#(7, 16)) z_ <- mkReg(0);
    Reg#(bit) signZ <- mkReg(0);

    Stmt cordicFSM = seq
        for(n <=0; n < fromInteger(nAngles); n <= n+1) action
        if (z_ >= 0.0) begin
            signZ <= 1;
        end else begin
            signZ <= 0;
        end

        if (signZ == 0) begin
            x_ <= x_ - (y_ >> n);
            y_ <= y_ + (x_ >> n);
            z_ <= z_ - angles[n];
        end else begin
            x_ <= x_ + (y_ >> n);
            y_ <= y_ - (x_ >> n);
            z_ <= z_ + angles[n];
        end

        endaction
    endseq;

    FSM atanCalc <- mkFSM(cordicFSM);

    method Action setPolar(FixedPoint#(7, 16) x, FixedPoint#(7, 16) y, FixedPoint#(7, 16) z);
        when((atanCalc.done),
        (action 
        x_ <= x;
        y_ <= y;
        z_ <= z;
        endaction));
        atanCalc.start;
    endmethod

/*
    method ActionValue #(Fasor) getRotate;
        atanCalc.waitTillDone();
        Fasor ret; 
        ret = Fasor{x: x_, y: y_};
        return (ret);
    endmethod
*/
    method ActionValue #(FixedPoint#(7, 16)) getX();
        atanCalc.waitTillDone();
        return (x_);
    endmethod

    method ActionValue #(FixedPoint#(7, 16)) getY();
        atanCalc.waitTillDone();
        return (y_);
    endmethod

endmodule
endpackage : Cordic

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
*/