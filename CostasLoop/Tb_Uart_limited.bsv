package Tb_Uart_limited;

import CostasLoop_limited::*;
import StmtFSM::*;
import Complex::*;
import FixedPoint::*;
import CBus::*;
import Constants::*;
import RS232::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;
import Connectable::*;

interface UartIface;
    interface RS232 rs232;    
endinterface

(* synthesize *)
module mkTb (UartIface);
    IWithCBus#(LimitedCostasLoop, CostasLoop_IFC) cc <- exposeCBusIFC(mkCostasLoop);
    UART#(16) uart <- mkUART(8, NONE, STOP_1, 315);
    
    FIFO#(Bit#(8)) fifo_uart_rx <- mkSizedFIFO(100);
    FIFO#(Bit#(8)) fifo_uart_tx <- mkSizedFIFO(100);
    //inverted so tx means out, rx means in
    mkConnection(toGet(fifo_uart_tx), uart.rx);
    mkConnection(uart.tx, toPut(fifo_uart_rx));

    Reg#(Bit#(8)) phV <-mkReg(0);
	Reg#(Bit#(8)) errV <-mkReg(0);
	Reg#(Bit#(8)) frV <-mkReg(0);
    Reg#(Bit#(8)) inV <-mkReg(0);
    Reg#(Bit#(8)) outV <-mkReg(0);

    Reg#(Bit#(8)) xV <-mkReg(0);
    Reg#(Bit#(8)) yV <-mkReg(0);
    Reg#(Bit#(8)) zV <-mkReg(0);

    Reg#(REAL_SAMPLE_TYPE) realValue <-mkReg(0);
    Reg#(REAL_SAMPLE_TYPE) imagValue <-mkReg(0);
    Reg#(COMPLEX_SAMPLE_TYPE) fixValue <-mkReg(0);

    Reg#(Bit#(24)) real_bytes <-mkReg(0);
    Reg#(Bit#(24)) imag_bytes <-mkReg(0);
    Reg#(Bit#(48)) fix_bytes <-mkReg(0);
    
    Reg#(UInt#(10)) n <- mkReg(0);

    Stmt test = seq
      while(True) seq
        fifo_uart_tx.enq(80);
        fifo_uart_tx.enq(79);
        fifo_uart_tx.enq(78);
        fifo_uart_tx.enq(71);
        fifo_uart_tx.enq(13);

        action
        //let b <- uart.tx.get();
        //phV <= b;
        phV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();   
        endaction

        action
        //let b <- uart.tx.get();
        //errV <= b;
        errV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction

        action
        //let b <- uart.tx.get();
        //frV <= b;
        frV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction

        action
        //let b <- uart.tx.get();
        //inV <= b;
        inV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction

        action
        //let b <- uart.tx.get();
        //outV <= b;
        outV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction

        action
        //let b <- uart.tx.get();
        //xV <= b;
        xV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction
        action
        //let b <- uart.tx.get();
        //yV <= b;
        yV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction
        action
        //let b <- uart.tx.get();
        //zV <= b;
        zV <= fifo_uart_rx.first();
        fifo_uart_rx.deq();
        endaction
        
		cc.cbus_ifc.write(31, fromInteger(cleanMask) << phV);
		cc.cbus_ifc.write(32, fromInteger(cleanMask) << errV);
		cc.cbus_ifc.write(33, fromInteger(cleanMask) << frV);
        cc.cbus_ifc.write(34, fromInteger(cleanMask) << inV);
        cc.cbus_ifc.write(35, fromInteger(cleanMask) << outV);

        cc.cbus_ifc.write(41, fromInteger(cleanMask) << xV);
		cc.cbus_ifc.write(42, fromInteger(cleanMask) << yV);
		cc.cbus_ifc.write(43, fromInteger(cleanMask) << zV);

        for (n<=0; n < 83; n <= n+1) seq
            /*read 3 bytes for real
            1st byte is integer
            2nd and 3rd is fractional
            */
            action
            //let b <- uart.tx.get();
            //real_bytes[23:16] <= b;
            real_bytes[23:16] <= fifo_uart_rx.first(); 
            fifo_uart_rx.deq();
            endaction
            action
            //let b <- uart.tx.get();
            //real_bytes[15:8] <= b;
            real_bytes[15:8] <= fifo_uart_rx.first();
            fifo_uart_rx.deq();            
            endaction
            action
            //let b <- uart.tx.get();
            //real_bytes[7:0] <= b;
            real_bytes[7:0] <= fifo_uart_rx.first();
            fifo_uart_rx.deq();
            endaction
            realValue.i <= unpack(real_bytes[23:16]);
            realValue.f <= unpack(real_bytes[15:0]);

            /*read 3 bytes for imaginary
            1st byte is integer
            2nd and 3rd is fractional
            */
            action
            //let b <- uart.tx.get();
            //imag_bytes[23:16] <= b;
            imag_bytes[23:16] <= fifo_uart_rx.first();
            fifo_uart_rx.deq();
            endaction
            action
            //let b <- uart.tx.get();
            //imag_bytes[15:8] <= b;
            imag_bytes[15:8] <= fifo_uart_rx.first();
            fifo_uart_rx.deq();
            endaction
            action
            //let b <- uart.tx.get();
            //imag_bytes[7:0] <= b;
            imag_bytes[7:0] <= fifo_uart_rx.first();
            fifo_uart_rx.deq();
            endaction
            imagValue.i <= unpack(imag_bytes[23:16]);
            imagValue.f <= unpack(imag_bytes[15:0]);
    
            cc.device_ifc.addSample(cmplx(realValue , imagValue));
            action
            let fix <- cc.device_ifc.getFixedSample;
            fixValue <= fix;
            endaction
            fix_bytes <= 0;
            fix_bytes[47:40] <= pack(fixValue.rel.i);
            fix_bytes[39:24] <= pack(fixValue.rel.f);

            fix_bytes[23:16] <= pack(fixValue.img.i);
            fix_bytes[15:00] <= pack(fixValue.img.f);

            //real
            fifo_uart_tx.enq(fix_bytes[47:40]);
            fifo_uart_tx.enq(fix_bytes[39:32]);
            fifo_uart_tx.enq(fix_bytes[31:24]);
            //imag
            fifo_uart_tx.enq(fix_bytes[23:16]);
            fifo_uart_tx.enq(fix_bytes[15:08]);
            fifo_uart_tx.enq(fix_bytes[07:00]);

        endseq
      endseq
    endseq;
    mkAutoFSM(test);

    interface rs232 = uart.rs232;
    
endmodule: mkTb
endpackage: Tb_Uart_limited
