`timescale 1ns/1ps

module transmitter #(
	parameter CLOCKS_PER_BIT = 100
)
(
	input logic [7:0] data_in,
	input logic data_en,
	input logic clk,
	input logic rstn,
	output logic tx,
	output logic tx_busy
);

	typedef enum logic [3:0] {
		IDLE   = 4'b0000,
		START  = 4'b0001,
		BIT0   = 4'b0010,
		BIT1   = 4'b0011,
		BIT2   = 4'b0100,
		BIT3   = 4'b0101,
		BIT4   = 4'b0110,
		BIT5   = 4'b0111,
		BIT6   = 4'b1000,
		BIT7   = 4'b1001,
		STOP   = 4'b1010
	} state_t;

	state_t state, next_state;
	logic [7:0] data_reg;
	logic [19:0] clk_count;

	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= IDLE;
			data_reg <= 8'b0;
			clk_count <= 20'b0;
		end else begin
			state <= next_state;

			if (clk_count == CLOCKS_PER_BIT - 1) begin
				clk_count <= 20'b0;
			end else begin
				clk_count <= clk_count + 1'b1;
			end

			if ((state == IDLE) && (next_state == START)) begin
				data_reg <= data_in;
			end
		end
	end

	always_comb begin
		case (state)
			IDLE:  tx = 1'b1;
			START: tx = 1'b0;
			BIT0:  tx = data_reg[0];
			BIT1:  tx = data_reg[1];
			BIT2:  tx = data_reg[2];
			BIT3:  tx = data_reg[3];
			BIT4:  tx = data_reg[4];
			BIT5:  tx = data_reg[5];
			BIT6:  tx = data_reg[6];
			BIT7:  tx = data_reg[7];
			STOP:  tx = 1'b1;
			default: tx = 1'b1;
		endcase
	end

	always_comb begin
		next_state = state;

		case (state)
			IDLE: begin
				if (data_en) begin
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

	assign tx_busy = (state != IDLE);

endmodule
