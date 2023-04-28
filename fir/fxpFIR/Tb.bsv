package Tb;

import FIRfilter::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    FIRfilter_type fir <-mkFIRfilter;
    Reg#(Bool) first <- mkReg(True); 
    Reg#(Int#(8)) loop <- mkReg(0);
    Reg#(Sample_Type) result <-mkReg(0);
    
    
    Stmt filter = seq
        while (loop < 43) seq
            loop <= loop+1;
            if (first == False) 
                fir.add_sample(0);
    
            if (first == True) 
                fir.add_sample(1);
                first <= False;
             
            action
            let r <-  fir.get_value;   
            result <= r;
            endaction
            //$display("%d.%d", fxptGetInt(result), fxptGetFrac(result));
            //fxptGetInt(result.img), fxptGetFrac(result.img));
            $display(result);
        endseq
    endseq;
    
    mkAutoFSM(filter);
    
endmodule: mkTb
endpackage: Tb
