/*
      *****************************************************************************
      *  Copyright (C) by Reinhard Heuberger , www.pdp11gy.com                    *
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
      
                                     Decoding
        This MFM decoder measures the MFM distance time using the 65.6MHz clock. 
        Two counters (A and B) alternately count the 65.6 MHZ pulses between the MFM 
        signals. The MFM tranfer rate is 4.1 MHz, that is 0,2439 uS.
        This results in 65.6 Mhz measurement, = 0.01524 uS:       
        ( MFM decoder. Die Abstände der MFM Signale werden mit einer 65.6 MHz  Clock
        gemessen. Zwei counter ( A und B ) zählen abwechselnd die 65.6 MHZ impulse 
        zwischen den MFM Signalen. Die MFM tranfer Rate ist 4.1 MHz, also 0.2439 uS.        
        Somit ergibt sich bei 65.6Mhz Messung, = 0.01524 uS :)
            short       : 0,1234 us  = 16 
            long        : 0,1626 us  = 24
            verylong    : 0,2439 us  = 32 

                                   MFM-Decoding
                                   ************
                      short                   long               verylong
    tooshort<--------|-----------------------|-------------------|--------->toolong
                     |                       |                   |
                  0.1234                  0.1626              0.2439
                     16                      24                  32
    <9-----|<------------------>|<------------------>|<------------------>|------>                          
                12 <-> 20               20 <-> 28           28 <-> 36
             (=>9  & <=20)            (>20 & <=28)       (>28  & <=36)       >36
            
    This decoder provides "on the fly" realtime MFM-decoding with Clock recovery, 
    serial output and 8 bit parallel output.  
    An alternativ module was clone_MFM_DEcoder.v 	  
    
                                    Sequencing
									         **********
    This module generates the sector addresses and the addresses within one sector for 
    one track. A track consists of 40 sectors (0-39) and a each sector consists of 140
    16-bit words including servo / header / CRC information. In the FPGA, a sector 
    with 144 16-bit words is implemented for the purpose of 16-bit boundary.                                    
    
                                  Version 2.8 / JANUAR 2021
                    part of the RL01/RL02 disk reader/emulator Version V2.7
    
    
*/
module      read_one_track(
            Enable,                             // Enable
            Clk_65_6,                           // System Clock 65.6 MHz
            MFM_IN,                             // MFM signal 
            Sector,                             // Start decoding (@ sector)
            //
            Parallel_out,                       // parallel output
            address_out,                        // 13 bit adress out
            Clock_16bit,                        // Clock 16 Bit
            Serial_out,                         // Serial   Output
            MFM_Sy1,                            // MFM to be scanned
            start_MFM);
            //          
input  Enable, Clk_65_6, MFM_IN, Sector;
output [15:0]  Parallel_out;
output [12:0]  address_out;
output Clock_16bit, Serial_out, MFM_Sy1; 
output start_MFM;
//
reg [31:0] count_A;                             // Counter A
reg [31:0] count_B;                             // Counter B
reg [7:0]  counterwert;                         // latched counter value
reg [23:0] shifter0;                            // shifter, serial->parallel
reg [15:0] latch_word;                          // Parallel out
reg [23:0] MFM_shift;                           // shift and sync MFM to 80MHz clk.
reg [23:0] Sector_shift;                        // shift and sync Sector puls
reg [31:0] current_address;                     // augenblickliche Addresse^
reg [31:0] grenze_unten;                        // Start Addresse ( DP RAM )
reg [31:0] grenze_oben;                         //  bis gültige Obergrenze.
reg [31:0] sector_counter;                      // Sector counter
reg [31:0] word_clock;
reg [12:0] address_out;                         // 13-Bit output Adress to DPR
reg FF, doshift, long, verylong, firstMFM;
reg countAorB, FlipFlop, CLK_16bit_P,Sector_p;
wire load_word_n, Sector_puls, Sector_puls1, Sector_puls2;
wire MFM_pulse_pos2, MFM_pulse_pos3, MFM_pulse_neg1, MFM_pulse_neg2;
//
//
initial
begin
    firstMFM         <= 0;
    shifter0         <= 0;
    FF               <= 0;   
    word_clock       <= 0;
    FlipFlop         <= 0;
    current_address  <= 0;
    grenze_unten     <= 0;
    grenze_oben      <= 140;
end 
//
//
//--------------------------- Find first MFM pulse --------------------------
//---------------------------------------------------------------------------
always @ (posedge Clk_65_6)
begin
    if(Enable & Sector) begin
        if(!firstMFM) begin
           if(MFM_IN) begin
                firstMFM <= 1;                            // indicate: first MFM puls
            end else begin
                firstMFM <= 0;
            end
        end else begin
             firstMFM <= firstMFM;
          end
    end else begin
        firstMFM <= 0;
   end      
