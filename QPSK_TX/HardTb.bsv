package HardTb;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import QPSKtx::*;
import QPSKmapper::*;

//typedef Complex#(Int#(13)) Sample_Type;

interface HardTb_type;
    method Bit#(1) sample_ready;
    method Bit#(1) data;
endinterface: HardTb_type

(* synthesize *)

module mkhardTb (HardTb_type);
    QPSKtx_type tx <- mkQPSKtx;
    
    Reg#(Bit#(1)) toggle <- mkReg(0);
    Reg#(Bit#(1)) datum <- mkReg(0);
    Reg#(Bit#(7)) i <- mkReg(0);
    Reg#(Sample_Type) samp <- mkReg(0);
    
    
    Stmt loop = seq
        tx.add_sample(2'b00);
        for (i <= 0; i < 4; i<=i+1) seq
            action
            let tmp <- tx.get_value;
            samp <= tmp;
            endaction
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.rel));
                datum <= bits[i];
                endaction
            endseq
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.img));
                datum <= bits[i];
                endaction
            endseq
        endseq
        
        toggle <= ~ toggle;
        
        tx.add_sample(2'b01);
        for (i <= 0; i < 4; i<=i+1) seq
            action
            let tmp <- tx.get_value;
            samp <= tmp;
            endaction
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.rel));
                datum <= bits[i];
                endaction
            endseq
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.img));
                datum <= bits[i];
                endaction
            endseq
        endseq
        
        toggle <= ~ toggle;
        
        tx.add_sample(2'b11);
        for (i <= 0; i < 4; i<=i+1) seq
            action
            let tmp <- tx.get_value;
            samp <= tmp;
            endaction
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.rel));
                datum <= bits[i];
                endaction
            endseq
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.img));
                datum <= bits[i];
                endaction
            endseq
        endseq
        
        toggle <= ~ toggle;
        
        tx.add_sample(2'b10);
        for (i <= 0; i < 4; i<=i+1) seq
            action
            let tmp <- tx.get_value;
            samp <= tmp;
            endaction
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.rel));
                datum <= bits[i];
                endaction
            endseq
            for (i <=0; i < 13; i <= i+1) seq
                action
                Bit#(13) bits = unpack(pack(samp.img));
                datum <= bits[i];
                endaction
            endseq
        endseq
        
        toggle <= ~ toggle;
    endseq;
    
    FSM tx_test <- mkFSM(loop);
    
    rule init;
        tx_test.start;
    endrule
    
    method Bit#(1) sample_ready;
        return toggle;
    endmethod
    
    method Bit#(1) data;
        return datum;
    endmethod

endmodule: mkhardTb

endpackage: HardTb
