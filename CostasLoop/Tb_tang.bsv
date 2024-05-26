package Tb_tang;

//import CostasLoop::*;
import CostasLoop_optimal::*;
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
    //IWithCBus#(LimitedCostasLoop, CostasLoop_IFC) cc <- exposeCBusIFC(mkCostasLoop);
    CostasLoopO_IFC cc <- mkCostasLoopO();
    Reg#(Bit#(INTEGERSIZE)) inV <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) outV <-mkReg(0); 
    Reg#(REAL_SAMPLE_TYPE) fV <-mkReg(1);
    Reg#(UInt#(10)) n <- mkReg(0);
    Stmt test = seq
        fV.f <= inV;
		//cc.cbus_ifc.write(8, fromInteger(cleanMask) << inV);
		//cc.cbus_ifc.write(9, fromInteger(cleanMask) << inV);
		//cc.cbus_ifc.write(10, fromInteger(cleanMask) << inV);
        for (n<=0; n < 106; n <= n+1) seq
            //cc.device_ifc.addSample(cmplx(fV , fV));
            cc.addSample(cmplx(fV , fV));
            action
            //let fix <- cc.device_ifc.getFixedSample;
            let fix <- cc.getFixedSample;
            outV <= fix.rel;
            endaction
        endseq
    endseq;
    mkAutoFSM(test);

    method inM = inV;
    method outM = outV.f;

endmodule: mkTb

endpackage: Tb_tang