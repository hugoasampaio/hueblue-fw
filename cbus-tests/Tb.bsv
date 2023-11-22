package Tb;

import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import Operations::*;
import CBus::*;

(* synthesize *)
module mkTb (Empty);
    let plus_ifc();
    mkPlusSynth the_operation(plus_ifc);

    //Operations plus <- mkPlus;
    Stmt sum = seq
         $display("basic test, 1 bit fp");
        plus_ifc.device_ifc.putOperands(1, 1.5);
        plus_ifc.cbus_ifc.write(5, 1);
        action
        let r <-  plus_ifc.device_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        $display(" mask: ", plus_ifc.cbus_ifc.read(5));
        endaction
        plus_ifc.device_ifc.putOperands(1, 1.5);
        plus_ifc.cbus_ifc.write(5, 0);
        action
        let r <-  plus_ifc.device_ifc.getResult();
        $write("1 + 1.5 = ");
        fxptWrite(2,r);
        $display(" mask: ", plus_ifc.cbus_ifc.read(5));
        endaction
    endseq;

    mkAutoFSM(sum);

endmodule
endpackage