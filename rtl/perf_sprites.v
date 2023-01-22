//Sprite Layer Renderer - With additional sprite priority support
module sprite_layer (
	input master_clk,
	input pixel_clk,
	input npixel_clk,
	input pixel_clk_lb,
	input [7:0] VPIX,
	input [11:0] HPIX,
	input SCREEN_FLIP,
	input SPRITE_RAM,
	input Z80_WR,
	input Z80_RD,
	input CPU_RAM_SYNC,
	input CPU_RAM_SELECT,
	input CPU_RAM_LBUF,
	input IO_C_SPRITE_COLOUR,
	input [15:0] CPU_ADDR,
	input  [7:0] CPU_DIN,

	input [24:0] dn_addr,
	input [7:0] dn_data,
	input ep9_cs_i,
	input ep10_cs_i,
	input ep11_cs_i,
	input ep12_cs_i,
	input	spreg1_cs_i, 
	input	spreg2_cs_i, 
	input	spseq_cs_i,	
	input dn_wr,

	output [7:0] SP_RAMD_out,
	output [7:0] pixel_output
);

reg [11:0] SPR_CNT;

wire [11:0] SP_RAMA;

wire [7:0] SPRITE_RAM_D;
wire [7:0] SPR_VPIX_out;
wire [7:0] SPR_IDX_out;
wire [7:0] SPR_EXTRA_out;
wire [7:0] SPR_HPOS_out;

reg [7:0] ROM18_addr;

wire nCPU_RAM_SELECT=!CPU_RAM_SELECT;
wire SPR_CPU_RAM_SELECT=!nCPU_RAM_SELECT;
wire nCPU_RAM_SYNC=!CPU_RAM_SYNC;
//*********START: chip selects **************
//rom address should get set to zero when CPU_RAM_SYNC
always @(posedge pixel_clk or negedge nCPU_RAM_SYNC) 	ROM18_addr <= (!nCPU_RAM_SYNC) ? 8'd0 :
																		(!RESET_LD_CTR) ? 8'b00000100 : ROM18_addr+1; 

																		
reg [8:0] HPIX_LT;
always @(posedge pixel_clk) begin 
	HPIX_LT <= HPIX[8:0];  //this is a 'de-scrambled' version of HPIX_PT - U2D
end

wire [7:0] ROM18_out;

spseq_rom S2_U2B_ROM18
(
	.ADDR(ROM18_addr[4:0]),
	.CLK(master_clk),
	.DATA(ROM18_out),

	.ADDR_DL(dn_addr),
	.CLK_DL(master_clk),
	.DATA_IN(dn_data),
	.CS_DL(spseq_cs_i),
	.WR(dn_wr)
);

wire [3:0] S2_U2A_rout;
wire [3:0] S2_U4A_rout;
wire [3:0] S2_U2A_out;
wire [3:0] S2_U4A_out;

ls175 S2_U2A(
	.nMR(nCPU_RAM_SYNC),
	.clk(pixel_clk),
	.D(ROM18_out[3:0]),
	.Q(S2_U2A_out),
	.nQ()
);

ls175 S2_U4A(
	.nMR(nCPU_RAM_SYNC),
	.clk(pixel_clk),
	.D(ROM18_out[7:4]),
	.Q(S2_U4A_out),
	.nQ()
);

wire SPR_REG_OE=S2_U2A_out[0];
wire SPR_ROM_LD=!S2_U2A_out[1]|CPU_RAM_SYNC;
wire SPR_LB_LD=!S2_U2A_out[2];
wire SPR_8HPIX=!S2_U2A_out[3];
wire S2_U4A_3=!S2_U4A_out[0];
wire S2_U4A_6=!S2_U4A_out[1];
wire S2_U4A_10=S2_U4A_out[2];
wire S2_U4A_11=!S2_U4A_out[2];
wire RESET_LD_CTR=!S2_U4A_out[3];
//*********  END: chip selects **************

//*********START: register latches **************
reg [7:0] SPR_ROM1617_ADDR;

wire SPR_ROM_ADDR_RST=RST_REG_CTR|SPR_CPU_RAM_SELECT; //S2_U4C_D

