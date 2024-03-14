package Tb;

import Cordic::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;

Integer test_size = 5;
//can rotate 90 degree maximum
(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedCordic, Cordic_IFC) cordic <- exposeCBusIFC(mkRotate);

    //10,15,20,60,120
    FixedPoint#(7,16) x[test_size] = {0.98481, 0.96593,    0.96593,  0.5,     -0.5};
    FixedPoint#(7,16) y[test_size] = {0.17365, 0.25882,    0.25882,  0.86603,  0.86603};
    FixedPoint#(7,16) z[test_size] = {-0.17453, -0.26180, -0.26180, -1.04720, -2.094395};

    Reg#(UInt#(10)) n <- mkReg(0);
    Reg#(FixedPoint#(7, 16)) realV <- mkReg(1.0);
    Reg#(FixedPoint#(7, 16)) imagV <- mkReg(0.0);
    
    Stmt test = seq 
        for (n <= 0; n < fromInteger(test_size); n <= n+1) seq
            cordic.device_ifc.setPolar(x[n], y[n], z[n]);
            action
            let x_rot <- cordic.device_ifc.getX;
            let y_rot <- cordic.device_ifc.getY;
            $write("n: ");
            fxptWrite(6,x_rot);
            $write(", ");
            fxptWrite(6,y_rot);
            endaction
            $display("  ");
        endseq


        $display("rotation test");
        for (n <= 1; n < 73; n <= n+1) seq
            cordic.device_ifc.setPolar(realV, imagV, 0.17453);
            action
            let x_rot <- cordic.device_ifc.getX;
            let y_rot <- cordic.device_ifc.getY;
            realV <= x_rot;
            imagV <= y_rot;
            endaction
        endseq

        $write(10*n, ": ");
        fxptWrite(6,realV);
        $write(", ");
        fxptWrite(6,imagV);
        $display(" ");
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
