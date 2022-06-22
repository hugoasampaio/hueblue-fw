package QPSKtx;

import Complex::*;
import Vector::*;
import FIFO::*;
import FIRfilter::*;
import StmtFSM::*;
import QPSKmapper::*;

typedef Complex#(Int#(13)) Sample_Type;

interface QPSKtx_type;
    //method #(Bit#(1)) is_data_ready;
    method ActionValue #(Sample_Type) get_value;
    method Action add_sample (Bit#(2) bits);
endinterface: QPSKtx_type

(* synthesize *)
module mkQPSKtx (QPSKtx_type);
    QPSKmapper_type mapper <-mkQPSKmapper;
    FIRfilter_type srrc <- mkFIRfilter;
    Vector#(4, Reg#(Sample_Type)) input_samples <-replicateM(mkReg(0));
    FIFO#(Sample_Type) output_sample <-mkFIFO;
    FIFO#(Bit#(2)) input_bits <-mkFIFO;
    Reg#(Int#(4)) n <- mkReg(0);
    //Reg#(Sample_Type) out <- mkReg(0);

    Stmt compute_tx_samples = seq
        input_samples[0] <= mapper.map(input_bits.first);
        input_bits.deq;
        
        for (n <=0; n < 4; n <= n+1) seq
            srrc.add_sample(input_samples[n]);
            action
            let out <- srrc.get_value;
            output_sample.enq(out);
            endaction
        endseq
    endseq;
    
    FSM tx_sampl <- mkFSM(compute_tx_samples);
    
    rule init;
        tx_sampl.start;
    endrule
    
    method Action add_sample (Bit#(2) bits);
        input_bits.enq(bits);
    endmethod
    
    method ActionValue #(Sample_Type) get_value;
        let ret = output_sample.first;
        output_sample.deq;
        return ret;
   endmethod
   
endmodule: mkQPSKtx

endpackage: QPSKtx
