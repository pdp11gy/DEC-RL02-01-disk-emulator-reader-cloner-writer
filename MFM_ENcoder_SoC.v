/*
      *****************************************************************************
      *  Copyright (C) by Reinhard Heuberger                                 *
      *                                                                           *
      *  All rights reserved.                                                     *
      *                                                                           *
      *  Redistribution and use in source and binary forms, with or without       *
      *  modification, are permitted provided that the following conditions       *
      *  are met:                                                                 *
      *                                                                           *
      *  1. Redistributions of source code must retain the above copyright        *
      *     notice, this list of conditions and the following disclaimer.         *
      *  2. Redistributions in binary form must reproduce the above copyright     *
      *     notice, this list of conditions and the following disclaimer in the   *
      *     documentation and/or other materials provided with the distribution.  *
      *  3. Neither the name of the author nor the names of its contributors may  *
      *     be used to endorse or promote products derived from this software     *
      *     without specific prior written permission.                            *
      *                                                                           *
      *****************************************************************************
*/

// Description:
// ============
// MFM ENcoder for RL02 disk simmulator with 16 bit parallel input
// and serial output. In this case, the serial transfer clock runs
// at 4.1 Mhz. The clock input is 65.6 MHz, obtained from a PLL to
// get the double frequency of 8.2 MHz, necessary for MFM phase 
// shifting. The 16bit transfer rate runs at 256.250 KHz. 
//
// TIME-shifting:
// ==============
//  |<------ shift <-------- shift <----------- shift <-----------|
//  |                          |  ********* LSB first *********   |
//  |<-16Bit SR history[15:0]->|<-16Bit shift/load,shifter[15:0]->|
//  |15  -> |9|8|7|6| <-     00|00 -----------------------------15|
//           | | | 
//           | | |
//           | | +-----> jetzt  (current)  history[7] -> serial_OUT
//           | +-------> alt    (old)      history[8]
//           +---------> uralt  (very old) history[9] 
// 
// PHASE shifting:
// ===============
// 8.2 MHz:  ..._|----____----____|----____----____.....
// 4.1 MHz:  ..._|--------________|--------________.....
// phase_0   ..._|________________|________________.....
// phase_1   ..._|----____________|----____________.....
// phase_2   ..._|____----________|____----________.....
// phase_3   ..._|________----____|________----____.....
// phase_4   ..._|____________----|____________----.....
//
//
//  by: Reinhard Heuberger , www.PDP11GY.com, JUL, 2011
// 
//  JUL-2018:  optimized for SoC/HPC .     
//   
module my_MFM_ENcoder_SoC(
       data_end,                   // data_end inside one sector
       sector,                     // Start if sector High.
       clk_65_6,                   // Input Clock  65.6 MHz
       data_16_in,                 // Data, 16 Bit parallel in
       //
       CLK_8_2,                    // Out-Clock 8.2MHz
       CLK_4_1,                    // Out-Clock 4.1MHZ
       CLK_16bit,                  // Out-clock, 16Bit 
       serial_OUT,                 // Data, Serial out
       load_L,                     // SR load pulse
       MFM);                       // MFM out
//      
input  data_end, sector, clk_65_6; 
input [15:0] data_16_in;
output CLK_8_2, CLK_4_1, CLK_16bit, serial_OUT, load_L, MFM;
//
reg [31:0]  divider;         // counter,= clock generator.
reg [15:0]  shifter;         // 16Bit parallel in SR
reg [15:0]  history;         // jetzt, alt, uralt SR.
reg [3:0]   load_SR;         // load-puls generator SR
reg [2:0] rclksync_16_4;     // like 2 D-FF register, 
reg clk_4_1_p;               // Synchronized 4.1MHz Clock
reg MFM;                     // MFM out
reg sync_p;
//wire jetzt;                // = current     (is no longer needed)
//wire alt;                  // = old         (is no longer needed)
//wire uralt;                // = very old    (is no longer needed)
reg ph0, ph1, ph3;
wire phase_0, phase_1, phase_3, shifter_out;
wire syncpuls;
//
initial
begin
   divider <= 0;
   shifter <= 0;
   history <= 0;
end
//
//
always @ (posedge clk_65_6)
begin
    sync_p <= sector;
end
assign syncpuls= sync_p & !sector;
//
//
//========================== Counter/Divider =================================
//============================================================================
// Note: Counting up is done at negative edges.
//       Counting down is done at positive edges.
always @ (posedge clk_65_6)
begin
	if (syncpuls) begin
		divider <= 0;
	end else if(sector & data_end) begin
		divider <= divider - 1;
	end else begin
		divider <= divider;	
	end	
