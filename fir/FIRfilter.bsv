package FIRfilter;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIRcoeff::*;
import StmtFSM::*;

typedef Int#(13) Sample_Type;

interface FIRfilter_type;
   method Action add_sample (Sample_Type sample);
   method ActionValue #(int) get_value;
endinterface: FIRfilter_type

(* synthesize *)
module mkFIRfilter (FIRfilter_type);
   Vector#(43, Reg#(Sample_Type)) samples <-replicateM(mkReg(0));
   FIFO#(int) acc <-mkFIFO;
   FIFO#(Sample_Type) newSample <- mkFIFO;
   Reg#(int) sum <- mkReg(0);
   Reg#(Int#(7)) n <- mkReg(0);
   
   Stmt convolve = seq
        for (n <= 42; n > 0; n<=n-1) seq
            samples[n] <= samples[n-1];
        endseq
        
        samples[0] <= newSample.first;
        newSample.deq;
        for (n<= 0; n < 42; n<=n+1) seq
            sum <= sum + signExtend(samples[n]) * signExtend(coeff[n]);
        endseq
        acc.enq(sum);
        sum <= 0;
   endseq;
   
   FSM conv <- mkFSM(convolve);
   
   rule init;
        conv.start;
   endrule
   
   method Action add_sample (Sample_Type sample);
        newSample.enq(sample);
   endmethod
   
   method ActionValue #(int) get_value;
        let ret = acc.first;
        acc.deq;
        return ret;
   endmethod
   
endmodule: mkFIRfilter

endpackage: FIRfilter
