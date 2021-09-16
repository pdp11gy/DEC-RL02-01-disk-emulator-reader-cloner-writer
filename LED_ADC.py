# PYTHON Program example for some different LED patterns with variable
# speed control, depending on the AD value at ADC2, GP28, Pin34.
# Pattern 3 is built up with Pattern 1 and 2 and shows the idle light
# Pattern from a PDP-11 where RSX11-M is running (kind of nostalgia). 
# I'm also a fan of the Raspberry products and programmed the typical
# RSX_idle-task light pattern - just for fun :-)
#
# Raspberry Pi PICO implementation 
from machine import Pin, ADC
analog_value = machine.ADC(28)
#
#
# byte-ordering like Big endian : -------- does not work with PICO  ---------
# pio = [19, 18, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2, 22, 20, 21, 25]
# led =  15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,  x,  y,  z,  o
# pin =  25, 24, 20, 19, 17, 16, 15, 14, 12, 11, 10,  9,  7,  6,  5,  4, 29, 26, 27,   
#
# byte-ordering like Little endian : LED's & PIN's
pio =   [ 2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 18, 19, 22, 20, 21, 25]
# led =   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,  x,  y,  z,  o
# pin =   4,  5,  6,  7,  9, 10, 11, 12, 14, 15, 16, 17, 19, 20, 24, 25, 29, 26, 27,   
#
def bitout16(pattern):
    temp = pattern
    for i in range(16):
        #print("{0:b}".format(temp))
        if (temp & 0x0001) == True :
            Pin(pio[i], Pin.OUT).high()
        else :
             Pin(pio[i], Pin.OUT).low()
        temp = temp >> 1
#
def delay(faktor):
    ad_wert = (analog_value.read_u16()-330)*faktor     
    for i in range(ad_wert*2):
        wert = ad_wert
#
def bytel(tempb):
    for i in range(8):
        if ((tempb & 0x0001) ==  0x0001) :
            Pin(pio[i], Pin.OUT).high()  
        else :
            Pin(pio[i], Pin.OUT).low() 
        tempb = tempb >> 1
#
def byteh(tempb):
    for i in range(8,16):
        if ((tempb & 0x0001) ==  0x0001) :
            Pin(pio[i], Pin.OUT).high()  
        else :
            Pin(pio[i], Pin.OUT).low() 
        tempb = tempb >> 1
#
#
#
def pattern1(loops):
    bl = 0b00001111                   # preset high byte
    bh = 0x00
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bl & 0x80) == 0x80) :    # green OK <<  if ((bl & 0x80) == 0x80)
            bl = bl << 1              # bl = bl << 1
            bl = bl | 0x01            # bl = bl | 0x01
        else:
            bl = bl << 1              # bl = bl << 1 
            bl = bl &~ 0x01           # bl = bl &~ 0x01
        bytel(bl)
        delay(2)
#
def pattern2(loops):
    bh = 0b11110000                   # preset low  byte
    bl = 0x00
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bh & 0x01) == 0x01) :    # red: OK >>  if ((bh & 0x01) == 0x01)
            bh = bh >> 1              # bh = bh >> 1
            bh = bh | 0x80            # bh = bh | 0x80 
        else:
            bh = bh >> 1              # bh = bh >> 1 
            bh = bh &~ 0x80           # bh = bh &~ 0x80
        byteh(bh)
        delay(2)
#
def pattern3(loops):
    bl = 0b00011111                   # preset high byte
    bh = 0b11110000
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bl & 0x80) == 0x80) :    # green OK <<  if ((bl & 0x80) == 0x80)
            bl = bl << 1              # bl = bl << 1
            bl = bl | 0x01            # bl = bl | 0x01
        else:
            bl = bl << 1              # bl = bl << 1 
            bl = bl &~ 0x01           # bl = bl &~ 0x01
        bytel(bl)
        #
        if ((bh & 0x01) == 0x01) :    # red: OK >>  if ((bh & 0x01) == 0x01)
            bh = bh >> 1              # bh = bh >> 1
            bh = bh | 0x80            # bh = bh | 0x80 
        else:
            bh = bh >> 1              # bh = bh >> 1 
            bh = bh &~ 0x80           # bh = bh &~ 0x80
        byteh(bh)
        delay(2)
#
#
def pattern4(loops):
    pattern = 0b1000000000000000
    Pin(pio[16], Pin.OUT).high()      # set X-LED
    Pin(pio[17], Pin.OUT).high()      # set Y-LED
    #print("pattern: {0:b}".format(pattern))
    for i in range(loops):
        for j in range(15):
            bitout16(pattern)
            pattern = pattern >>1
            delay(1)
        for j in range(15):
            bitout16(pattern)
            pattern = pattern <<1 
            delay(1)
#
def pattern5(loops):
    pattern = 0x0000
    Pin(pio[16], Pin.OUT).high()      # set X-LED
    Pin(pio[17], Pin.OUT).high()      # set Y-LED
    for i in range(loops):
        for j in range(15):
            bitout16(pattern)
            pattern = pattern >>1
            pattern = pattern | 0x8000
            delay(1)
        for j in range(15):
            bitout16(pattern)
            pattern = pattern <<1 
            delay(1)
