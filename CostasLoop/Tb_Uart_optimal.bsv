package Tb_Uart_optimal;

import CostasLoop_optimal::*;
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
    interface Reset rs232_rst;    
endinterface

(* synthesize *)
module mkTb#(Clock clk_uart) (UartIface);
    CostasLoop_IFC cc <- mkCostasLoop();

    Reset rst_uart <- mkAsyncResetFromCR(2, clk_uart);
    UART#(16) uart <- mkUART(8, NONE, STOP_1, 1, clocked_by clk_uart, reset_by rst_uart);
    
    SyncFIFOIfc#(Bit#(8)) fifo_uart_rx <- mkSyncFIFOToCC(2, clk_uart, rst_uart);
    SyncFIFOIfc#(Bit#(8)) fifo_uart_tx <- mkSyncFIFOFromCC(2, clk_uart);
    //inverted so tx means out, rx means in
    mkConnection(toGet(fifo_uart_tx), uart.rx);
    mkConnection(toPut(fifo_uart_rx), uart.tx);

    Reg#(FixedPoint#(4, 1)) realValue <-mkReg(0);
    Reg#(FixedPoint#(4, 1)) imagValue <-mkReg(0);
    Reg#(Complex#(FixedPoint#(4, 3))) fixValue <-mkReg(0);

    Reg#(Bit#(32)) real_bytes <-mkReg(0);
    Reg#(Bit#(32)) imag_bytes <-mkReg(0);
    Reg#(Bit#(64)) fix_bytes <-mkReg(0);
    
    Reg#(UInt#(10)) n <- mkReg(0);

    Stmt test = seq
        for (n<=0; n < 83; n <= n+1) seq
            action
            real_bytes[31:24] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[23:16] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[15:8] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            real_bytes[7:0] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            realValue.i <= unpack(real_bytes[4+15:16]);
            realValue.f <= unpack(real_bytes[15]);

            action
            imag_bytes[31:24] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[23:16] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[15:8] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            action
            imag_bytes[7:0] <= fifo_uart_rx.first;
            fifo_uart_rx.deq;
            endaction
            imagValue.i <= unpack(imag_bytes[4+15:16]);
            imagValue.f <= unpack(imag_bytes[15]);
    
            cc.addSample(cmplx(realValue , imagValue));
            action
            let fix <- cc.getFixedSample;
            fixValue <= fix;
            endaction
            fix_bytes <= 0;
            
            fix_bytes[51:48] <= pack(fixValue.rel.i);
            fix_bytes[47:45] <= pack(fixValue.rel.f);
            fix_bytes[19:16] <= pack(fixValue.img.i);
            fix_bytes[15:13] <= pack(fixValue.img.f);
            
            fifo_uart_tx.enq(fix_bytes[63:56]);
            fifo_uart_tx.enq(fix_bytes[55:48]);
            fifo_uart_tx.enq(fix_bytes[47:40]);
            fifo_uart_tx.enq(fix_bytes[39:32]);
            fifo_uart_tx.enq(fix_bytes[31:24]);
            fifo_uart_tx.enq(fix_bytes[23:16]);
            fifo_uart_tx.enq(fix_bytes[15:08]);
            fifo_uart_tx.enq(fix_bytes[07:00]);

        endseq
    endseq;
    mkAutoFSM(test);

    interface rs232 = uart.rs232;
    interface rs232_rst = rst_uart;
    
endmodule: mkTb
endpackage: Tb_Uart_optimal

