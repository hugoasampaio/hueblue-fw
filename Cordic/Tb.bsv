package Tb;

import Cordic::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    Cordic_IFC cordic <- mkAtan;

    Angle_Type x = 1;
    Angle_Type y = 0;
    Angle_Type z = 0.523598; //30°
    
    Stmt test = seq 
        cordic.setPolar(x, y, z);
        $write("vec: ");
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
