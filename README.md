# Music Colorizer
## By Megan Ku and Isabel Serrato
Final project for Introduction to Analog and Digital Communications.

## Demo
A link to a video demo of the colorizer can be found [here](https://youtu.be/6El5UoysoWc).

## Requirements
### Software:
- MATLAB (Written in R2021a)
- MATLAB Packages: MATLAB Support Package for Arduino Hardware and NeoPixel Add-On Library for Arduino

Make sure to follow the setup instructions for both libraries correctly. Information on installation can be found within the Add-On Manager in MATLAB.

### Hardware
- Arduino Mega 2560, power supply
- Programmable RGB LED strip, 120 px
- Jumper cables

## Preparing the LEDs

Connect the black wire on the LED strip to GND on the Arduino, the red wire to 5V on the Arduino, and the green wire to digital pin 53.

## Running the Visualizer

There are two scripts that take audio and create visuals. `music_colorizer_MATLAB_recorder.m` takes live audio from the computer's microphone and creates light sequences from that audio. This program runs indefinitely and needs to be killed with `CTRL + C` in the MATLAB Command Window. `music_colorizer_MATLAB_preloaded.m` takes a sample of preloaded music (in the `data` folder) and runs the visualizer on that music. This terminates after the music is complete.

Choose which visualizer you want, then make sure to **change the port number in the script** so that your Arduino connects properly. You do not need to clear the workspace between runs as the script has `clear` calls at the start of every script.

You can also choose to keep or comment out the real-time frequency response plots within the script. Note that in `music_colorizer_MATLAB_preloaded.m`, you will need to adjust `FFT_samp` to minimize delay of audio and visuals.
