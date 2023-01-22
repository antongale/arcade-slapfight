//============================================================================
// 
//  SD card ROM loader and ROM selector for MISTer.
//  Copyright (C) 2019 Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//	 the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	 and/or sell copies of the Software, and to permit persons to whom the 
//	 Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//	 all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//	 DEALINGS IN THE SOFTWARE.
//
//============================================================================

// Rom layout for Performan:
// 0x00000 - 0x03FFF = eprom_0A - Main CPU Program
// 0x04000 - 0x07FFF = eprom_0B - Main CPU Program
// 0x10000 - 0x11FFF = eprom_2 - Audio CPU Program
// 0x12000 - 0x13FFF = eprom_3 - Foreground - Chars
// 0x14000 - 0x15FFF = eprom_4 - Foreground - Chars
// 0x16000 - 0x1DFFF = eprom_5 - Background - Tiles
// 0x1E000 - 0x25FFF = eprom_6 - Background - Tiles
// 0x26000 - 0x2DFFF = eprom_7 - Background - Tiles
// 0x2E000 - 0x35FFF = eprom_8 - Background - Tiles


module selector
(
	input logic [24:0] ioctl_addr,
	output logic ep0_cs, ep0b_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, ep6_cs, ep7_cs, ep9_cs, ep10_cs, ep11_cs, ep13_cs,ep_dummy_cs,cp1_cs,cp2_cs,cp3_cs,hs_cs,vs_cs,spreg1_cs,spreg2_cs,spseq_cs
);

	always_comb begin
					{ep0_cs, ep0b_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, ep6_cs, ep7_cs, ep9_cs, ep10_cs, ep11_cs, ep13_cs,ep_dummy_cs,cp1_cs,cp2_cs,cp3_cs,hs_cs,vs_cs,spreg1_cs,spreg2_cs,spseq_cs} = 0;


		if     (ioctl_addr < 'h04000) ep0_cs = 1; 		// 0x4000 13   - Main CPU
		else if(ioctl_addr < 'h08000) ep0b_cs = 1;		// 0x4000 13   - Main CPU
		else if(ioctl_addr < 'h0A000) ep2_cs = 1; 		// 0x2000 14	- Audio CPU Program
		else if(ioctl_addr < 'h0C000) ep3_cs = 1; 		// 0x2000 12   - Foreground - Chars
		else if(ioctl_addr < 'h0E000) ep4_cs = 1; 		// 0x2000 12   - Foreground - Chars
		else if(ioctl_addr < 'h10000) ep_dummy_cs = 1; 	// 0x2000 12   - Foreground - Chars
		else if(ioctl_addr < 'h12000) ep5_cs = 1; 		// 0x8000 14   - Background - Tiles
		else if(ioctl_addr < 'h14000) ep6_cs = 1; 		// 0x8000 14	- Background - Tiles
		else if(ioctl_addr < 'h16000) ep7_cs = 1; 		// 0x8000 14	- Background - Tiles
		else if(ioctl_addr < 'h18000) ep9_cs = 1;			// 0x8000 14	- Sprites
		else if(ioctl_addr < 'h1A000) ep10_cs = 1; 		// 0x8000 14	- Sprites
		else if(ioctl_addr < 'h1C000) ep11_cs = 1; 		// 0x8000 14	- Sprites
		else if(ioctl_addr < 'h1C100) cp1_cs = 1; 		// 0x8000 14	- Colour Prom #1
		else if(ioctl_addr < 'h1C200) cp2_cs = 1; 		// 0x8000 14	- Colour Prom #2
		else if(ioctl_addr < 'h1C300) cp3_cs = 1; 		// 0x8000 14	- Colour Prom #3
		else if(ioctl_addr < 'h1C400) hs_cs = 1; 			// 0x8000 14	- Colour Prom #3
		else if(ioctl_addr < 'h1C500) vs_cs = 1; 			// 0x8000 14	- Colour Prom #3
		else if(ioctl_addr < 'h1C600) spreg1_cs = 1; 	// 0x00100 8	- Sprite Register Prom #1
		else if(ioctl_addr < 'h1C700) spreg2_cs = 1; 	// 0x00100 8	- Sprite Register Prom #2
		else if(ioctl_addr < 'h1C720) spseq_cs = 1; 		// 0x00020 5	- Sprite Sequencer Prom #3
		
		else ep13_cs = 1; // 0x8000 14	- Background - Tiles

	end
endmodule

////////////
// EPROMS //
////////////

module eprom_0 //program
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic        CEN,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);

	dpram_dc #(.widthad_a(14)) eprom_0
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA),
		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule


module eprom_0b //program
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic        CEN,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);

	dpram_dc #(.widthad_a(14)) eprom_0b
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA),
		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_2 //audio program
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);

	dpram_dc #(.widthad_a(13)) eprom_2
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),
		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_3
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);

	dpram_dc #(.widthad_a(13)) eprom_3
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),
		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_4
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_4
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_dummy
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_dummy
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_5
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_5
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule


module eprom_6
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_6
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule



module eprom_7
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_7
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule


module eprom_9
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_9
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_10
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_10
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_11
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_11
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule



///////////
// PROMS //
///////////

module cprom_1
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) cprom_1
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module cprom_2
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) cprom_2
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module cprom_3
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) cprom_3
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule


module spreg1_rom
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) spreg1_rom
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module spreg2_rom
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) spreg2_rom
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module spseq_rom
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [4:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(5)) spseq_rom
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[4:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule
