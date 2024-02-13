package Tb;

import CostasLoop::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;

(* synthesize *)
module mkTb (Empty);
     IWithCBus#(LimitedCostasLoop, CostasLoop_IFC) cc <- exposeCBusIFC(mkCostasLoop);
 
    Stmt test = seq
        cc.device_ifc.addSample(cmplx(-0.00006201 , 0.00000759));
        $write("timing error1: ");
        action
        let err <- cc.device_ifc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.device_ifc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.device_ifc.addSample(cmplx(-0.00049760 , 0.00033028));
        $write("timing error2: ");
        action
        let err <- cc.device_ifc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.device_ifc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.device_ifc.addSample(cmplx(-0.00268036 , 0.00193871));
        $write("timing error3: ");
        action
        let err <- cc.device_ifc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.device_ifc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

        cc.device_ifc.addSample(cmplx(-0.02249891 , 0.06907698));
        $write("timing error4: ");
        action
        let err <- cc.device_ifc.getError;
        fxptWrite(5,err);
        $write(" fix: ");
        let fix <-cc.device_ifc.getFixedSample;
        fxptWrite(5, fix.rel);
        $write(", ");
        fxptWrite(5, fix.img);
        endaction
        $display("  ");

    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
