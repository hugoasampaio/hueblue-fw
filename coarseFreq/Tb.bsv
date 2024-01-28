package Tb;

import CoarseFreq::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    CoarseFreq_IFC coarseFreq <- mkCoarseFreq;
    Reg#(FixedPoint#(5, 16)) res <-mkReg(0);
 
    Stmt test = seq
        $display("  ");
        fxptWrite(5, atan(2.819, 1.026));//20 --- 0.349
        $display("  ");
        fxptWrite(5, atan(-1.026, 2.819));//110 --- 1.9198
        $display("  ");
        fxptWrite(5, atan(-2.819, -1.026));//200 --- 3.49
        $display("  ");
        fxptWrite(5, atan(1.026, -2.819));//290 --- 5.061
        $display("  ");
        fxptWrite(5, atan(-5.83674, 30.597488));//290 --- 5.061
        $display("  ");

        coarseFreq.addSample(cmplx(-0.00000045 , 0.00000000));
        coarseFreq.addSample(cmplx(-0.00000012 , 0.00000062));
        coarseFreq.addSample(cmplx(0.00000164 , 0.00000065));
        coarseFreq.addSample(cmplx(0.00000056 , -0.00000089));
        coarseFreq.addSample(cmplx(-0.00000360 , -0.00000338));
        coarseFreq.addSample(cmplx(-0.00000574 , 0.00000417));
        coarseFreq.addSample(cmplx(0.00000357 , 0.00000759));
        coarseFreq.addSample(cmplx(0.00001517 , -0.00000389));
        coarseFreq.addSample(cmplx(-0.00000143 , -0.00002266));
        coarseFreq.addSample(cmplx(-0.00003547 , -0.00000448));
        coarseFreq.addSample(cmplx(-0.00001856 , 0.00005711));
        coarseFreq.addSample(cmplx(0.00055753 , 0.00030650));
        coarseFreq.addSample(cmplx(-0.00002490 , 0.00003010));
        coarseFreq.addSample(cmplx(-0.00043580 , -0.00052680));
        coarseFreq.addSample(cmplx(0.00208358 , -0.00114546));
        coarseFreq.addSample(cmplx(0.00108983 , 0.00335415));
        coarseFreq.addSample(cmplx(-0.00044974 , 0.00005682));
        coarseFreq.addSample(cmplx(-0.00020246 , 0.00321809));
        coarseFreq.addSample(cmplx(-0.00305484 , -0.00078435));
        coarseFreq.addSample(cmplx(0.00027126 , -0.00057645));
        coarseFreq.addSample(cmplx(-0.00052776 , -0.00038344));
        coarseFreq.addSample(cmplx(-0.00586284 , 0.00550557));
        coarseFreq.addSample(cmplx(-0.01264457 , -0.01992465));
        coarseFreq.addSample(cmplx(0.02738548 , -0.01084268));
        coarseFreq.addSample(cmplx(0.00075723 , 0.00396956));
        coarseFreq.addSample(cmplx(0.05043993 , 0.00000000));
        coarseFreq.addSample(cmplx(-0.01927752 , 0.10105631));
        coarseFreq.addSample(cmplx(-0.09614120 , -0.03806499));
        coarseFreq.addSample(cmplx(0.00760495 , -0.01198348));
        coarseFreq.addSample(cmplx(-0.12658620 , -0.11887235));
        coarseFreq.addSample(cmplx(0.34981920 , -0.25415853));
        coarseFreq.addSample(cmplx(0.30401938 , 0.64607406));
        coarseFreq.addSample(cmplx(-0.94591325 , 0.24286924));
        coarseFreq.addSample(cmplx(-0.07420374 , -1.17943472));
        coarseFreq.addSample(cmplx(1.28122208 , 0.16185599));
        coarseFreq.addSample(cmplx(-0.38835581 , 1.19523628));
        coarseFreq.addSample(cmplx(-0.90601976 , -0.49808858));
        coarseFreq.addSample(cmplx(0.38912915 , -0.47037634));
        coarseFreq.addSample(cmplx(0.02920951 , 0.03530823));
        coarseFreq.addSample(cmplx(0.46530930 , -0.25580595));
        coarseFreq.addSample(cmplx(0.29920162 , 0.92084789));
        coarseFreq.addSample(cmplx(-1.16653676 , 0.14736786));
        coarseFreq.addSample(cmplx(0.07353358 , -1.16878285));
        coarseFreq.addSample(cmplx(1.03448464 , 0.26561051));
        coarseFreq.addSample(cmplx(-0.42611774 , 0.90554629));
        coarseFreq.addSample(cmplx(-0.84259262 , -0.61217937));
        coarseFreq.addSample(cmplx(0.83666878 , -0.78568428));
        coarseFreq.addSample(cmplx(0.63638305 , 1.00277924));
        coarseFreq.addSample(cmplx(-0.95768945 , 0.37917608));
        coarseFreq.addSample(cmplx(-0.11723261 , -0.61455488));
        coarseFreq.addSample(cmplx(0.05045161 , 0.00000000));
        coarseFreq.addSample(cmplx(0.09998856 , -0.52415838));
        coarseFreq.addSample(cmplx(0.89977336 , 0.35624548));
        coarseFreq.addSample(cmplx(-0.63066579 , 0.99377028));
        coarseFreq.addSample(cmplx(-0.86865099 , -0.81571757));
        coarseFreq.addSample(cmplx(0.89393224 , -0.64947979));
        coarseFreq.addSample(cmplx(0.42910157 , 0.91188725));
        coarseFreq.addSample(cmplx(-0.91619248 , 0.23523825));
        coarseFreq.addSample(cmplx(-0.05796954 , -0.92139938));
        coarseFreq.addSample(cmplx(0.92792355 , 0.11722400));
        coarseFreq.addSample(cmplx(-0.30643686 , 0.94311566));
        coarseFreq.addSample(cmplx(-0.96037267 , -0.52796935));
        coarseFreq.addSample(cmplx(0.76925262 , -0.92986669));
        coarseFreq.addSample(cmplx(0.78051090 , 0.94347561));
        coarseFreq.addSample(cmplx(-0.90590647 , 0.49802630));
        coarseFreq.addSample(cmplx(-0.18159743 , -0.55889942));
        coarseFreq.addSample(cmplx(-0.02975169 , 0.00375851));
        //$display("energy error expected (-6.074024636019345 +j31.841152218217513), 1.7592 rad");
        $write("coarse freq error: ");
        action
        let err <- coarseFreq.getError;
        fxptWrite(5,err);
        endaction
        $display("  ");
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
