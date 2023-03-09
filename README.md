# DEC-RL02-01-disk-emulator-reader-cloner-writer

# Final Version V2.8E based on Quartus V16.1 or higher

**Note:** It also works with the current Quartus version V22.1

SoC/HPS based RL01/RL02 disk emulator/reader/cloner/(writer), Altera Cyclone V FPGA with ARM Cortex-A9 (DE10-Nano) 
The operation of the RL02/RL01 emulator is best viewed with a VIDEO via YouTube, however in the first version from **2012**, based on the DE1-Board. https://www.youtube.com/watch?v=0i3ypBU39as
                                                                                                                                              
**All sources with environment setup  are located in the zip-folder DE10_SoC_RL_emulator_V2_8.zip**                                                                                                                                               

With the new firmware version V2.8E it is also possible to clone a disk without a PDP-11 system.                                                        
The software runs completely on the DE10-Nano board and generates .dsk files for direct further                                                       
use with SIMH. The most important is the verilog module read_one_track.v, which is uploaded again.                                                                                       

                                                                                                                    
                                                                                                                    

For info: Another project, MFM disk emulator, also based on the DE10-Nano board is now also available:                   
https://github.com/pdp11gy/SoC-HPS-based-MFM-disk-emulator  Furthermore, it is planned to bring both           
interfaces together like in the overview.pdf dokument. This action has been suspended for the time being.                                
Maybe someone has the motivation and time to complete the project? A ready-made proposal with pictures can                                    
be found in the file zusammen.pdf. It's written in German, but with google translator it shouldn't be a problem.                                                   
A full, ready for use configured SD-card-image for the DE10-Nano Board is also available.                                                                                                                                 
More details are published on my homepage, www.pdp11gy.com
