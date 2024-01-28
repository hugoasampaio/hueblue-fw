package Tb;

import Cordic::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    Cordic_IFC cordic <- mkRotate;

    // 1 /_10
    FixedPoint#(7, 16) x2 = 0.98481;
    FixedPoint#(7, 16) y2 = 0.17365;
    FixedPoint#(7, 16) z2 = -0.17453; //-10°

    // 1 /_ 15
    FixedPoint#(7, 16) x3 = 0.96593;
    FixedPoint#(7, 16) y3 = 0.25882;
    FixedPoint#(7, 16) z3 = -0.26180; //-15°

    // 1 /_ 20
    FixedPoint#(7, 16) x4 = 0.93969;
    FixedPoint#(7, 16) y4 = 0.34202;
    FixedPoint#(7, 16) z4 = -0.34907; //-20°

    // 1 /_30
    FixedPoint#(7, 16) x1 = 0.86603;
    FixedPoint#(7, 16) y1 = 0.5;
    FixedPoint#(7, 16) z1 = -0.523598; //-30°

    
    Stmt test = seq 

        cordic.setPolar(x2, y2, z2);
        action
        let x_rot <- cordic.getX;
        let y_rot <- cordic.getY;
        $write("10: ");
        fxptWrite(10,x_rot);
        $write(", ");
        fxptWrite(10,y_rot);
        endaction
        $display("  ");

        cordic.setPolar(x3, y3, z3);
        $write("15: ");
        action
        let x_rot <- cordic.getX;
        let y_rot <- cordic.getY;
        fxptWrite(10,x_rot);
        $write(", ");
        fxptWrite(10,y_rot);
        endaction
        $display("  ");

        cordic.setPolar(x4, y4, z4);
        $write("20: ");
        action
        let x_rot <- cordic.getX;
        let y_rot <- cordic.getY;
        fxptWrite(10,x_rot);
        $write(", ");
        fxptWrite(10,y_rot);
        endaction
        $display("  ");

        cordic.setPolar(x1, y1, z1);
        $write("30: ");
        action
        let x_rot <- cordic.getX;
        let y_rot <- cordic.getY;
        fxptWrite(10,x_rot);
        $write(", ");
        fxptWrite(10,y_rot);
        endaction
        $display("  ");
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
