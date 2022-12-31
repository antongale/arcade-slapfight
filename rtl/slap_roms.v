module prom6301_L8
(
	input [7:0] addr,
	input clk,n_cs, 
	output reg [3:0] q
);

	reg [3:0] rom[255:0];

	initial
	begin
		$readmemh("roms/promL8.txt", rom);
	end

	always @ (posedge clk)
	begin
		if (!n_cs) begin
			q <= rom[addr];
		end
	end

endmodule

module prom6331_E1
(
	input [4:0] addr,
	input clk,n_cs, 
	output reg [7:0] q
);

	reg [7:0] rom[31:0];

	initial
	begin
		$readmemh("roms/promE1.txt", rom);
	end

	always @ (posedge clk)
	begin
		if (!n_cs) begin
			q <= rom[addr];
		end
	end

endmodule


module prom6301_H10
(
	input [7:0] addr,
	input clk,n_cs, 
	output reg [3:0] q
);

	reg [3:0] rom[255:0];

	initial
	begin
		$readmemh("roms/promH10_4BIT.txt", rom);
	end

	always @ (posedge clk)
	begin
		if (!n_cs) begin
			q <= rom[addr];
		end
	end

endmodule


module prom6301_3L
(
	input [7:0] addr,
	input clk,n_cs, 
	output reg [3:0] q
);

	reg [3:0] rom[255:0];

	initial
	begin
		$readmemh("roms/prom3L.txt", rom);
	end

	always @ (posedge clk)
	begin
		if (!n_cs) begin
			q <= rom[addr];
		end
	end

endmodule


module prom6301_4KJ
(
	input [7:0] addr,
	input clk,n_cs, 
	output reg [3:0] q
);

	reg [3:0] rom[255:0];

	initial
	begin
		$readmemh("roms/prom4KJ.txt", rom);
	end

	always @ (posedge clk)
	begin
		if (!n_cs) begin
			q <= rom[addr];
		end
	end

endmodule
