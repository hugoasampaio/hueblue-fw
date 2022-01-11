package Tb;

import QPSKmapper::*;

(* synthesize *)
module mkTb (Empty);
    QPSKmapper_type mapper <-mkQPSKmapper;
    
    rule test;
        $display("map of 00 is: ", fshow(mapper.map(2'b00)));
        $finish(0);
    endrule
endmodule: mkTb
endpackage: Tb
