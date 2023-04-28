package FxpLimType;

import FixedPoint::*;
import CBus::*;

typedef 10 ADDRSIZE; 
typedef 5 DATASIZE; 

typedef ModWithCBus#(ADDRSIZE, DATASIZE, i) FxpLimModWithCBus#(type i);
typedef CBus#(ADDRSIZE, DATASIZE) FxpLimCBus;

interface FxpLimType;
    method FixedPoint#(2, 6)    get();
    method Action               set(FixedPoint#(2,6) x_);
    method Action               limit(UInt#(DATASIZE) val);
endinterface

(* synthesize *)
module mkFxpLimSynth(IWithCBus#(FxpLimCBus, UInt#(DATASIZE)));
   let ifc();
   exposeCBusIFC#(mkFxpLimType) _temp(ifc);
   return (ifc);
endmodule

module [FxpLimModWithCBus] mkFxpLimType(UInt#(DATASIZE));
    FixedPoint#(2, 6) x  = 1.875;
    Reg#(UInt#(DATASIZE)) zeroes = mkCBRegRW(4, 2);

    method FixedPoint#(2, 6) get();
        //TODO: how to truncate?
        // truncate while reading or writing?
        return x;
    endmethod

    method Action set(FixedPoint#(2, 6) x_);
        x <= x_;
    endmethod

    method Action limit(UInt#(DATASIZE) val);
        zeroes <= val;
    endmethod

endmodule

(* synthesize *)
module mkFxpLimTypeTest(Empty);
    let fxpLimIfc();
    mkFxpLimSynth the_Fxp(fxpLimIfc);

    rule display_value(True);
        let value = fromMaybe(0, fxpLimIfc.cbus_ifc.read(4));
        $display("fxp is %b.%b", fxptGetInt(value), fxptGetFrac(value));
        $finish();
    endrule
endmodule
endpackage
