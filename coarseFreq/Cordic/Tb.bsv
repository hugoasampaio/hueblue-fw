package Tb;

import Cordic::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

//typedef FixedPoint#(7, 16)  Angle_Type;

(* synthesize *)
module mkTb (Empty);
    Cordic_IFC cordic <- mkAtan;

    Angle_Type x = 2;
    Angle_Type y = 2;
    
    Stmt test = seq 
        cordic.setPolar(x, y);
        $write("angle: ");
        action
        let atan <- cordic.getAtan;
        fxptWrite(10,atan);
        endaction
        $display("  ");
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
