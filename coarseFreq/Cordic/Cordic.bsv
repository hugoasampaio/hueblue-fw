package Cordic;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;

typedef FixedPoint#(3, 16)  Angle_Type;
Integer nAngles = 14;

Angle_Type angles[nAngles] = {
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
    method Action setPolar(Angle_Type x, Angle_Type y);
    method ActionValue #(Angle_Type) getAtan;
endinterface: Cordic_IFC

(* synthesize *)
module mkAtan (Cordic_IFC);
    Reg#(Angle_Type) sumAngle <-mkReg(0);
    Reg#(UInt#(5)) n <- mkReg(0);
    Reg#(Angle_Type) x_ <- mkReg(0);
    Reg#(Angle_Type) y_ <- mkReg(0);

    Stmt cordicFSM = seq
        for(n <=0; n < fromInteger(nAngles); n <= n+1) action
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
        endaction
    endseq;

    FSM atanCalc <- mkFSM(cordicFSM);

    method Action setPolar(Angle_Type x, Angle_Type y);
        when((atanCalc.done),
        (action 
        x_ <= x;
        y_ <= y;
        endaction));
        atanCalc.start;
    endmethod

    method ActionValue #(Angle_Type) getAtan;
        atanCalc.waitTillDone();
        return sumAngle;
    endmethod
endmodule
endpackage : Cordic