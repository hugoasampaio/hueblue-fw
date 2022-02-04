package Tb;

import FIRfilter::*;
import StmtFSM::*;

(* synthesize *)
module mkTb (Empty);
    FIRfilter_type fir <-mkFIRfilter;
    Reg #(Bool) first <- mkReg(True); 
    Reg #(Int#(8)) loop <- mkReg(0);
    Stmt filter = seq
        while (loop < 43) seq
            loop <= loop+1;
            if (first == False)
            fir.add_sample(0);
    
            if (first == True)
                fir.add_sample(4095);
                first <= False;
        
            $display("%d", fir.get_value);
        endseq
    endseq;
    
    mkAutoFSM(filter);
    
endmodule: mkTb
endpackage: Tb
