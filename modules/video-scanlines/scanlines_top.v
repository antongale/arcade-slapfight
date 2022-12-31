//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2022 OpenGateware authors and contributors
// Copyright (c) 2017 Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2015 Till Harbaum <till@harbaum.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
// Generic Video Scanlines
// H Soft    - 25% - b0001  d1
// H Medium  - 50% - b0010  d2
// H Hard    - 75% - b0011  d3

// V Soft    - 25% - b0100  d4
// V Medium  - 50% - b1000  d8
// V Hard    - 75% - b1100  d12

// HV Soft   - 25% - b0101  d5
// HV Medium - 50% - b1010  d10
// HV Hard   - 75% - b1111  d15
//------------------------------------------------------------------------------

module scanlines (
        input             iPCLK,      //! Pixel Clock

        input       [3:0] iSCANLINES, //! Scanlines

        input      [23:0] iRGB,       //! Core: RGB Video
        input             iVS,        //! Core: Hsync
        input             iHS,        //! Core: Vsync
        input             iDE,        //! Core: Data Enable

        output reg [23:0] oRGB,       //! Video Ouput: RGB Video
        output reg        oVS,        //! Video Ouput: Hsync
        output reg        oHS,        //! Video Ouput: Vsync
        output reg        oDE         //! Video Ouput: Data Enable
    );

    wire [23:0] h_video_rgb, v_video_rgb;
    wire        h_video_de,  v_video_de;
    wire        h_video_vs,  v_video_vs;
    wire        h_video_hs,  v_video_hs;
    wire  [1:0] hscanlines = iSCANLINES[1:0];
    wire  [1:0] vscanlines = iSCANLINES[3:2];

    scanlines_horizontal sh
                         (
                             .iPCLK      ( iPCLK      ),
                             .iSCANLINES ( hscanlines ),

                             .iRGB       ( iRGB ),
                             .iVS        ( iVS  ),
                             .iHS        ( iHS  ),
                             .iDE        ( iDE  ),

                             .oRGB       ( h_video_rgb ),
                             .oVS        ( h_video_vs  ),
                             .oHS        ( h_video_hs  ),
                             .oDE        ( h_video_de  )
                         );

    scanlines_vertical sv
                       (
                           .iPCLK      ( iPCLK      ),
                           .iSCANLINES ( vscanlines ),

                           .iRGB       ( h_video_rgb ),
                           .iVS        ( h_video_vs  ),
                           .iHS        ( h_video_hs  ),
                           .iDE        ( h_video_de  ),

                           .oRGB       ( v_video_rgb ),
                           .oVS        ( v_video_vs  ),
                           .oHS        ( v_video_hs  ),
                           .oDE        ( v_video_de  )
                       );

    always @(posedge iPCLK) begin
        oRGB <= v_video_rgb;
        oHS  <= v_video_hs;
        oVS  <= v_video_vs;
        oDE  <= v_video_de;
    end

endmodule