end
assign CLK_8_2   =  divider[2];  // Output: 8.2Mhz
assign CLK_4_1   =  divider[3];  // Output: 4.1MHz
assign CLK_16bit =  divider[7];  // Output: 16Bit Clock//
//
//============== MFM phase and pulse-width generator =========================
//============================================================================
always @ (posedge clk_65_6)
begin
 /*
 // ( A special feature was implemented through the input 
 //   "select_pulse_width".In this case, the MFM pulse-width is 
 //    selectable, either at ~60us or at ~120us ) .. no longer needed!
 ph0 <= ( select_pulse_width ) ? 0 : 0;
 ph1 <= ( select_pulse_width ) ? (CLK_4_1 && CLK_8_2)   : (CLK_4_1);
 ph2 <= ( select_pulse_width ) ? (CLK_4_1 && !CLK_8_2)  : (CLK_4_1 ^ CLK_8_2);
 ph3 <= ( select_pulse_width ) ? (!CLK_4_1 && CLK_8_2)  : (!CLK_4_1);
 ph4 <= ( select_pulse_width ) ? (!CLK_4_1 && !CLK_8_2) : (!CLK_4_1 ^ !CLK_8_2);
 */
 ph0 <= 0;
 ph1 <= ( CLK_4_1 &&  CLK_8_2);
 //ph2 <= ( CLK_4_1 && !CLK_8_2);   // not used for MFM ENcoding
 ph3 <= (!CLK_4_1 &&  CLK_8_2);
 //ph4 <= (!CLK_4_1 && !CLK_8_2);   // not used for MFM ENcoding
end
assign phase_0 = ph0;
assign phase_1 = ph1;
//assign phase_2 = ph2;            // not used for MFM ENcoding
assign phase_3 = ph3;
//assign phase_4 = ph4;            // not used for MFM ENcoding
//
//
//===================== Generate a 20ns load pulse ===========================
//============================================================================
always @ (posedge clk_65_6)
begin
 load_SR = {load_SR[2:0], CLK_16bit};   // shift
end
assign load_L = ~((load_SR[2] ^ CLK_16bit) & CLK_16bit);
//
//
//========================= Mofify 4.1MHz clock  =============================
//============================================================================
always @ (posedge clk_65_6)
begin
 clk_4_1_p <= CLK_4_1;
end
//
//
//=============== Shiftregister with synchronous parallel load ===============
//============================================================================
//always @(posedge clk_4_1_p  or negedge load_L ) // Asynchron
//always @(posedge clk_4_1_p )                    // "Synchron"
/*
always @ (posedge clk_65_6)                       // Full Synchron !
begin
 if(!sector & !data_end )
  shifter <= 0;
 else
  if ( !clk_4_1_p & CLK_4_1 )         //    Full Synchron !
   begin  
     if (!load_L )                    //    IF load
       begin
        shifter <= data_16_in;        //    than (re)load
       end
       else if (load_L) begin
         shifter <= shifter >> 1;     //    else shift
       end 
     end
  end
 */
 always @ (posedge clk_65_6)                       // Full Synchron !
  begin
   if(!sector & !data_end )
     shifter = 0;
   else if ( !clk_4_1_p & CLK_4_1 )
     if (!load_L )
       shifter <= data_16_in;
     else if (load_L)
       shifter <= shifter >> 1;
  end
 //
assign  shifter_out  = shifter[0];
//
//
//========================= History shiftregister  ===========================
//============================================================================
always @ (posedge clk_65_6)
begin
 if ( !clk_4_1_p & CLK_4_1 )
 begin
  //
  history = {history[14:0], shifter_out};   // shift
  //
 end
end
assign  serial_OUT  = history[7];          // Serial out @ byte boundary       
//
//
//============================ MFM - ENcoder =================================
//============================================================================
// MFM spezifisch: Von 1 ->  einer(!) 0 mit folgender 1 :
// 1 auf 0  wird immer Phase_0, aber um die darauf folgende
// richtig zu encoden, muss eine Phase_3 gesendet werden. 
always @(posedge clk_65_6)
begin
  if (sector & data_end) begin
    case (history[9:7])
      //   |
      3'b000: MFM <= phase_1;         // 00->0 
      3'b001: MFM <= phase_3;         // 00->1 
      3'b010: MFM <= phase_0;         // 01->0 
      3'b011: MFM <= phase_3;         // 01->1 
      3'b100: MFM <= phase_1;         // 10->0 
      3'b101: MFM <= phase_3;         // 10->1 !
      3'b110: MFM <= phase_0;         // 11->0 
      3'b111: MFM <= phase_3;         // 11->1  
      //
    default: MFM <= 0;    
    endcase
  end
  else begin
    MFM <= 0;
  end
end
//
endmodule