#   
# Main
Pin(pio[19], Pin.OUT).low()       # clear onboard-LED
#
while True:
    Pin(pio[16], Pin.OUT).low()   # clear X-LED
    Pin(pio[17], Pin.OUT).low()   # clear Y-LED
    Pin(pio[18], Pin.OUT).low()   # clear Z-LED
    pattern1(30)
    pattern2(30)
    pattern3(60)
    pattern4(6)
    pattern5(6)
#
pattern = 0x0000
bitout16(pattern)
Pin(pio[16], Pin.OUT).low()       # clear X-LED
Pin(pio[17], Pin.OUT).low()       # clear Y-LED
bitout16(0x0000)                  # clear bit 0 to 15
#end
#
#
#
"""
# Raspberry Pi implementation 
import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
#
#Big endian
#pio =  [  2,  3,  4, 17, 27, 22,  5,  6, 13, 26, 16, 12, 25, 24, 23, 18 ]
#PIN =     3,  5,  7, 11, 13, 15, 29, 31, 33, 37, 36, 32, 22, 18, 16, 12 
#LED =    14, 15, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0 
#
#Little endian
pio =  [ 18, 23, 24, 25, 12, 16, 26, 13,  6,  5, 22, 27, 17,  4,  3,  2 ]
#PIN =   12, 16, 18, 22, 32, 36, 37, 33, 31, 29, 15, 13, 11,  7,  5,  3 
#LED =    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 
#
def defgpio():
    GPIO.setmode(GPIO.BCM)
    for i in range(16):
        GPIO.setup(pio[i], GPIO.OUT)
#
def bitout16(temp):
    for i in range(16):
        #print("{0:b}".format(temp).zfill(16))
        if ((temp & 0x0001) ==  0x0001) :
            GPIO.output(pio[i],GPIO.HIGH)  
        else :
            GPIO.output(pio[i],GPIO.LOW) 
        temp = temp >> 1    
#
def bytel(tempb):
    for i in range(8):
        if ((tempb & 0x0001) ==  0x0001) :
            GPIO.output(pio[i],GPIO.HIGH)  
        else :
            GPIO.output(pio[i],GPIO.LOW) 
        tempb = tempb >> 1
#
def byteh(tempb):
    for i in range(8,16):
        if ((tempb & 0x0001) ==  0x0001) :
            GPIO.output(pio[i],GPIO.HIGH)  
        else :
            GPIO.output(pio[i],GPIO.LOW) 
        tempb = tempb >> 1
#
#
def pattern1(loops):
    bl = 0b00001111                   # preset high byte
    bh = 0x00
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bl & 0x80) == 0x80) :    # green OK <<  if ((bl & 0x80) == 0x80)
            bl = bl << 1              # bl = bl << 1
            bl = bl | 0x01            # bl = bl | 0x01
        else:
            bl = bl << 1              # bl = bl << 1 
            bl = bl &~ 0x01           # bl = bl &~ 0x01
        bytel(bl)
        time.sleep(0.06)
#
def pattern2(loops):
    bh = 0b11110000                   # preset low  byte
    bl = 0x00
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bh & 0x01) == 0x01) :    # red: OK >>  if ((bh & 0x01) == 0x01)
            bh = bh >> 1              # bh = bh >> 1
            bh = bh | 0x80            # bh = bh | 0x80 
        else:
            bh = bh >> 1              # bh = bh >> 1 
            bh = bh &~ 0x80           # bh = bh &~ 0x80
        byteh(bh)
        time.sleep(0.06)
#
def pattern3(loops):
    bl = 0b00011111                   # preset high byte
    bh = 0b11110000
    bitout16(0x0000)                  # clear bit 0 to 15
    for i in range(loops):
        if ((bl & 0x80) == 0x80) :    # green OK <<  if ((bl & 0x80) == 0x80)
            bl = bl << 1              # bl = bl << 1
            bl = bl | 0x01            # bl = bl | 0x01
        else:
            bl = bl << 1              # bl = bl << 1 
            bl = bl &~ 0x01           # bl = bl &~ 0x01
        bytel(bl)
        #
        if ((bh & 0x01) == 0x01) :    # red: OK >>  if ((bh & 0x01) == 0x01)
            bh = bh >> 1              # bh = bh >> 1
            bh = bh | 0x80            # bh = bh | 0x80 
        else:
            bh = bh >> 1              # bh = bh >> 1 
            bh = bh &~ 0x80           # bh = bh &~ 0x80
        byteh(bh)
        time.sleep(0.04)
#
#
def pattern4(loops):
    pattern = 0b1000000000000000
    for i in range(loops):
        for j in range(15):
            bitout16(pattern)
            pattern = pattern >>1
            time.sleep(0.03)
        for j in range(15):
            bitout16(pattern)
            pattern = pattern <<1 
            time.sleep(0.03)       
#
#Main    
defgpio()                                              # Setup GPIOs
pattern = 0xFFFF                                       # set   16Bit pattern
bitout16(pattern)                                      # set   LEDs 0 to 15
pattern = 0x0000                                       # clear 16Bit pattern
bitout16(pattern)                                      # clear LEDs 0 to 15
while True:
    pattern1(30)
    pattern2(30)
    pattern3(60)
    pattern4(6)
#
pattern = 0x0000
bitout16(pattern)
#end
#
exit()
"""
