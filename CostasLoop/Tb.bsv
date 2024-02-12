package Tb;

import CostasLoop::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    CostasLoop_IFC cc <- mkCostasLoop;
 
    Stmt test = seq
        cc.addSample(cmplx(0.00000045 , 0.00000000));
        $write("timing error1: ");
        action
        let err <- cc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.addSample(cmplx(-0.00000063 , -0.00000000));
        $write("timing error2: ");
        action
        let err <- cc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.addSample(cmplx(0.00000176 , 0.00000000));
        $write("timing error3: ");
        action
        let err <- cc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.addSample(cmplx(-0.00000105 , -0.00000000));
        $write("timing error4: ");
        action
        let err <- cc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
