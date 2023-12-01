package Limit;
/*
import Complex::*;
import Vector::*;
import FIFO::*;
import FIRcoeff::*;
import StmtFSM::*;
import FixedPoint::*;

interface Limited_type#(type var);
    
    method Action set_fwl(UInt#(7) fwl);
endinterface

(* synthesize *)
module mkLimit (Limited_type);
    Reg#(UInt#(7)) zeros <-mkReg(0);

    function FIRtap_Type apply_limit(FIRtap_Type tap);
        tap.f = tap.f & ('hFFFF << zeros);
        return tap;
    endfunction

    method Action set_fwl(UInt#(7) fwl);
        zeros <= fwl;
    endmethod

endmodule
*/
endpackage: Limit