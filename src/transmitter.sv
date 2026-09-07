module transmitter #(
	parameter CLOCKS_PER_PULSE = 10417  // For 9600 baud
)
(
	input logic [7:0] data_in,
	input logic data_en,
	input logic clk,
	input logic rstn,
	output logic tx,
	output logic tx_busy
);

	typedef enum logic [1:0] {
		IDLE   = 2'b00,
		START  = 2'b01,
		DATA   = 2'b10,
		STOP   = 2'b11
	} state_t;

	state_t state, next_state;
	
	logic [7:0] data_reg;
	logic [2:0] bit_count;
	logic [12:0] clk_count;

	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= IDLE;
			data_reg <= 8'b0;
			bit_count <= 3'b0;
			clk_count <= 13'b0;
			tx <= 1'b1;
		end else begin
			state <= next_state;

			if (clk_count == CLOCKS_PER_PULSE - 1) begin
				clk_count <= 13'b0;
			end else begin
				clk_count <= clk_count + 1'b1;
			end

			if ((state == IDLE) && (next_state == START)) begin
				data_reg <= data_in;
			end

			if ((state == DATA) && (clk_count == CLOCKS_PER_PULSE - 1)) begin
				if (bit_count == 3'd7) begin
					bit_count <= 3'b0;
				end else begin
					bit_count <= bit_count + 1'b1;
				end
			end
		end
	end

	always_comb begin
		next_state = state;

		case (state)
			IDLE: begin
				tx = 1'b1;
				if (data_en) begin
					next_state = START;
				end
			end

			START: begin
				tx = 1'b0;
				if (clk_count == CLOCKS_PER_PULSE - 1) begin
					next_state = DATA;
				end
			end

			DATA: begin
				tx = data_reg[bit_count];
				if ((clk_count == CLOCKS_PER_PULSE - 1) && (bit_count == 3'd7)) begin
					next_state = STOP;
				end
			end

			STOP: begin
				tx = 1'b1;
				if (clk_count == CLOCKS_PER_PULSE - 1) begin
					next_state = IDLE;
				end
			end

			default: begin
				tx = 1'b1;
				next_state = IDLE;
			end
		endcase
	end

	assign tx_busy = (state != IDLE);

endmodule
