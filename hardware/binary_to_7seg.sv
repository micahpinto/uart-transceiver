module binary_to_7seg ( 
	input logic [3:0] data_in,
	output logic [6:0] data_out
);
    logic [15:0][6:0] lut_7seg;
    
    assign lut_7seg[0] = 7'b0111111;
    assign lut_7seg[1] = 7'b0000110;
    assign lut_7seg[2] = 7'b1011011;
    assign lut_7seg[3] = 7'b1001111;
    assign lut_7seg[4] = 7'b1100110;
    assign lut_7seg[5] = 7'b1101101;
    assign lut_7seg[6] = 7'b1111101;
    assign lut_7seg[7] = 7'b0000111;
    assign lut_7seg[8] = 7'b1111111;
    assign lut_7seg[9] = 7'b1101111;
    // Entries 10-15 default to 0
	 
	 assign data_out = ~lut_7seg[data_in];
	 
endmodule
