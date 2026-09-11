`timescale 1ns/1ps
module receiver #(
	parameter CLK_FREQ = 100_000_000,
	parameter BAUD_RATE = 1_000_000
)
(
	input logic clk,
	input logic rstn,
	input logic ready_clr,
	input logic rx,
	output logic ready,
	output logic [7:0] data_out
);
localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;  // 100 clocks per bit
	localparam BIT_MIDDLE = CLOCKS_PER_BIT / 2 - 1;    // Sample at clock 49
	
	typedef enum logic [2:0] {
		IDLE   = 3'b000,
		START  = 3'b001,
		DATA   = 3'b010,
		STOP   = 3'b011
	} state_t;

	state_t state, next_state;
	logic [7:0] data_reg;
	logic [3:0] bit_count;
	logic [19:0] clk_count;
	logic rx_sync1, rx_sync2;
	logic rx_sync2_d;
	logic rx_edge;

	// Synchronization
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			rx_sync1 <= 1'b1;
			rx_sync2 <= 1'b1;
		end else begin
			rx_sync1 <= rx;
			rx_sync2 <= rx_sync1;
		end
	end
// Detect falling edge on rx (START bit detection)
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			rx_sync2_d <= 1'b1;
		end else begin
			rx_sync2_d <= rx_sync2;
		end
	end
	
	assign rx_edge = rx_sync2_d & ~rx_sync2;  // Falling edge detector
	// Main FSM
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= IDLE;
			data_reg <= 8'b0;
			bit_count <= 4'b0;
			clk_count <= 20'b0;
			ready <= 1'b0;
		end else begin
			state <= next_state;

			if (clk_count == CLOCKS_PER_BIT - 1) begin
				clk_count <= 20'b0;
			end else begin
				clk_count <= clk_count + 1'b1;
			end
// Reset counters when entering START state
			if (next_state == START && state == IDLE) begin
				bit_count <= 4'b0;
				data_reg <= 8'b0;
				clk_count <= 20'b0;
			end
			if ((state == DATA) && (clk_count == BIT_MIDDLE)) begin
				data_reg[bit_count[2:0]] <= rx_sync2;
				bit_count <= bit_count + 1'b1;
			end
if (state == STOP && clk_count == BIT_MIDDLE) begin
				ready <= 1'b1;
			end else if (ready_clr) begin
				ready <= 1'b0;
			end
		end
	end
			

	// Next state logic
	always_comb begin
		next_state = state;

		case (state)
			IDLE: begin
				if (rx_edge) begin
					next_state = START;
				end
			end

			START: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = DATA;
				end
			end

			DATA: begin
				// After receiving all 8 bits, when clk_count reaches 99, go to STOP
				// This means we'll have 100 more clock cycles in STOP state
				if (bit_count == 4'd8 && clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = STOP;
				end
			end

			STOP: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = IDLE;
				end
			end

			default: begin
				next_state = IDLE;
			end
		endcase
	end

	// Output assignment
	assign data_out = data_reg;

endmodule
