package Tb;

import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import Operations::*;
import CBus::*;

(* synthesize *)
module mkTb (Empty);
/*
    let plusFullIfc();
    mkPlusSynth instance (plusFullIfc);
    let otherPlus();
    mkPlusSynth other_operation(otherPlus);
*/
    IWithCBus#(LimitedCBus, Operations#(3, CBDATASIZE)) plusFullIfc <- exposeCBusIFC(mkPlus(3'd5));
    //let plus_ifc <- collectCBusIFC(Module(plusFullIfc));
    
    Stmt sumMask = seq
        $display("basic test, 1 bit fp");
        plusFullIfc.device_ifc.putOperands(1, 1.5);
        plusFullIfc.cbus_ifc.write(5, 1);
        action
        let r <-  plusFullIfc.device_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        $display(" mask: ", plusFullIfc.cbus_ifc.read(5));
        endaction
        plusFullIfc.device_ifc.putOperands(1, 1.5);
        plusFullIfc.cbus_ifc.write(5, 0);
        action
        let r <-  plusFullIfc.device_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        $display(" mask: ", plusFullIfc.cbus_ifc.read(5));
        endaction
    endseq;

/*
    Stmt sum = seq
        $display("basic test, 1 bit fp");
        plus_ifc.putOperands(1, 1.5);
        action
        let r <- plus_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        endaction
        plus_ifc.putOperands(1, 1.5);
        action
        let r <- plus_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        endaction
    endseq;
*/
    mkAutoFSM(sumMask);

endmodule
endpackage