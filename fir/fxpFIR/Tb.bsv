package Tb;

import FIRfilter::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import Vector::*;
import FIRcoeff::*;

(* synthesize *)
module mkTb (Empty);
    FIRfilter_type fir <-mkFIRfilter;
    Reg#(Bool) first <- mkReg(True); 
    Reg#(Int#(8)) loop <- mkReg(0);
    Vector#(43, Reg#(FIRPreciseTap_Type)) errors <-replicateM(mkReg(0));
    Reg#(FIRPreciseTap_Type) err_energy <- mkReg(0);
    Reg#(UInt#(7)) n <- mkReg(0);
    
    Stmt filter = seq
        for (n<= 0; n < 10; n<=n+1) seq
            fir.set_fwl(n);
            first <= True;
            while (loop < 43) seq
                if (first == False) 
                    fir.add_sample(0);
        
                if (first == True) 
                    fir.add_sample(1);
                    first <= False;
                
                action
                let r <-  fir.get_value;   
                errors[loop] <= coeff_precise[loop] - fxptSignExtend(r);
                endaction
                loop <= loop+1;
            endseq
            loop <= 0;
            err_energy <= 0;
            while (loop < 43 ) seq
                err_energy <= err_energy + (errors[loop] * errors[loop]);
                $write("iter %d: ", n);
                fxptWrite(10,errors[loop]);
                $display("  ");
                loop <= loop+1;
            endseq
            $write("energy error: ");
            fxptWrite(10,err_energy);
            $display("  ");
            loop <= 0;
        endseq
        $write("energy filter: ");
        fxptWrite(10,energy_filter());
        $display("  ");
    endseq;
    mkAutoFSM(filter);
    
endmodule: mkTb
endpackage: Tb
