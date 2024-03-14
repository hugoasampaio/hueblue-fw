package Cordic;

import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import CBus::*;

typedef 8    CBADDRSIZE; //size of configuration address bus to decode
typedef 16   CBDATASIZE; //size of configuration data bus

typedef ModWithCBus#(CBADDRSIZE, CBDATASIZE, j)         LimitedOps#(type j);
typedef CBus#(CBADDRSIZE, CBDATASIZE)                   LimitedCordic;

//typedef FixedPoint#(4, 16)  FixedPoint#(4, 16);
Integer nAngles = 14;

FixedPoint#(7, CBDATASIZE) angles[nAngles] = {
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

FixedPoint#(7, CBDATASIZE) kForNinety = 0.70712;

interface Cordic_IFC;
    method Action setPolar(FixedPoint#(7, 16) x, FixedPoint#(7, 16) y, FixedPoint#(7, 16) z);
    method ActionValue #(FixedPoint#(7, 16)) getX();
    method ActionValue #(FixedPoint#(7, 16)) getY();
endinterface: Cordic_IFC

module [LimitedOps] mkRotate (Cordic_IFC);
    Reg#(UInt#(4)) n <- mkReg(0);
    Reg#(FixedPoint#(7, CBDATASIZE)) x_ <- mkReg(0);
    Reg#(FixedPoint#(7, CBDATASIZE)) y_ <- mkReg(0);
    Reg#(FixedPoint#(7, CBDATASIZE)) z_ <- mkReg(0);

    Reg#(Bit#(CBDATASIZE)) limitX <- mkCBRegRW(CRAddr{a: 8'd3, o:0}, 'hffff);
    Reg#(Bit#(CBDATASIZE)) limitY <- mkCBRegRW(CRAddr{a: 8'd4, o:0},  'hffff);
    Reg#(Bit#(CBDATASIZE)) limitZ <- mkCBRegRW(CRAddr{a: 8'd5, o:0},  'hffff);

    Stmt cordicFSM = seq
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

            action
            x_.f <= x_.f & limitX;
            y_.f <= y_.f & limitY;
            z_.f <= z_.f & limitZ;
            endaction
        endseq
    endseq;

    FSM atanCalc <- mkFSM(cordicFSM);

    method Action setPolar(FixedPoint#(7, 16) x, FixedPoint#(7, 16) y, FixedPoint#(7, 16) z);
        atanCalc.waitTillDone();
        x_ <= x;
        y_ <= y;
        z_ <= z;
        atanCalc.start;
    endmethod

    method ActionValue #(FixedPoint#(7, 16)) getX();
        atanCalc.waitTillDone();
        return (x_ * 0.607253);
        //return x_;
    endmethod

    method ActionValue #(FixedPoint#(7, 16)) getY();
        atanCalc.waitTillDone();
        return (y_ * 0.607253);
        //return y_;
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

if (z > 1.570796) begin
            bigAngle<= True;
            z_ <= z - 2*(z - 1.570796);
        end else if (z < (-1.570796)) begin
            bigAngle<= True;
            z_ <= z + 2*(z + 1.570796);
        end else


*/