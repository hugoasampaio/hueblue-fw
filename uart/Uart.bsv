package UartIface

import RS232::*;
import GetPut::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;


interface UartIface;
    interface RS232 rs232;
    interface Reset rs232_rst;    
endinterface

(* synthesize *)
module mkUartIface#(Clock clk_uart)(UartIface);
    Reset rst_uart <- mkAsyncResetFromCR(2, clk_uart);
    UART#(16) uart <- mkUART(8, NONE, STOP_1, 1, clocked_by clk_uart, reset_by rst_uart);
    rule discard_uart_input;
        let b <- uart.tx.get;
    endrule

    SyncFIFOIfc#(Bit#(8)) fifo_uart <- mkSyncFIFOFromCC(2, clk_uart);
    mkConnection(toGet(fifo_uart), uart.rx);

    interface rs232 = uart.rs232;
    interface rs232_rst = rst_uart;

endmodule
endpackage