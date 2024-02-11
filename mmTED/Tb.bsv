package Tb;

import MMTED::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;

(* synthesize *)
module mkTb (Empty);
    MMTED_IFC mmTed <- mkMMTED;
 
    Stmt test = seq
        mmTed.addSample(cmplx(-0.00000045 , 0.00000000));
        mmTed.addSample(cmplx(-0.00000012 , 0.00000062));
        mmTed.addSample(cmplx(0.00000164 , 0.00000065));
        mmTed.addSample(cmplx(0.00000056 , -0.00000089));
        mmTed.addSample(cmplx(-0.00000360 , -0.00000338));
        mmTed.addSample(cmplx(-0.00000574 , 0.00000417));
        mmTed.addSample(cmplx(0.00000357 , 0.00000759));
        mmTed.addSample(cmplx(0.00001517 , -0.00000389));
        mmTed.addSample(cmplx(-0.00000143 , -0.00002266));
        mmTed.addSample(cmplx(-0.00003547 , -0.00000448));
        mmTed.addSample(cmplx(-0.00001856 , 0.00005711));
        mmTed.addSample(cmplx(0.00055753 , 0.00030650));
        mmTed.addSample(cmplx(-0.00002490 , 0.00003010));
        mmTed.addSample(cmplx(-0.00043580 , -0.00052680));
        mmTed.addSample(cmplx(0.00208358 , -0.00114546));
        mmTed.addSample(cmplx(0.00108983 , 0.00335415));
        mmTed.addSample(cmplx(-0.00044974 , 0.00005682));
        mmTed.addSample(cmplx(-0.00020246 , 0.00321809));
        mmTed.addSample(cmplx(-0.00305484 , -0.00078435));
        mmTed.addSample(cmplx(0.00027126 , -0.00057645));
        mmTed.addSample(cmplx(-0.00052776 , -0.00038344));
        mmTed.addSample(cmplx(-0.00586284 , 0.00550557));
        mmTed.addSample(cmplx(-0.01264457 , -0.01992465));
        mmTed.addSample(cmplx(0.02738548 , -0.01084268));
        mmTed.addSample(cmplx(0.00075723 , 0.00396956));
        mmTed.addSample(cmplx(0.05043993 , 0.00000000));
        mmTed.addSample(cmplx(-0.01927752 , 0.10105631));
        mmTed.addSample(cmplx(-0.09614120 , -0.03806499));
        mmTed.addSample(cmplx(0.00760495 , -0.01198348));
        mmTed.addSample(cmplx(-0.12658620 , -0.11887235));
        mmTed.addSample(cmplx(0.34981920 , -0.25415853));
        mmTed.addSample(cmplx(0.30401938 , 0.64607406));
        mmTed.addSample(cmplx(-0.94591325 , 0.24286924));
        mmTed.addSample(cmplx(-0.07420374 , -1.17943472));
        mmTed.addSample(cmplx(1.28122208 , 0.16185599));
        mmTed.addSample(cmplx(-0.38835581 , 1.19523628));
        mmTed.addSample(cmplx(-0.90601976 , -0.49808858));
        mmTed.addSample(cmplx(0.38912915 , -0.47037634));
        mmTed.addSample(cmplx(0.02920951 , 0.03530823));
        mmTed.addSample(cmplx(0.46530930 , -0.25580595));
        mmTed.addSample(cmplx(0.29920162 , 0.92084789));
        mmTed.addSample(cmplx(-1.16653676 , 0.14736786));
        mmTed.addSample(cmplx(0.07353358 , -1.16878285));
        mmTed.addSample(cmplx(1.03448464 , 0.26561051));
        mmTed.addSample(cmplx(-0.42611774 , 0.90554629));
        mmTed.addSample(cmplx(-0.84259262 , -0.61217937));
        mmTed.addSample(cmplx(0.83666878 , -0.78568428));
        mmTed.addSample(cmplx(0.63638305 , 1.00277924));
        mmTed.addSample(cmplx(-0.95768945 , 0.37917608));
        mmTed.addSample(cmplx(-0.11723261 , -0.61455488));
        mmTed.addSample(cmplx(0.05045161 , 0.00000000));
        mmTed.addSample(cmplx(0.09998856 , -0.52415838));
        mmTed.addSample(cmplx(0.89977336 , 0.35624548));
        mmTed.addSample(cmplx(-0.63066579 , 0.99377028));
        mmTed.addSample(cmplx(-0.86865099 , -0.81571757));
        mmTed.addSample(cmplx(0.89393224 , -0.64947979));
        mmTed.addSample(cmplx(0.42910157 , 0.91188725));
        mmTed.addSample(cmplx(-0.91619248 , 0.23523825));
        mmTed.addSample(cmplx(-0.05796954 , -0.92139938));
        mmTed.addSample(cmplx(0.92792355 , 0.11722400));
        mmTed.addSample(cmplx(-0.30643686 , 0.94311566));
        mmTed.addSample(cmplx(-0.96037267 , -0.52796935));
        mmTed.addSample(cmplx(0.76925262 , -0.92986669));
        mmTed.addSample(cmplx(0.78051090 , 0.94347561));
        mmTed.addSample(cmplx(-0.90590647 , 0.49802630));
        mmTed.addSample(cmplx(-0.18159743 , -0.55889942));
        mmTed.addSample(cmplx(-0.02975169 , 0.00375851));
        $write("timing error: ");
        action
        let err <- mmTed.getError;
        fxptWrite(5,err);
        endaction
        $display("  ");
    endseq;
    mkAutoFSM(test);
    
endmodule: mkTb
endpackage: Tb
