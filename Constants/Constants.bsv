package Constants;
import FixedPoint::*;
import CBus::*;
import Complex::*;

typedef 8    CBADDRSIZE; //size of configuration address bus to decode
typedef 16   CBDATASIZE; //size of configuration data bus

Integer cleanMask = 'hffff;

typedef 12  INTEGERSIZE; //-2048 a 2047, atan tem ²
 
typedef FixedPoint#(INTEGERSIZE, CBDATASIZE)    REAL_SAMPLE_TYPE;
typedef Complex#(REAL_SAMPLE_TYPE)              COMPLEX_SAMPLE_TYPE;

endpackage