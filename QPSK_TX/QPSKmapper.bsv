package QPSKmapper;

import Complex::*;

interface QPSKmapper_type;
   method Complex#(Int#(13)) map (Bit#(2) bits);
endinterface: QPSKmapper_type

(* synthesize *)
module mkQPSKmapper (QPSKmapper_type);

   method Complex#(Int#(13)) map (Bit#(2) bits);
      Complex#(Int#(13)) ret = cmplx(-1, -1);
      case (bits)
         2'b00: ret = cmplx(-1, -1);
	      2'b01: ret = cmplx(-1,  1);
	      2'b10: ret = cmplx( 1, -1);
	      2'b11: ret = cmplx( 1,  1);
      endcase
      return ret;
   endmethod

endmodule: mkQPSKmapper

endpackage: QPSKmapper
