`timescale 1ns/1ps

module tb_uart_wrapper;

	localparam CLOCKS_PER_PULSE = 100;
	localparam CLK_PERIOD = 10;

	logic clk;
	logic rstn;
	logic [3:0] data_in;
	logic data_en;
	logic [3:0] led_out;
	logic tx_busy;
	logic rx_ready;

	uart_wrapper #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) dut (
		.clk(clk),
		.rstn(rstn),
		.data_in(data_in),
		.data_en(data_en),
		.led_out(led_out),
		.tx_busy(tx_busy),
		.rx_ready(rx_ready)
	);

	always begin
		clk = 0;
		#(CLK_PERIOD/2);
		clk = 1;
		#(CLK_PERIOD/2);
	end

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_uart);
		
		rstn = 0;
		data_in = 4'b0;
		data_en = 0;
		
		#(CLK_PERIOD * 10);
		rstn = 1;
		#(CLK_PERIOD * 10);
		
		$display("System Reset Complete\n");
		
		send_and_verify(4'b0101, "Test 1");
		#(CLK_PERIOD * 2000);
		
		send_and_verify(4'b1010, "Test 2");
		#(CLK_PERIOD * 2000);
		
		send_and_verify(4'b1111, "Test 3");
		#(CLK_PERIOD * 2000);
		
		send_and_verify(4'b0000, "Test 4");
		#(CLK_PERIOD * 2000);
		
		send_and_verify(4'b0011, "Test 5");
		#(CLK_PERIOD * 2000);
		
		send_and_verify(4'b1100, "Test 6");
		#(CLK_PERIOD * 2000);
		
		$display("\nAll Tests Passed!");
		$finish;
	end

	task send_and_verify(input logic [3:0] test_data, input string test_name);
		begin
			send_data(test_data);
			wait_for_rx();
			check_output(test_data, test_name);
		end
	endtask

	task send_data(input logic [3:0] data);
		begin
			data_in = data;
			data_en = 1;
			@(posedge clk);
			data_en = 0;
			$display("Sending: 0x%X (%b)", data, data);
		end
	endtask

	task wait_for_rx();
		begin
			integer timeout = 0;
			while (!rx_ready && timeout < 200000) begin
				@(posedge clk);
				timeout++;
			end
			if (rx_ready) begin
				$display("  RX Ready (waited %d clocks)", timeout);
				@(posedge clk);
				@(posedge clk);
				@(posedge clk);
				@(posedge clk);
				@(posedge clk);
			end
		end
	endtask

	task check_output(input logic [3:0] expected, input string test_name);
		begin
			if (led_out == expected) begin
				$display(" PASS: led_out = 0x%X\n", led_out);
			end else begin
				$display(" FAIL: led_out = 0x%X, expected 0x%X\n", led_out, expected);
			end
		end
	endtask

endmodule
