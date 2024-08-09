package Constants;
import FixedPoint::*;
import CBus::*;
import Complex::*;

typedef 8   CBADDRSIZE; //size of configuration address bus to decode
typedef 16  CBDATASIZE; //size of configuration data bus
typedef 8   INTEGERSIZE; //-32 to 31

Integer cleanMask = 'hffff;

typedef FixedPoint#(INTEGERSIZE, CBDATASIZE)    REAL_SAMPLE_TYPE;
typedef Complex#(REAL_SAMPLE_TYPE)              COMPLEX_SAMPLE_TYPE;

endpackage
