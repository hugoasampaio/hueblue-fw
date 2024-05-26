package Tb_tang;

import MMTED::*;
//import MMTED_optimal::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

interface Tang;

    (* always_ready, prefix="", result="IN" *)
    method Bit#(12) inM;
    (* always_ready, prefix="", result="OUT" *)
    method Bit#(12) outM;
endinterface

(* synthesize *)
module mkTb (Tang);
    IWithCBus#(LimitedMMTED, MMTED_IFC) mmTed <- exposeCBusIFC(mkMMTED);
    //MMTED_IFC mmTed <- mkMMTEDO();
    Reg#(Bit#(12)) inV <-mkReg(0);
    Reg#(FixedPoint#(12, 12)) outV <-mkReg(0); 
    Reg#(FixedPoint#(12, 12)) fV <-mkReg(1);
    Reg#(UInt#(10)) n <- mkReg(0);
    Stmt test = seq
        fV.f <= inV;
        
		mmTed.cbus_ifc.write(5, fromInteger(cleanMask) << inV);
		mmTed.cbus_ifc.write(6, fromInteger(cleanMask) << inV);
		mmTed.cbus_ifc.write(7, fromInteger(cleanMask) << inV);
		mmTed.cbus_ifc.write(8, fromInteger(cleanMask) << inV);
		mmTed.cbus_ifc.write(9, fromInteger(cleanMask) << inV);
        
        for (n<=0; n < 10; n <= n+1) seq
            mmTed.device_ifc.addSample(cmplx(fV , fV));
            //mmTed.addSample(cmplx(fV , fV));
            action
            let fix <- mmTed.device_ifc.getError;
            //let fix <- mmTed.getError;
            outV <= fix;
            endaction
        endseq
    endseq;
    mkAutoFSM(test);

    method inM = inV;
    method outM = outV.i;

endmodule: mkTb

endpackage: Tb_tang