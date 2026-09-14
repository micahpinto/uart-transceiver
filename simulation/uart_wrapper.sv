module uart_wrapper (
    input logic clk,
    input logic rstn,
    input logic [3:0] data_in,
    input logic data_en,
    output logic [3:0] led_out,
    output logic tx_busy,
    output logic rx_ready
);
    logic tx_line;  // ← INTERNAL LOOPBACK
    
    transmitter uart_tx (
        .tx(tx_line)  // ← Transmits to internal wire
    );
    
    receiver uart_rx (
        .rx(tx_line)  // ← Receives from same wire
    );
endmodule
