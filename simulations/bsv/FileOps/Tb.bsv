package Tb;
import FileOps::*;
import FixedPoint::*;
import FIFOF::*;
import StmtFSM::*;

/* file read */
(* synthesize *)
module mkTb (Empty);
    Reg#(UInt#(7)) cnt <- mkReg(0);
    FIFOF#(FixedPoint#(7, 16)) infifo <- mkSizedFIFOF(3);
    LineReader lr <- mkLineReader;
    mkAutoFSM(seq
        while (cnt < 3) seq
            cnt <= cnt + 1;
            lr.start;
            infifo.enq(lr.result);
            $write(cnt, ": ");
            fxptWrite(8,infifo.first);
            $display(" ");
            infifo.deq;
        endseq
        $finish(0);
    endseq);
endmodule: mkTb
endpackage: Tb


/* file write
(* synthesize *)
module mkTb (Empty);
    Reg#(UInt#(4)) cnt <- mkReg(0);
    let fh <- mkReg(InvalidFile);
    let fmcd <- mkReg(InvalidFile);

    rule open (cnt == 0 ) ;
        // Open the file and check for proper opening
        String dumpFile = "dump_file1.dat" ;
        File lfh <- $fopen( dumpFile, "w" ) ;
        if ( lfh == InvalidFile )
        begin
            $display("cannot open %s", dumpFile);
            $finish(0);
        end
        cnt <= 1 ;
        fh <= lfh ; // Save the file in a Register
    endrule

    rule open2 (cnt == 1 ) ;
        // Open the file and check for proper opening
        // Using a multi-channel descriptor.
        String dumpFile = "dump_file2.dat" ;
        File lmcd <- $fopen( dumpFile ) ;
        if ( lmcd == InvalidFile ) begin
            $display("cannot open %s", dumpFile );
            $finish(0);
        end
        lmcd = lmcd | stdout_mcd ; // Bitwise operations with File MCD
        cnt <= 2 ;
        fmcd <= lmcd ; // Save the file in a Register
    endrule

    rule dump (cnt > 1 && cnt <= 10 );
        //$fwrite( fh , "cnt = %0d\n", cnt); // Writes to dump_file1.dat
        //$fwrite( fmcd , "cnt = %0d\n", cnt); // Writes to dump_file2.dat and stdout
        cnt <= cnt + 1;
    endrule

    rule endTb (cnt > 10);
        $finish(0);
    endrule

endmodule: mkTb
*/