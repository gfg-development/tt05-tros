![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# TROS
This project for the tapeout via [Tiny Tapeout](https://tinytapeout.com/) aims at using
ring oscillators to measure temperatures of the chip. 

## Introduction
This design implements three different ring oscillators. The first one is a basic NAND 
based oscillator. The second one adds additional NAND gates to the outputs of the stages
of the oscillator to increase the capacitve loading. The last one uses the tri-state
inverts with a sub-threshold tri-state enable. 
Each of the oscillators should have a different temperature and voltage dependency. 
Therefore it should be possible to measure the temperature (and supply voltage) with the
help of a device specific calibration. 

For measuring the frequencies each oscillator is driving a counter. This counters are
latched with the latch counter input. With the input transfer counter the currently 
selected counter (counter select bits) is transfered via the serial data stream. The 
transfer is driven by the clock of the design. As encoding a manchester encoding is used. 

Furthermore, a divided version of the clock of each oscillator is outputted. The divisior
can be configured with the frequency selection bits. 