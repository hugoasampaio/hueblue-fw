package Constants;
import FixedPoint::*;
import CBus::*;
import Complex::*;

typedef 8    CBADDRSIZE; //size of configuration address bus to decode
typedef 12    CBDATASIZE; //size of configuration data bus

Integer cleanMask = 'hfff;

typedef 4  INTEGERSIZE; //-8 a 7
 
typedef FixedPoint#(INTEGERSIZE, CBDATASIZE)    REAL_SAMPLE_TYPE;
typedef Complex#(REAL_SAMPLE_TYPE)              COMPLEX_SAMPLE_TYPE;

endpackage
