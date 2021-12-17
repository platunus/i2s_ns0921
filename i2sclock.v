module i2sclock (
	inout wand sda,
	input wire sclk,
	input wire mclk_in,
	output wire mclk,
	output wire bck,
	output wire lrck
);

	reg [3:0] count_bck	= 4'b0;
	reg [5:0] count_lrck	= 6'b0;
	reg bck_m = 1'b0;
	reg lrck_m;
	wire [2:0] bck_n;
	wire [1:0] lrck_n;
	
	wire [7:0] i2c_miso;
	wire [7:0] i2c_mosi;
	reg [7:0] i2c_reg = 8'b00000000;
	
	wire count_bck_or = count_bck[3] | count_bck[2] | count_bck[1] | count_bck[0];
	wire count_lrck_or = count_lrck[5] | count_lrck[4] | count_lrck[3] 
		| count_lrck[2] | count_lrck[1] | count_lrck[0];
//	reg [7:0] i2c_reg = 8'b10100011;
		// [0:0] LRCK: 0:Hi-Z, 1:Output
		// [1:1] BCK: 0:Hi-Z, 1:Output
		// [4:2] BCK div: 000:2, 001:4 010:8, 011:16, 100:32
		// [6:5] LRCK div: 00:32, 01:59, 10:64, 11:88
		// [7:7] MCLK: 0:GND, 1:PassThrough
		
		// 44.1kHz/16:  0b00001111(0x0f)	BCK:1.4MHz(), LRCL=44.1kHz
		// 44.1kHz/32:  0b01001011(0x4b)
		// 88.2kHz/16:  0b00001011(0x0b)
		// 88.2kHz/32:  0b00101011(0x2b)
		// 176.4kHz/16: 0b00000111(0x07)
		// 176.4kHz/32: 0b01000011(0x43)
		//  8kHz:	 0b01110011(0x73)
		// 16kHz:	 0b01101111(0x6f)
		// 24kHz:	 0b00101111(0x2f)
		// 32kHz:	 0b01101011(0x6b)
		//	48kHz:	 0b00101011(0x2b)
		// 96kHz:	 0b00100111(0x27)
		// 192kHz:	 0b00100011(0x23)
			
	I2C_to_GPIO #(.slave_address(7'h41)) i2c ( mclk_in, sda, sclk, i2c_miso, i2c_mosi);
	assign i2c_miso = i2c_reg;
	assign bck_n = i2c_reg[4:2];
	assign lrck_n = i2c_reg[6:5];
	
	assign lrck = (i2c_reg[0] ? lrck_m: 1'bz);
	assign bck = (i2c_reg[1] ? bck_m : 1'bz);
	assign mclk = i2c_reg[7] & mclk_in;
		
	always @(i2c_mosi) begin
		i2c_reg <= i2c_mosi;
	end
	
	always @(posedge mclk_in) begin
		count_bck <= count_bck - 4'd1;
//		if (count_bck == 4'd0) begin
		if (~(count_bck_or)) begin
			if (bck_m == 1'b1) bck_m <= 1'b0;
			else bck_m <= 1'b1;
			case (bck_n)
				3'b000:	count_bck <= 4'd0;	// 2/2-1
				3'b001:	count_bck <= 4'd1;	// 4/2-1
				3'b010:	count_bck <= 4'd3;	// 8/2-1
				3'b011:	count_bck <= 4'd7;	// 16/2-1
				3'b100:	count_bck <= 4'd15;	// 32/2-1
				default:	count_bck <= 4'd3;	// 8/2-1
			endcase
		end
	end
	
	always @(negedge bck_m) begin
		count_lrck <= count_lrck - 6'd1;
//		if (count_lrck == 6'd0) begin
		if (~(count_lrck_or)) begin
			if (lrck_m == 1'b1) begin
				lrck_m <= 1'b0;
				case (lrck_n)
					2'b00: count_lrck <= 6'd15;	// 32/2-1
					2'b01: count_lrck <= 6'd28;	// 59/2-1
					2'b11: count_lrck <= 6'd43;	// 88/2-1
					default: count_lrck <= 6'd31;	// 64/2-1
				endcase
			end else begin
				lrck_m <= 1'b1;
				case (lrck_n)
					2'b00: count_lrck <= 6'd15;	// (32+1)/2-1
					2'b01: count_lrck <= 6'd29;	// (59+1)/2-1
					2'b11: count_lrck <= 6'd43;	// (88+1)/2-1
					default: count_lrck <= 6'd31;	// (64+1)/2-1
				endcase
			end
		end
	end

endmodule