end 
assign start_MFM = firstMFM;               
//          
//
//
//========= shift + Synchronize MFM signal, = MFM_IN  to FPGA clock ==========
//============================================================================
always @ (posedge Clk_65_6)
begin
    //
    MFM_shift <= { MFM_shift[22:0] , ~MFM_IN };               // synchron shift
    //
end
assign MFM_Sy1 =          MFM_shift[23];                       // Synced MFM signal
assign MFM_pulse_pos2 = (!MFM_shift[22] &  MFM_shift[21]);     // 80Mhz MFM pulse #2
assign MFM_pulse_pos3 = (!MFM_shift[23] &  MFM_shift[22]);     // 80Mhz MFM pulse #3
assign MFM_pulse_neg1 = ( MFM_shift[22] & !MFM_shift[21]);     // 80Mhz MFM pulse #4
assign MFM_pulse_neg2 = ( MFM_shift[23] & !MFM_shift[22]);     // 80Mhz MFM pulse #4
//
//
//
//==================== Synchronize Sector pulse signal =======================
//============================================================================
always @ (posedge Clk_65_6)
begin
    Sector_shift <= { Sector_shift[22:0] , Sector };                // shift
end
assign Sector_puls1 = (!Sector_shift[20] & Sector_shift[19]);       // 80Mhz Sector pulse1
assign Sector_puls2 = (!Sector_shift[21] & Sector_shift[20]);       // 80Mhz Sector pulse2
//
//
//
//
//                                +----------------------+
//                                |------ "decode" ------|
//                                +----------------------+ 
//
always @ (posedge Clk_65_6)
begin
    if(Enable & !Sector_puls1 & !Sector_puls2) begin
        if(!countAorB) begin
            count_A <= count_A + 1;                     // increment counter A
            count_B <= 0;
        end else begin
            count_B <= count_B + 1;                     // incremant counter B
            count_A <= 0;
          end
        //
        //
        if(MFM_pulse_pos2) begin
        //----------------------------------------------------------------------
        //              Counter-Management @  MFM_pulse_pos2
        //----------------------------------------------------------------------
            countAorB <= ~countAorB;                    // !! Switch counter !!
            if(!countAorB) begin
                counterwert <= count_A[7:0]; 
            end else begin
                counterwert <= count_B[7:0];
            end
        end else if ( MFM_pulse_pos3 ) begin            // pos edge
        //
        //----------------------------------------------------------------------
        //          calculate MFM gaps & decode to serial & parallel out 
        //----------------------------------------------------------------------
            if (counterwert  <= 9) begin                                // TOO short !! (10)
                long          <= 0;                                     // !long     cycle 
                verylong      <= 0;                                     // !verylong cycle
                doshift       <= 0;                                     // 1 = Enable shifting  
                FlipFlop      <= FlipFlop;
                FF            <= FF;                                    // compare purpose@logic analyser
            end else
                if (counterwert > 9 &  counterwert <= 20) begin         // short ( >10  & <=20)
                    long       <= 0;                                    // !long     cycle 
                    verylong   <= 0;                                    // !verylong cycle
                    word_clock <= word_clock + 1;                       // increment byte-counter
                    doshift    <= 1;
                    FlipFlop   <= FlipFlop;
                    FF         <= FF;                                   // compare purpose@logic analyser
            end else
                if (counterwert > 20 &  counterwert <= 28) begin        // long ( >20 & <=28 )
                    //
                    if(FlipFlop) begin                                  // Long cycle from 1 -> 0 
                        long   <= 1;                                    // has to be handled different
                    end                                                 // comparing to 0 ->1 long cycle
                    //
                    verylong   <= 0;
                    word_clock <= word_clock + 1;                       // increment byte-counter
                    doshift    <= 1;                                    // 1 = Enable shifting
                    FlipFlop   <= ~FlipFlop;
                    FF         <= ~FF;                                  // compare purpose@logic analyser
            end else        
                if (counterwert > 28 &  counterwert <= 35) begin        // very long (>28  & <=36)
                    long       <= 0;
                    verylong   <= 1;

                    word_clock <= word_clock + 1;                       // increment byte-counter
                    doshift    <= 1;                                    // 1 = Enable shifting
                    FlipFlop   <= ~FlipFlop;                            // FlipFlop   <= ~FlipFlop;
                    FF         <= ~FF;                                  // compare purpose@logic analyser
            end
            //
            if ( doshift ) begin
                shifter0 <= { shifter0[22:0] , FlipFlop};
            end
            //
        end else if ( MFM_pulse_neg1 ) begin                            // neg edge
            if ( verylong | long ) begin                                // VeryLong or 1->0 long cycle ?
                if (long ) begin
                    FlipFlop  <= FlipFlop;                              // long:     FlipFlop <= FlipFlop;  
                    FF        <= FF;                                    // Vergleich//  
                    long      <= 0;
                end else begin
                    FlipFlop  <= ~FlipFlop;                             // Verylong: FlipFlop <= ~FlipFlop; 
                    FF        <= ~FF;                                   // compare purpose@logic analyser
                end
                shifter0   <= { shifter0[22:0] , FlipFlop};
                word_clock <= word_clock + 1;                           // increment byte-counter
                verylong   <= 0;                                        // Clear verylong Flag
            end else begin 
                FlipFlop   <= FlipFlop;
                FF         <= FF;                           
            end
            //
            //
        end
    end else begin
        long        <= 0;
        verylong    <= 0;
        FF          <= 0;
        FlipFlop    <= 0;
        word_clock  <= 0;
    end
