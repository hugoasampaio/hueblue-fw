package Tb;

import Cordic_limited::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

Integer test_size = 5;
//can rotate 90 degree maximum
(* synthesize *)
module mkTb (Empty);
    IWithCBus#(LimitedCordic, Cordic_IFC) cordic <- exposeCBusIFC(mkRotate);
    IWithCBus#(LimitedCordic, Cordic_IFC) atan <- exposeCBusIFC(mkAtan);

    //10,15,20,60,120
    REAL_SAMPLE_TYPE x[test_size] = {0.98481, 0.96593,    0.96593,  0.5,     -0.5};
    REAL_SAMPLE_TYPE y[test_size] = {0.17365, 0.25882,    0.25882,  0.86603,  0.86603};
    REAL_SAMPLE_TYPE z[test_size] = {-0.17453, -0.26180, -0.26180, -1.04720, -2.094395};

    Reg#(UInt#(10)) n <- mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) realV <- mkReg(1.0);
    Reg#(REAL_SAMPLE_TYPE) imagV <- mkReg(0.0);

    /*
    cordic.cbus_ifc.write(41, fromInteger(cleanMask));
	cordic.cbus_ifc.write(42, fromInteger(cleanMask));
	cordic.cbus_ifc.write(43, fromInteger(cleanMask));
    */
    Stmt test = seq 
        for (n <= 0; n < fromInteger(test_size); n <= n+1) seq
            cordic.device_ifc.setPolar(x[n], y[n], z[n]);
            action
            let x_rot <- cordic.device_ifc.getX;
            let y_rot <- cordic.device_ifc.getY;
            let z_rot <- cordic.device_ifc.getZ;
            $write("n: ");
            fxptWrite(6,x_rot);
            $write(", ");
            fxptWrite(6,y_rot);
            endaction
            $display("  ");
        endseq
        $display("rotation test");
        for (n <= 0; n < 30; n <= n+1) seq
            //10 degree
            // cordic.device_ifc.setPolar(realV, imagV, 0.17453);
            //120 degree
            cordic.device_ifc.setPolar(realV, imagV, -2.094395);
            action
            let x_rot <- cordic.device_ifc.getX;
            let y_rot <- cordic.device_ifc.getY;
            realV <= x_rot;
            imagV <= y_rot;
            endaction
        endseq
        action
        fxptWrite(6,realV);
        $write(", ");
        fxptWrite(6,imagV);
        $display(" ");
        endaction

        $display("atan test");
        for (n <= 0; n < fromInteger(test_size); n <= n+1) seq
            atan.device_ifc.setPolar(x[n], y[n], 0.0);
            action
            let z_rot <- atan.device_ifc.getZ;
            $write("n: ");
            fxptWrite(6,z_rot+z[n]);
            endaction
            $display("  ");
        endseq

    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
