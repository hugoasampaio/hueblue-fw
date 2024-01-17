package CoarseFreq;

import Complex::*;
import Vector::*;
import FIFO::*;
import StmtFSM::*;
import FixedPoint::*;
import Cordic::*;

typedef Complex#(FixedPoint#(7, 16)) Sample_Type;
Integer sps = 4;
Integer tSamples = 1;
Integer tSymbol = tSamples * sps;

interface CoarseFreq_IFC;
    method Action addSample (Sample_Type sample);
    method ActionValue #(FixedPoint#(7, 16)) getError;
    //method ActionValue #(Vector#(64, Reg#(Sample_Type))) getFixedSamples;
endinterface: CoarseFreq_IFC

function FixedPoint#(7, 16) atan(FixedPoint#(7, 16) x, FixedPoint#(7, 16) y);

    FixedPoint#(7, 16) xAbs = x;
    FixedPoint#(7, 16) yAbs = y;
    FixedPoint#(7, 16) ret = 0.0;

    Bool xPos = True;
    Bool yPos = True;

    if (xAbs < 0.0) begin
        xAbs = xAbs * -1;
        xPos = False;
    end

    if (yAbs < 0.0) begin
        yAbs = yAbs * -1;
        yPos = False;
    end

    //1th and 8th octants
    if (x > 0.0 && (xAbs > yAbs)) begin
        ret = ((x * y) / ((x * x) + (y * y * 0.28125)));
    end

    //2nd and 3rd octants
    if (y > 0.0 && (yAbs >= xAbs)) begin
        ret = 1.570796 - ((x * y) / ((y * y) + (x * x * 0.28125)));
    end
    //4th and 5th octants
    if (x < 0.0 && (xAbs > yAbs)) begin
        if (yPos == True) begin
            ret = 3.14159 + ((x * y) / ((x * x) + (y * y * 0.28125)));
        end 
        else begin
            ret = -3.14159 + ((x * y) / ((x * x) + (y * y * 0.28125)));
        end 
    end
    if (y < 0.0 && (yAbs >= xAbs)) begin
        ret = -1.570796 - ((x * y) / ((y * y) + (x * x * 0.28125)));
    end
    return ret;

endfunction: atan

(* synthesize *)
module mkCoarseFreq (CoarseFreq_IFC);
    Vector#(64, Reg#(Sample_Type)) samples <-replicateM(mkReg(0));
    FIFO#(Sample_Type) newSample <- mkFIFO;
    Reg#(Sample_Type) lastSample <-mkReg(0);
    Reg#(Sample_Type) currSample <-mkReg(0);
    Reg#(Sample_Type) accumError <- mkReg(0);
    Reg#(FixedPoint#(7, 16)) fsError <- mkReg(0);
    Reg#(UInt#(7)) n <- mkReg(0);
    Cordic_IFC fixFxError <- mkRotate;

    Stmt calcError = seq
        for (n <= 0; n < 64; n <= n+1) seq
            currSample <= newSample.first;
            newSample.deq;
            lastSample.img <=  lastSample.img * -1; //conjugado
            accumError <= accumError + (currSample * lastSample);
            //normalizar accumError
            lastSample <= currSample;
            samples[n] <= currSample;
        endseq
        //based on understanding dsp equation
        $write("real: ");
        fxptWrite(10,accumError.rel);
        $write(" img: ");
        fxptWrite(10,accumError.img);
        $display("  ");
        fsError <=  (1/(2*3.14159)) * atan(accumError.rel, accumError.img);
        for (n <= 0; n < 64; n <= n+1) seq
            fixFxError.setPolar(samples[n].rel, samples[n].img, fsError);
            action
                let x <- fixFxError.getX();
                samples[n].rel <= x;
            endaction
            action
                let y <- fixFxError.getY();
                samples[n].img <= y;
            endaction
        endseq

    endseq;

    FSM coarseErrorCalc <- mkFSM(calcError);

    rule init;
        coarseErrorCalc.start;
    endrule

    method Action addSample (Sample_Type sample);
        newSample.enq(sample);
    endmethod

    method ActionValue #(FixedPoint#(7, 16)) getError;
        return fsError;
    endmethod

endmodule: mkCoarseFreq

endpackage: CoarseFreq
