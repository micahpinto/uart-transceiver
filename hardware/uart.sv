module uart #(
	parameter CLK_FREQ = 100_000_000,
	parameter BAUD_RATE = 9600)
(
	input logic [3:0] data_in, // only in this case to verify that the 4 inputs appear at the  output, since we have only 4 leds and not 8.
	input logic data_en,
	input logic clk,
	input logic rstn,
	output logic tx,
	output logic tx_busy,
	input logic ready_clr,
	input logic rx,
	output logic ready,
	output logic [3:0] led_out,
	output logic [6:0] display_out
);
	logic [7:0] data_input; 
	logic [7:0] data_output;
	
	transmitter #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) uart_tx (
		.data_in(data_input),
		.data_en(data_en),
		.clk(clk),
		.rstn(rstn),
		.tx(tx),
		.tx_busy(tx_busy)
	);
	
	receiver #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) uart_rx (
		.clk(clk),
		.rstn(rstn),
		.ready_clr(ready_clr),
		.rx(rx),
		.ready(ready),
		.data_out(data_output)
	);
	
	binary_to_7seg converter (
		.data_in(data_output[3:0]),
		.data_out(display_out)
	);
	
	assign data_input = {4'b0, data_in};
	assign led_out = data_output[3:0];
	
endmodule
