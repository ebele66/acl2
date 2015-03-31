/*

Centaur Hardware Verification Tutorial
Copyright (C) 2012-2013 Centaur Technology

Contact:
  Centaur Technology Formal Verification Group
  7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
  http://www.centtech.com/

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.  This program is distributed in the hope that it will be useful but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.  You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.

Original authors: Sol Swords <sswords@centtech.com>
                  Jared Davis <jared@centtech.com>

*/


// assumes minusb = - b.
// computes pp = b * (signed(abits[2:1]) + abits[0]).
module boothenc (pp, abits, b, minusb);
  output [17:0] pp;
  input [2:0] abits;
  input [15:0] b;
  input [16:0] minusb;

  wire [16:0] bsign = abits[2] ? minusb : { b[15], b };

   // is it shifted?
  wire shft = abits[0] ~^ abits[1];

   // is it zero? (all abits same)
  wire zro = shft & (abits[2] ~^ abits[1]);

   // result without the shift
  wire [16:0] res1 = zro ? 16'b0 : bsign;

   // final shift
  wire [17:0] pp = shft ? { res1, 1'b0 } : { res1[16], res1 };

endmodule

module boothflop #(width=1)
   (output [width-1:0] q,
    input  [width-1:0] d,
    input  clk);

  always @(posedge clk) q <= #1 d;

endmodule

module boothpipe (o, a, b, en, clk);

  output [31:0] o;
  reg [31:0] o;
  input [15:0] a, b;
  input en;
  input clk;

  reg [15:0] a_c1;
  reg [15:0] b_c1;
  reg [15:0] en_c1;

  reg en_latched;
   always @(clk or en)
     if (!clk)
       en_latched = en;

  wire lclk = clk & en_latched; 

   boothflop #(16) aflop (a_c1, en ? a : a_c1, lclk);
   boothflop #(16) bflop (b_c1, en ? b : b_c1, lclk);

  wire [16:0] minusb = 17'b1 + ~{ b_c1[15], b_c1 };

  wire [17:0] pp0;
  wire [17:0] pp1;
  wire [17:0] pp2;
  wire [17:0] pp3;
  wire [17:0] pp4;
  wire [17:0] pp5;
  wire [17:0] pp6;
  wire [17:0] pp7;

  boothenc booth0 (pp0, { a_c1[1:0], 1'b0 }, b_c1, minusb);
  boothenc booth1 (pp1, a_c1[3:1],   b_c1, minusb);
  boothenc booth2 (pp2, a_c1[5:3],   b_c1, minusb);
  boothenc booth3 (pp3, a_c1[7:5],   b_c1, minusb);
  boothenc booth4 (pp4, a_c1[9:7],   b_c1, minusb);
  boothenc booth5 (pp5, a_c1[11:9],  b_c1, minusb);
  boothenc booth6 (pp6, a_c1[13:11], b_c1, minusb);
  boothenc booth7 (pp7, a_c1[15:13], b_c1, minusb);

  // reg [17:0] pp0_c2;
  // reg [17:0] pp1_c2;
  // reg [17:0] pp2_c2;
  // reg [17:0] pp3_c2;
  // reg [17:0] pp4_c2;
  // reg [17:0] pp5_c2;
  // reg [17:0] pp6_c2;
  // reg [17:0] pp7_c2;

  //  always @(posedge lclk) begin
  //    pp0_c2 <= pp0;
  //    pp1_c2 <= pp1;
  //    pp2_c2 <= pp2;
  //    pp3_c2 <= pp3;
  //    pp4_c2 <= pp4;
  //    pp5_c2 <= pp5;
  //    pp6_c2 <= pp6;
  //    pp7_c2 <= pp7;
  //  end


  reg [35:0] pp01_c2;
  reg [35:0] pp23_c2;
  reg [35:0] pp45_c2;
  reg [35:0] pp67_c2;

   boothflop #(36) pp01flop (pp01_c2, {pp0, pp1}, lclk );
   boothflop #(36) pp23flop (pp23_c2, {pp2, pp3}, lclk );
   boothflop #(36) pp45flop (pp45_c2, {pp4, pp5}, lclk );
   boothflop #(36) pp67flop (pp67_c2, {pp6, pp7}, lclk );

  wire [35:0] pp01_c2b = ~pp01_c2;
  wire [35:0] pp23_c2b = ~pp23_c2;
  wire [35:0] pp45_c2b = ~pp45_c2;
  wire [35:0] pp67_c2b = ~pp67_c2;

  wire [17:0] pp0_c2 = ~pp01_c2b[35:18];
  wire [17:0] pp1_c2 = ~pp01_c2b[17:0];
  wire [17:0] pp2_c2 = ~pp23_c2b[35:18];
  wire [17:0] pp3_c2 = ~pp23_c2b[17:0];
  wire [17:0] pp4_c2 = ~pp45_c2b[35:18];
  wire [17:0] pp5_c2 = ~pp45_c2b[17:0];
  wire [17:0] pp6_c2 = ~pp67_c2b[35:18];
  wire [17:0] pp7_c2 = ~pp67_c2b[17:0];


  // We originally wrote this just as "assign o = ... + ... + ...", but
  // later, to experiment with alternative strategies, we decided to make
  // the summation order explicit, so that we can better match how the
  // implementation's term is built.
  wire [31:0] s0 = { {14{pp0_c2[17]}}, pp0_c2 };
  wire [31:0] s1 = s0 + { {12{pp1_c2[17]}}, pp1_c2, 2'b0 };
  wire [31:0] s2 = s1 + { {10{pp2_c2[17]}}, pp2_c2, 4'b0 };
  wire [31:0] s3 = s2 + { {8{pp3_c2[17]}}, pp3_c2, 6'b0 };
  wire [31:0] s4 = s3 + { {6{pp4_c2[17]}}, pp4_c2, 8'b0 };
  wire [31:0] s5 = s4 + { {4{pp5_c2[17]}}, pp5_c2, 10'b0 };
  wire [31:0] s6 = s5 + { {2{pp6_c2[17]}}, pp6_c2, 12'b0 };
  wire [31:0] s7 = s6 + { pp7_c2, 14'b0 };

  wire [31:0] o_c2 = s7;

   boothflop #(32) oflop (o, o_c2, lclk);

endmodule


