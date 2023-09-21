package FIRcoeff;
import FixedPoint::*;
import Vector::*;

typedef FixedPoint#(3, 16) FIRtap_Type;
typedef FixedPoint#(6, 32) FIRPreciseTap_Type;
//typedef Real FIRtap_Type;
//typedef Int#(16) FIRtap_Type;
Integer nTAPS = 43;

function FIRPreciseTap_Type energy_filter();
    FIRPreciseTap_Type acc = 0.0;
    for (Integer n = 0; n < 43; n = n+1)
        acc = acc + (coeff_precise[n] * coeff_precise[n]);
    return acc;

endfunction

 FIRtap_Type coeff[nTAPS] = {
 -0.01897049, 
 -0.01842133, 
 -0.00954316,  
  0.00624239,  
  0.02459163,  
  0.03898283,
  0.04231734,  
  0.02906669, 
 -0.00255221, 
 -0.04897974, 
 -0.10083352, 
 -0.1438624,
 -0.16131922, 
 -0.13737078, 
 -0.0608575,   
  0.07144658,  
  0.25288767,  
  0.46687654,
  0.68890519,  
  0.89035557,  
  1.04339768,  
  1.12599805,  
  1.12599805,  
  1.04339768,
  0.89035557,  
  0.68890519,  
  0.46687654, 
  0.25288767,  
  0.07144658, 
 -0.0608575,
 -0.13737078, 
 -0.16131922, 
 -0.1438624,  
 -0.10083352, 
 -0.04897974, 
 -0.00255221,
  0.02906669,  
  0.04231734,  
  0.03898283,  
  0.02459163,  
  0.00624239, 
 -0.00954316,
 -0.01842133};

 FIRPreciseTap_Type coeff_precise[nTAPS] = {
 -0.01897049, 
 -0.01842133, 
 -0.00954316,  
  0.00624239,  
  0.02459163,  
  0.03898283,
  0.04231734,  
  0.02906669, 
 -0.00255221, 
 -0.04897974, 
 -0.10083352, 
 -0.1438624,
 -0.16131922, 
 -0.13737078, 
 -0.0608575,   
  0.07144658,  
  0.25288767,  
  0.46687654,
  0.68890519,  
  0.89035557,  
  1.04339768,  
  1.12599805,  
  1.12599805,  
  1.04339768,
  0.89035557,  
  0.68890519,  
  0.46687654, 
  0.25288767,  
  0.07144658, 
 -0.0608575,
 -0.13737078, 
 -0.16131922, 
 -0.1438624,  
 -0.10083352, 
 -0.04897974, 
 -0.00255221,
  0.02906669,  
  0.04231734,  
  0.03898283,  
  0.02459163,  
  0.00624239, 
 -0.00954316,
 -0.01842133};

endpackage: FIRcoeff
