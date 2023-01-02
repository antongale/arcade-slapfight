//------------------------------------------------------------------------------
// SPDX-License-Identifier: MPL-2.0
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, Open Gateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2022, Marcus Andrade <marcus@raetro.org>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.
//
//------------------------------------------------------------------------------
// Simple SRAM Controller
//------------------------------------------------------------------------------

`default_nettype none

module sram
    (
        // Clock and Reset
        input  wire        iCLK,      //! Input Clock
        input  wire        RST_N,     //! Reset Async
        // Operation to Perform
        input  wire        RW_ACT,    //! [0] - Read / [1] - Write
        // Address/Data Bus Interface
        input  wire [16:0] ADDR,      //! Address In
        input  wire [15:0] DI,        //! Data In
        output  reg [15:0] DO,        //! Data Out
        output  reg [7:0] DO_1,        //! Data Out		  
        output  reg [7:0] DO_2,        //! Data Out
        output  reg [7:0] DO_3,        //! Data Out
        output  reg [7:0] DO_4,        //! Data Out		  
        // SRAM Interface
        output  reg [16:0] SRAM_ADDR, //! Address Out
        inout   reg [15:0] SRAM_DQ,   //! Data In/Out
        output  reg        SRAM_OE_N, //! Output Enable
        output  reg        SRAM_WE_N, //! Write Enable
        output  reg        SRAM_UB_N, //! Upper Byte Mask
        output  reg        SRAM_LB_N  //! Lower Byte Mask
    );

    //! RAM FSM
    parameter OFF_F  = 2'b00,
              READ_F = 2'b01,
              WRITE_F= 2'b11;

	 reg [1:0] slice;
    reg [1:0] S_RAM_STATE = OFF_F;  //! Controller State
    reg       S_RW_ACT;             //! RW_ACT Register
	 reg [14:0] READ_SRAM_ADDR; 		//! Address at first clock

    always @(posedge iCLK) begin : RW_SRAM
        
		  if(RST_N == 1'b1)
        begin
            SRAM_LB_N <= 1'b1;              // Mask Low Byte
            SRAM_UB_N <= 1'b1;              // Mask High Byte
            SRAM_ADDR <= {17{1'bX}};        // Set Address As "don't Care" (must Preserve Low The Bus)
            SRAM_DQ   <= {16{1'bZ}};        // Set Data Bus As High Impedance (tristate)
				slice		 <= 0;
        end
        else
        begin

				SRAM_ADDR <= {17{1'b0}};        // "Don't Care"
            SRAM_DQ   <= {16{1'bZ}};        // High Impedance
            if(RW_ACT == 1'b0)              // READ
            begin
					READ_SRAM_ADDR<=ADDR[14:0];	//if(slice==0) 			
					S_RW_ACT  <= 1'b0;          // Tells The Fsm To Read
					SRAM_ADDR <= {slice,READ_SRAM_ADDR};          // Notify The Address
					SRAM_LB_N <= 1'b0;          // Unmask Low Byte
					SRAM_UB_N <= 1'b0;          // Unmask High Byte
					case (slice)
						2'b00:	DO_1       <= SRAM_DQ[7:0]; // Read The Data							
						2'b01:	DO_2       <= SRAM_DQ[7:0]; // Read The Data									
						2'b10:	DO_3       <= SRAM_DQ[7:0]; // Read The Data							
						2'b11:	DO_4       <= SRAM_DQ[7:0]; // Read The Data							
					endcase
					slice<=slice+1;
				end
            else if(RW_ACT == 1'b1)         // WRITE
            begin
                S_RW_ACT  <= 1'b1;          // Tells The Fsm To Write
                SRAM_ADDR <= ADDR;          // Notify The Address
                SRAM_LB_N <= 1'b0;          // Unmask Low Byte
                SRAM_UB_N <= 1'b0;          // Unmask High Byte
                SRAM_DQ   <= DI;            // Write The Data
            end
			end
		  
    end

    always @(S_RW_ACT) begin : SRAM_RW_ACTION
        SRAM_OE_N <= 1'b1; // Output Disabled
        SRAM_WE_N <= 1'b1; // Write Disabled
        if((S_RW_ACT == 1'b0))
        // READ
        begin
            S_RAM_STATE <= READ_F;
            SRAM_OE_N   <= 1'b0;
        end
        else
        // WRITE
        begin
            S_RAM_STATE <= WRITE_F;
            SRAM_WE_N   <= 1'b0;
        end
    end

endmodule