end       
assign Serial_out   = FlipFlop;
assign Clock_16bit  = ~word_clock[3];
//
//
//=============== Generate load pulse for parallel out =======================
//============================================================================
always @ (posedge Clk_65_6)
begin
  CLK_16bit_P <= Clock_16bit;
end
assign load_word_n = CLK_16bit_P &  !Clock_16bit;              // negativ edge
//
//=========================== latch 16 bit output ============================
//============================================================================
always @ (posedge Clk_65_6)
begin
  if (load_word_n) begin                          // little endian ordering
    latch_word[15] <= shifter0[0]; 
    latch_word[14] <= shifter0[1];
    latch_word[13] <= shifter0[2];
    latch_word[12] <= shifter0[3];
    latch_word[11] <= shifter0[4];
    latch_word[10] <= shifter0[5];
    latch_word[9]  <= shifter0[6];
    latch_word[8]  <= shifter0[7];
    //
    latch_word[7]  <= shifter0[8];  
    latch_word[6]  <= shifter0[9];
    latch_word[5]  <= shifter0[10];
    latch_word[4]  <= shifter0[11];
    latch_word[3]  <= shifter0[12];
    latch_word[2]  <= shifter0[13];
    latch_word[1]  <= shifter0[14];
    latch_word[0]  <= shifter0[15];
  end
end
assign Parallel_out = latch_word;                          // 8bit, = byte  out
//
//
//
//
//
//                                +----------------------+
//                                |----- "sequence" -----|
//                                +----------------------+ 
//
always @ (posedge Clk_65_6)
begin
    Sector_p <= Sector;
end
assign Sector_puls = Sector_p & !Sector;                                  
//
//================= Sector Idex-Adressen bilden, 0-39 ========================
//========== 16Bit Adressen innerhalb eines Sector bilden, 0-139 =============
//============================================================================
always @ (posedge Clk_65_6)
begin
    //if ( ~synced_SECTOR_clk[1] & synced_SECTOR_clk[2] )    // @ negedge SEC clk
    if (Sector_puls) begin
        if(Enable) begin
            sector_counter = sector_counter +1;              // Increment
            if ( sector_counter == 40 ) begin                //  If Limit ( 0-39 )    
                sector_counter  <= 0;                        //      clear counter    
                current_address <= 0;                        //      and address
                grenze_unten    <= 0;
                grenze_oben <= 140;                          //  set upper limit 
            end else if( sector_counter < 40 ) begin
                grenze_unten <= grenze_unten + 144;          //  DP-RAM-Sector = +144
                current_address <= grenze_unten;             //  Neue untere Grenze
                grenze_oben <= grenze_unten + 140;           //  set upper limit  
            end    
        end   
    end
    //
    // Synchron zur 50Mhz clock werden nun mit der negativen Flanke der
    // 16Bit clock die Adressen innerhalb eines Sectors gebildet.
    //      
    //if ( ~synced_WORD_clk[1] & synced_WORD_clk[2] )         // @ negedge ENC clk
    if ( load_word_n ) begin                                  // *start*
        if(Enable) begin
            if ( current_address == grenze_oben+2) begin
                 current_address <= current_address;          // nix
            end else begin
                current_address <= current_address + 1;       // words/sector-counter
                address_out <= current_address[12:0];         // send Adress              
            end
        end else begin
            current_address <= 0;
            grenze_unten    <= 0;
            grenze_oben     <= 140;
        end
    end    
end
//
endmodule
