package MMTED;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;

typedef FixedPoint#(7, 16)      SampleType;
typedef Complex#(SampleType)    ComplexSampleType;
Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface MMTED_IFC;
    method Action addSample (ComplexSampleType sample);
    method ActionValue #(SampleType) getError;
endinterface: MMTED_IFC

(* synthesize *)
module mkMMTED (MMTED_IFC);
    /*
    mu = 0 # initial estimate of phase of sample
    out = np.zeros(len(samples) + 10, dtype=np.complex)
    out_rail = np.zeros(len(samples) + 10, dtype=np.complex) # stores values, each iteration we need the previous 2 values plus current value
    i_in = 0 # input samples index
    i_out = 2 # output index (let first two outputs be 0)
    */
    Reg#(SampleType) mu <-mkReg(0);
    Vector#(64, Reg#(ComplexSampleType)) samples <- replicateM(mkReg(0));
    Vector#(74, Reg#(ComplexSampleType)) out  <- replicateM(mkReg(0));
    Vector#(74, Reg#(ComplexSampleType)) outRail  <- replicateM(mkReg(0));
    Reg#(UInt#(7)) iIn <- mkReg(0);
    Reg#(UInt#(7)) iOut <- mkReg(2);
    Reg#(UInt#(7)) n <- mkReg(0);
    Reg#(ComplexSampleType) x <- mkReg(0);
    Reg#(ComplexSampleType) y <- mkReg(0);
    FIFO#(ComplexSampleType) newSample <- mkFIFO;
    Reg#(SampleType) mmVal <- mkReg(0);
/*
while i_out < len(samples) and i_in+16 < len(samples):
    out[i_out] = samples[i_in + int(mu)] # grab what we think is the "best" sample
    out_rail[i_out] = int(np.real(out[i_out]) > 0) + 1j*int(np.imag(out[i_out]) > 0)
    x = (out_rail[i_out] - out_rail[i_out-2]) * np.conj(out[i_out-1])
    y = (out[i_out] - out[i_out-2]) * np.conj(out_rail[i_out-1])
    mm_val = np.real(y - x)
    mu += sps + 0.3*mm_val
    i_in += int(np.floor(mu)) # round down to nearest int since we are using it as an index
    mu = mu - np.floor(mu) # remove the integer part of mu
    i_out += 1 # increment output index
out = out[2:i_out] # remove the first two, and anything after i_out (that was never filled out)
samples = out # only include this line if you want to connect this code snippet with the Costas Loop later on  
*/
    Stmt calcError = seq
        for (n <= 0; n < 64; n <= n+1) seq
            samples[n] <= newSample.first;
            newSample.deq;
        endseq
        while (iOut < 64 && iIn+16 < 64) seq
            out[iOut] <= samples[iIn + unpack(mu.i)];
            outRail[iOut] <= cmplx( (out[iOut].rel > 0.0 ? 1.0 : 0.0) ,  (out[iOut].img > 0.0 ? 1.0 : 0.0));
            x <= (outRail[iOut] - outRail[iOut -2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));
            y <= (out[iOut] - out[iOut -2]) * (outRail[iOut-1] * cmplx(1.0, -1.0));
            mmVal <= y.rel-x.rel;
            mu <= mu + fromInteger(sps) + 0.3 * mmVal;
            iIn <= iIn + unpack(mu.i);
            mu.i <= 0;
            iOut <= iOut + 1;
        endseq

    endseq;

    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (ComplexSampleType sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(SampleType) getError;
        return mu;
    endmethod

endmodule: mkMMTED

endpackage: MMTED
