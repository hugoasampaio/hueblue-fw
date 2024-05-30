package Tb_tang;

import CoarseFreq::*;
//import CoarseFreq_optimal::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;

interface Tang;

    (* always_ready, prefix="", result="IN" *)
    method Action inM (Bit#(12) value);
    (* always_ready, prefix="", result="OUT" *)
    method Bit#(12) outM;
endinterface

(* synthesize *)
module mkTb (Tang);
    IWithCBus#(LimitedCoarseFreq, CoarseFreq_IFC) coarseFreq <- exposeCBusIFC(mkCoarseFreq);
    //CoarseFreq_IFC coarseFreq <- mkCoarseFreqO();
    Reg#(Bit#(12)) inV <-mkReg(0);
    Reg#(FixedPoint#(INTEGERSIZE, 12)) outV <-mkReg(0); 
    Reg#(FixedPoint#(INTEGERSIZE, 12)) fV <-mkReg(1);
    Reg#(UInt#(10)) n <- mkReg(0);
    Stmt test = seq
        fV.f <= inV;
        
		coarseFreq.cbus_ifc.write(11, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(12, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(13, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(14, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(15, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(16, fromInteger(cleanMask) << inV);
		coarseFreq.cbus_ifc.write(17, fromInteger(cleanMask) << inV);
        
        for (n<=0; n < 10; n <= n+1) seq
            coarseFreq.device_ifc.addSample(cmplx(fV , fV));
            //coarseFreq.addSample(cmplx(fV , fV));
            action
            let fix <- coarseFreq.device_ifc.getError;
            //let fix <- coarseFreq.getError;
            outV <= fix;
            endaction
        endseq
    endseq;
    mkAutoFSM(test);

    method Action inM (Bit#(12) value);
        inV <= value;
    endmethod
    method outM = outV.f;

endmodule: mkTb

endpackage: Tb_tang