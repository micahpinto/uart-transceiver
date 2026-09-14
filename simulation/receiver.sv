`timescale 1ns/1ps

module receiver #(
	parameter CLOCKS_PER_BIT = 100
)
(
	input logic clk,
	input logic rstn,
	input logic ready_clr,
	input logic rx,
	output logic ready,
	output logic [7:0] data_out
);
	localparam BIT_MIDDLE = CLOCKS_PER_BIT / 2;
	
	typedef enum logic [2:0] {
		IDLE   = 3'b000,
		START  = 3'b001,
		BIT0   = 3'b010,
		BIT1   = 3'b011,
		BIT2   = 3'b100,
		BIT3   = 3'b101,
		BIT4   = 3'b110,
		BIT5   = 3'b111,
		BIT6   = 4'b1000,
		BIT7   = 4'b1001,
		STOP   = 4'b1010
	} state_t;

	state_t state, next_state;
	logic [7:0] data_reg;
	logic [7:0] data_latched;
	logic [19:0] clk_count;
	logic rx_sync1, rx_sync2, rx_sync2_d;
	logic rx_edge;
	logic sample_bit;

	// 2-stage synchronizer for metastability
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			rx_sync1 <= 1'b1;
			rx_sync2 <= 1'b1;
			rx_sync2_d <= 1'b1;
		end else begin
			rx_sync1 <= rx;
			rx_sync2 <= rx_sync1;
			rx_sync2_d <= rx_sync2;
		end
	end
	
	// Falling edge detector (START bit detection)
	assign rx_edge = rx_sync2_d & ~rx_sync2;

	// Sample enable at bit middle
	assign sample_bit = (clk_count == BIT_MIDDLE);

	// Main FSM - Sequential Logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= IDLE;
			data_reg <= 8'b0;
			data_latched <= 8'b0;
			clk_count <= 20'b0;
			ready <= 1'b0;
		end else begin
			state <= next_state;

			// Always increment clock counter
			if (clk_count == CLOCKS_PER_BIT - 1) begin
				clk_count <= 20'b0;
			end else begin
				clk_count <= clk_count + 1'b1;
			end

			// Sample data bits at BIT_MIDDLE
			if (state == BIT0 && sample_bit) begin
				data_reg[0] <= rx_sync2;
			end
			if (state == BIT1 && sample_bit) begin
				data_reg[1] <= rx_sync2;
			end
			if (state == BIT2 && sample_bit) begin
				data_reg[2] <= rx_sync2;
			end
			if (state == BIT3 && sample_bit) begin
				data_reg[3] <= rx_sync2;
			end
			if (state == BIT4 && sample_bit) begin
				data_reg[4] <= rx_sync2;
			end
			if (state == BIT5 && sample_bit) begin
				data_reg[5] <= rx_sync2;
			end
			if (state == BIT6 && sample_bit) begin
				data_reg[6] <= rx_sync2;
			end
			if (state == BIT7 && sample_bit) begin
				data_reg[7] <= rx_sync2;
			end

			// Latch data when STOP bit is sampled
			if (state == STOP && sample_bit) begin
				data_latched <= data_reg;
				ready <= 1'b1;
			end else if (ready_clr) begin
				ready <= 1'b0;
			end
		end
	end

	// Next state logic - Combinational
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
					next_state = BIT0;
				end
			end

			BIT0: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT1;
				end
			end

			BIT1: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT2;
				end
			end

			BIT2: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT3;
				end
			end

			BIT3: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT4;
				end
			end

			BIT4: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT5;
				end
			end

			BIT5: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT6;
				end
			end

			BIT6: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
					next_state = BIT7;
				end
			end

			BIT7: begin
				if (clk_count == CLOCKS_PER_BIT - 1) begin
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

	assign data_out = data_latched;

endmodule
