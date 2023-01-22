module foreground_layer (
	input master_clk,
	input pixel_clk,
	input [7:0] pcb,	
	input [7:0] VPIX,
	input [11:0] HPIX,
	input SCREEN_FLIP,
	input ATRRAM,
	input CHARAM,
	input Z80_WR,
	input Z80_RD,
	input CPU_RAM_SYNC,
	input [15:0] CPU_ADDR,
	input  [7:0] CPU_DIN,

	input [24:0] dn_addr,
	input [7:0] dn_data,
	input ep3_cs_i,
	input ep4_cs_i,
	input dn_wr,
	
	output [8:0] HPIX_LT_out,
	output [7:0] FG_HI_out,
	output [7:0] FG_LO_out,
	output [7:0] pixel_output,

	output FG_WAIT
);

reg [8:0] HPIX_LT;
reg [7:0] FG_PX_D;
wire [15:0] FG_RAMD;


always @(posedge pixel_clk) begin 
	HPIX_LT <= HPIX[8:0];  //this is a 'de-scrambled' version of HPIX_PT - U2D
end

assign HPIX_LT_out	= HPIX_LT;
	
	wire FG_CLK				= (SCREEN_FLIP ^ !HPIX_LT[2]); //U3C_A
	wire FG_SYNC			= !(FG_CLK&(SCREEN_FLIP ^ !HPIX_LT[0])&(SCREEN_FLIP ^  HPIX_LT[1])); //U4C_B
	wire colour_copy		= FG_SYNC|pixel_clk; //U4B_C

//	wire FG_RAM_nOE		= (FG_CLK) 		? 1'b0 : Z80_RD; //U4D (LS157) - output enable
	
	wire FG_SELECT			= (CPU_RAM_SYNC|FG_SYNC);
	wire FG_S0				= !( SCREEN_FLIP&FG_SELECT);
	wire FG_S1				= !(!SCREEN_FLIP&FG_SELECT);	
	
	//foreground RAM - dual port RAM for ease of use
	//graphics eproms use port A, CPU uses port B
	dpram_dc #(.widthad_a(11)) FG_U4G 
	(
		.clock_a(master_clk),
		.address_a({VPIX[7:3],HPIX_LT[8:3]}),
		.data_a(CPU_DIN),  							//Z80A_databus_out
		.wren_a(1'b0),
		.q_a(FG_RAMD[15:8]),

		.clock_b(master_clk),
		.address_b(CPU_ADDR[10:0]),
		.data_b(CPU_DIN),
		.wren_b(!ATRRAM & !Z80_WR),
		.q_b(FG_HI_out)	
	);

	dpram_dc #(.widthad_a(11)) FG_U4F 
	(
		.clock_a(master_clk),
		.address_a({VPIX[7:3],HPIX_LT[8:3]}),
		.data_a(CPU_DIN),
		.wren_a(1'b0),
		.q_a(FG_RAMD[7:0]),

		.clock_b(master_clk),
		.address_b(CPU_ADDR[10:0]),
		.data_b(CPU_DIN),
		.wren_b(!CHARAM & !Z80_WR),
		.q_b(FG_LO_out)	
	);


	//ROM for foreground graphics
	wire [7:0] U6G_FG_A77_03_out,U6F_FG_A77_04_out;

	eprom_3 U6G_FG_A77_03
	(
		.ADDR({FG_RAMD,VPIX[2:0]}),	//ROM Address
		.CLK(master_clk),					//clkm_36MHZ
		.DATA(U6G_FG_A77_03_out),		//Data output

		.ADDR_DL(dn_addr),				//Download ROM Address
		.CLK_DL(master_clk),				//
		.DATA_IN(dn_data),				//Download Data
		.CS_DL(ep3_cs_i),					//Select ROM for download
		.WR(dn_wr)							//Download to ROM 
	);

	eprom_4 U6G_FG_A77_04
	(
		.ADDR({FG_RAMD,VPIX[2:0]}),	//ROM Address
		.CLK(master_clk),					//clkm_36MHZ
		.DATA(U6F_FG_A77_04_out),		//Data output
                                    
		.ADDR_DL(dn_addr),            //Download ROM Address
		.CLK_DL(master_clk),				//
		.DATA_IN(dn_data),            //Download Data
		.CS_DL(ep4_cs_i),             //Select ROM for download
		.WR(dn_wr)							//Download to ROM 
	);

	wire U7F_QA,U7F_QH;
	wire U7G_QA,U7G_QH;

	//render each pixel to the screen by
	//shifting each pixel out of ROM
	ls299 U7F (
		.clk(pixel_clk),
		.pin(U6F_FG_A77_04_out),
		.S0(FG_S0),
		.S1(FG_S1),
		.QA(U7F_QA),
		.QH(U7F_QH)
	);

	ls299 U7G (
		.clk(pixel_clk),
		.pin(U6G_FG_A77_03_out),
		.S0(FG_S0),
		.S1(FG_S1),
		.QA(U7G_QA),
		.QH(U7G_QH)
	);

	always @(*) begin //posedge pixel_clk
		FG_PX_D[0] <= (SCREEN_FLIP) ?   U7G_QA : U7G_QH;
		FG_PX_D[1] <= (SCREEN_FLIP) ?   U7F_QA : U7F_QH;
	end

	always @(posedge colour_copy) FG_PX_D[7:2]<=FG_RAMD[15:10];

	assign pixel_output=FG_PX_D;

	
	//wait state
wire U2A_SF_B_Q,U1A_SF_B_nQ;
reg U1A_SF_B_Q;
reg U2A_SF_B_Qx;
wire	FG_CHIP_SEL=(ATRRAM&CHARAM);
//wire nFG_CHIP_SEL=!FG_CHIP_SEL;
wire nFG_CLK=!FG_CLK;

reg [7:0] count_wait;

//end

reg FG_CS_OLD;
always @(posedge nFG_CLK) begin
	count_wait= (!FG_CHIP_SEL&FG_CS_OLD) ? 8'b11000000 : count_wait<<1;
	U1A_SF_B_Q=count_wait[7];
	FG_CS_OLD=FG_CHIP_SEL;
end


assign FG_WAIT=FG_CHIP_SEL|U1A_SF_B_Q;	//FG_CHIP_SEL|

endmodule