always @(posedge npixel_clk or posedge SPR_ROM_ADDR_RST) SPR_ROM1617_ADDR <= (SPR_ROM_ADDR_RST) ? 8'd0 : SPR_ROM1617_ADDR+1; //clear on RST going high, may not be clocked - observe behaviour

wire [7:0] ROM17_out;
wire [7:0] ROM16_out;

spreg1_rom S2_U1E_ROM16
(
	.ADDR(SPR_ROM1617_ADDR),
	.CLK(master_clk),
	.DATA(ROM16_out),

	.ADDR_DL(dn_addr),
	.CLK_DL(master_clk),
	.DATA_IN(dn_data),
	.CS_DL(spreg1_cs_i),
	.WR(dn_wr)
);

spreg2_rom S2_U1C_ROM17
(
	.ADDR(SPR_ROM1617_ADDR),
	.CLK(master_clk),
	.DATA(ROM17_out),

	.ADDR_DL(dn_addr),
	.CLK_DL(master_clk),
	.DATA_IN(dn_data),
	.CS_DL(spreg2_cs_i),
	.WR(dn_wr)
);

reg [5:0] S2_U1F_out;

always @(posedge pixel_clk) S2_U1F_out <= ({ROM16_out[1:0],ROM17_out[3:0]});

wire SPR_INC_CNT=S2_U1F_out[3];
wire RST_REG_CTR=S2_U1F_out[5];

always @(posedge SPR_INC_CNT or posedge SPR_CPU_RAM_SELECT) SPR_CNT <= (SPR_CPU_RAM_SELECT) ? 12'd0 : SPR_CNT+12'd1;  //this code doesn't see the clear is it isn't clocking at the time

wire S2_U1G_7,S2_U1G_9,S2_U1G_10,SPR_LAT_INDX,SPR_LAT_VPOS,SPR_LAT_XDAT,SPR_LAT_HPOS,S2_U1G_O0;
ls138x S2_U1G( //sf
  .nE1(1'b0),
  .nE2(pixel_clk),
  .E3(1'b1),
  .A(S2_U1F_out[2:0]),
  .Y({S2_U1G_7,S2_U1G_9,S2_U1G_10,SPR_LAT_INDX,SPR_LAT_VPOS,SPR_LAT_XDAT,SPR_LAT_HPOS,S2_U1G_O0})
);


//*********  END: register latches **************

//SPRITE RAM - mainboard -
dpram_dc #(.widthad_a(11)) SP_U2L //sf
(
	.clock_a(master_clk),
	.address_a(SPR_CNT[10:0]),  //sprite hardware address
	.data_a(CPU_DIN),
	.wren_a(1'b0),
	.q_a(SPRITE_RAM_D),

	.clock_b(master_clk),
	.address_b(CPU_ADDR[10:0]),
	.data_b(CPU_DIN),
	.wren_b(!Z80_WR & !SPRITE_RAM),
	.q_b(SP_RAMD_out)

);

//START: SPRITE REGISTERS
reg [7:0] SPR_VPOS_D;
reg [7:0] SPR_EXT_D;
reg [9:0] SPR_IDX_D;
reg [8:0] SPR_HPOS_D;
wire [3:0] SPR_VPIX;
//END: SPRITE REGISTERS

always @(posedge SPR_LAT_VPOS) SPR_VPOS_D      <= SPRITE_RAM_D;	//S2_U1H
always @(posedge SPR_LAT_INDX) SPR_IDX_D[7:0]  <= SPRITE_RAM_D;	//S2_U1J
always @(posedge SPR_LAT_HPOS) SPR_HPOS_D[7:0] <= SPRITE_RAM_D;	//S2_U1L 
always @(posedge SPR_LAT_XDAT) SPR_EXT_D       <=SPRITE_RAM_D;//S2_U1K

//START: VPIX & SPR_32K ADDRESS GENERATION
wire S2_U7B_AQ=!S2_U1G_10&S2_U1G_9; //S2_U7B LS74
wire S2_U7B_AnQ=!S2_U7B_AQ;
reg [4:0] SPR_VPIX_CNT;
reg [7:0] SPR_VPOS_CNT;

//S2_U7B_A
wire S2_U7BA_Q;
wire S2_U7BA_nQ;

ls74 S2_U7B 
(
	.n_pre1(S2_U1G_10), 
	.n_clr1(S2_U1G_9), 
	.clk1(1'b0), 
	.d1(1'b0), 
	.q1(S2_U7BA_Q), 
   .n_q1(S2_U7BA_nQ), 
	
	.n_pre2(S2_U7BA_nQ),
	.n_clr2(1'b1),
	.clk2(S2_U9B_D),
	.d2(1'b0),
	.q2(S2_U7BB_Q),
	.n_q2(S2_U7BB_nQ)
);

wire S2_U9B_D = SPR32_CLK|!(SPR_VPIX_CNT[0]&SPR_VPIX_CNT[1]&SPR_VPIX_CNT[2]&SPR_VPIX_CNT[3]);

wire S2_U7BB_Q;
wire S2_U7BB_nQ;// = !S2_U7BB_Q;

always @(posedge SPR32_CLK) begin
	SPR_VPIX_CNT <= (!S2_U7B_AnQ) ? 5'd0			: (S2_U7BB_Q) ? SPR_VPIX_CNT+1 : SPR_VPIX_CNT; //S2_U7C
	SPR_VPOS_CNT <= (!S2_U7B_AnQ) ? SPR_VPOS_D 	: (S2_U7BB_Q) ? SPR_VPOS_CNT+1 : SPR_VPOS_CNT; //S2_u5F & S2_U7F
end

assign SPR_VPIX[3:0]=(!SPR_REG_OE) ? SPR_VPIX_CNT[3:0] : 4'd0; //S2_U5C 

wire S2_U4C_A = S2_U7BB_nQ|S2_U1G_10;
wire S2_U4C_B = S2_U7BB_nQ|S2_U1G_9;
wire S2_U4C_C = S2_U7BB_nQ|S2_U1G_7;
wire S2_U5A_A = S2_U4C_B&S2_U4A_3;


wire SPR32_WR = 		S2_U4C_C&S2_U4A_6;
wire SPR32_CLK = 		S2_U4C_C&S2_U4C_A;
wire SPR32_BUF_WR = 	S2_U4C_C&S2_U4A_6;

reg [3:0] SPR_32K_HI;
always @(posedge S2_U5A_A) SPR_32K_HI <= (!SPR32_BUF_WR) ? S2_U4F_sum : S2_U2F_out;

assign SPR_32K_A[7:0] = (CPU_RAM_SYNC) ? SPR_VPOS_CNT : VPIX-1; //VPIX-1 hack
assign SPR_32K_A[11:8] = SPR_32K_HI;

ttl_74283 #(.WIDTH(4), .DELAY_RISE(0), .DELAY_FALL(0)) U9E(
	.a(SPR_32K_A[11:8]),
	.b(4'b0001),
	.c_in(1'b0),  
	.sum(S2_U4F_sum),
	.c_out()
);


wire [11:0] SPR_32K_A;
wire [3:0] S2_U4F_sum;
wire [3:0] S2_U2F_out;

m6148_7 S2_U2F (
	.clk(master_clk),
	.addr(SPR_32K_A[7:0]),
	.data(S2_U4F_sum),
	.nWE(SPR32_BUF_WR),
	.q(S2_U2F_out)
);


//SPRITE RAM - S2

dpram_dc #(.widthad_a(12)) SP_3H //sf
(
	.clock_a(master_clk),
	.address_a(SPR_32K_A),
	.data_a({4'b0000,SPR_VPIX}),
	.wren_a(!SPR32_WR),
	.q_a(SPR_VPIX_out),

	.clock_b(master_clk),
	.address_b(SPR_32K_A),
	.data_b(),
	.wren_b(1'b0),
	.q_b() 

);

dpram_dc #(.widthad_a(12)) SP_3J //sf
(
	.clock_a(master_clk),
	.address_a(SPR_32K_A),
	.data_a(SPR_IDX_D[7:0]),
	.wren_a(!SPR32_WR),
	.q_a(SPR_IDX_out),

	.clock_b(master_clk),
	.address_b(SPR_32K_A),
	.data_b(),
	.wren_b(1'b0),
	.q_b()

);

dpram_dc #(.widthad_a(12)) SP_3K //sf
(
	.clock_a(master_clk),
	.address_a(SPR_32K_A),
	.data_a(SPR_EXT_D),
	.wren_a(!SPR32_WR),
	.q_a(SPR_EXTRA_out),

	.clock_b(master_clk),
	.address_b(SPR_32K_A),
	.data_b(),
	.wren_b(1'b0),
	.q_b()

);

dpram_dc #(.widthad_a(12)) SP_3L //sf
(
	.clock_a(master_clk),
	.address_a(SPR_32K_A),
	.data_a(SPR_HPOS_D[7:0]),
	.wren_a(!SPR32_WR),
	.q_a(SPR_HPOS_out),

	.clock_b(master_clk),
	.address_b(SPR_32K_A),
	.data_b(),
	.wren_b(1'b0),
	.q_b()

);


wire [7:0] SP_09_out,SP_10_out,SP_11_out,SP_12_out; //Sprite ROM output bytes
reg [12:0] SPROM_ADDR ;

always @(*) SPROM_ADDR <= {2'b00,SPR_IDX_out,SPR_VPIX_out[3:0],SPR_8HPIX}; //performan or 8K BG ROMs 

eprom_9 SP_09
(
	.ADDR(SPROM_ADDR),
	.CLK(master_clk),//
	.DATA(SP_09_out),//
	.ADDR_DL(dn_addr),
	.CLK_DL(!master_clk),//
	.DATA_IN(dn_data),
	.CS_DL(ep9_cs_i),
	.WR(dn_wr)
);


eprom_10 SP_10
(
	.ADDR(SPROM_ADDR),//
	.CLK(master_clk),//
	.DATA(SP_10_out),//
	.ADDR_DL(dn_addr),
	.CLK_DL(!master_clk),//
	.DATA_IN(dn_data),
	.CS_DL(ep10_cs_i),
	.WR(dn_wr)
);

eprom_11 SP_11
(
	.ADDR(SPROM_ADDR),//
	.CLK(master_clk),//
	.DATA(SP_11_out),//
	.ADDR_DL(dn_addr),
	.CLK_DL(!master_clk),//
	.DATA_IN(dn_data),
	.CS_DL(ep11_cs_i),
	.WR(dn_wr)
);

wire SPR_PIX_A,SPR_PIX_B,SPR_PIX_C,SPR_PIX_D;

ls166 S2_U7G(
	.clk(pixel_clk),
	.pin(SP_09_out),
	.PE(SPR_ROM_LD),
	.QH(SPR_PIX_A)
);

ls166 S2_U7K(
	.clk(pixel_clk),
	.pin(SP_11_out),
	.PE(SPR_ROM_LD),
	.QH(SPR_PIX_B)
);

ls166 S2_U9G(
	.clk(pixel_clk),
	.pin(SP_10_out),
	.PE(SPR_ROM_LD),
	.QH(SPR_PIX_C)
);



reg [7:0] LINEBUF_A_D_in;
wire [7:0] LINEBUF_A_D_out;
reg [7:0] LINEBUF_B_D_in;
wire [7:0] LINEBUF_B_D_out;


//****************** SPRITE LINE BUFFER *************
reg  [8:0] LNBF_CNT;
wire [8:0] LNBF_CNTnext;
wire [8:0] LINEBUF_A_A;
wire [8:0] LINEBUF_B_A;
wire SPR_LINEA;
wire SPR_LINEB;

ls74 S2_U9D 
(
	.n_pre1(1'b1), 
	.n_clr1(1'b1), 
	.clk1(!CPU_RAM_SYNC), 
	.d1(SPR_LINEB), 
	.q1(SPR_LINEA), 
   .n_q1(SPR_LINEB) 
	
);

reg [4:0] SP_PX_SEL_D;
wire SPR_LINEA_PIX_A = SPR_PIX_A&SPR_LINEA;
wire SPR_LINEA_PIX_B = SPR_PIX_B&SPR_LINEA;
wire SPR_LINEA_PIX_C = SPR_PIX_C&SPR_LINEA;

wire SPR_LINEB_PIX_A = SPR_PIX_A&SPR_LINEB;
wire SPR_LINEB_PIX_B = SPR_PIX_B&SPR_LINEB;
wire SPR_LINEB_PIX_C = SPR_PIX_C&SPR_LINEB;

reg [7:0] SP_PX_D;

wire S2_U5A_D=SPR_LB_LD&S2_U4A_11;

always @(posedge pixel_clk) LNBF_CNT <= (!SPR_LB_LD) ? ({1'b0,SPR_HPOS_out}) : 
													 (!S2_U5A_D) ? LNBF_CNT-1 : LNBF_CNT; //S2_U1M,U2M & U3M

assign LINEBUF_A_A = (CPU_RAM_LBUF) ? 9'd0 :
							  (!SPR_LINEA) ? HPIX_LT : LNBF_CNT; //S2_U2T, U4T

assign LINEBUF_B_A = (CPU_RAM_LBUF) ? 9'd0 :
							  (!SPR_LINEB) ? HPIX_LT : LNBF_CNT; //S2_U2T, U4T
							  
//SPR_EXTRA_OUT[7]  = SPRITE PRIORITY
//IO_C_SPRITE_COLOR = USED WHEN IN 'POWER' MODE TO SHIFT COLOURS TO UPPER HALF OF PALLET
always @(posedge SPR_ROM_LD) SP_PX_SEL_D <= {SPR_EXTRA_out[7],IO_C_SPRITE_COLOUR,SPR_EXTRA_out[0],SPR_EXTRA_out[2:1]};
		
always @(*) begin
	LINEBUF_A_D_in<={SP_PX_SEL_D[4:0],SPR_LINEA_PIX_B,SPR_LINEA_PIX_C,SPR_LINEA_PIX_A}; //S2_U7P
	LINEBUF_B_D_in<={SP_PX_SEL_D[4:0],SPR_LINEB_PIX_B,SPR_LINEB_PIX_C,SPR_LINEB_PIX_A}; //S2_U8P
end
	
	
//assign SP_PRI=SPRITE_PRIORITY;
wire S2_U7M_B=!(SPR_LINEA_PIX_B|SPR_LINEA_PIX_C);
wire S2_U7M_A=!(SPR_LINEA_PIX_A);
wire S2_U8M_A=!(S2_U7M_A&S2_U7M_B);
wire S2_U1R_A=!(S2_U8M_A&SPR_LINEA&S2_U4A_10);
wire S2_U1T_D=S2_U1R_A&SPR_LINEA;
wire LINEBUF_A_nWE=pixel_clk|S2_U1T_D;

wire S2_U7M_D=!(SPR_LINEB_PIX_B|SPR_LINEB_PIX_C);
wire S2_U7M_C=!(SPR_LINEB_PIX_A);
wire S2_U8M_C=!(S2_U7M_C&S2_U7M_D);
wire S2_U1R_B=!(S2_U8M_C&SPR_LINEB&S2_U4A_10);
wire S2_U1T_C=S2_U1R_B&SPR_LINEB;
wire LINEBUF_B_nWE=pixel_clk|S2_U1T_C;


m6148x2 S2_U5T (
	.data(LINEBUF_A_D_in),
	.clk(master_clk),
	.addr(LINEBUF_A_A),
	.nWE(LINEBUF_A_nWE),
	.q(LINEBUF_A_D_out)
);

m6148x2 S2_U5M (
	.data(LINEBUF_B_D_in),
	.clk(master_clk),
	.addr(LINEBUF_B_A),
	.nWE(LINEBUF_B_nWE),
	.q(LINEBUF_B_D_out)
);

reg [7:0] LINEA_PIXEL;
reg [7:0] LINEB_PIXEL;

always @(posedge pixel_clk_lb) begin
	LINEA_PIXEL <= (LINEBUF_A_D_out[7:0]);  //put in enables here based off of 'LINEBUF_A_nWE'
	LINEB_PIXEL <= (LINEBUF_B_D_out[7:0]);
end

reg [7:0] pixel_blank;

//pixel blanker not enabled S2_u8C
always @(posedge pixel_clk) begin
	pixel_blank <= (!nCPU_RAM_SELECT) ? 8'd0 : ({pixel_blank[6:0],nCPU_RAM_SELECT});
end
wire clear_pixel=pixel_blank[7];

always @(posedge pixel_clk) SP_PX_D = (!SPR_LINEA) ?  LINEA_PIXEL : LINEB_PIXEL;
//assign pix_out2=(!clear_pixel) ? 8'b00000000 : SP_PX_D;
assign pixel_output=SP_PX_D;

endmodule
