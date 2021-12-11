%{
Proof of concept script that takes frequency response of signal, applies
ideal bandpass filters, and converts peaks to LED light intensities.

Required Hardware:
Arduino Mega 2560
Neopixel light strip (120 pixels)

Required Packages:
MATLAB Support Package for Arduino Hardware
Neopixel Add-On Library for MATLAB
%}

clear all;


%INITIALIZE ARDUINO
COM = 'COM3';
ARDUINO_TYPE = 'Mega2560';
DIG_PIN = "D53";

NUM_LED = 120;

% Set constants
Fs = 44100; % Sampling frequency

max_brightness = 0.8; % Max Neopixel brightness (scale of 0 to 1)
LED_range = 1:NUM_LED;

% Control how many samples go into FFT per cycle - adjust number to account
% for lag in processing FFT and changing lights
FFT_samp = Fs * 0.33; 

% Bandpass filter cutoffs
FREQ_LOW = [129, 265];
FREQ_MID = [247, 523.4];
FREQ_HIGH = [523, 1047];

% Initialize Arduino Mega 2560 - adjust port number as necessary
% a = arduino(COM, ARDUINO_TYPE, 'Libraries', 'Adafruit/NeoPixel');
% neostrip = addon(a, 'Adafruit/NeoPixel', DIG_PIN, NUM_LED);

[x_full, Fs] = audioread("data/bensound-sunny.mp3");
% soundsc(x_full, Fs);

% Grab first audio snippet
start = 1 * FFT_samp - (FFT_samp - 1);
finish = 1 * FFT_samp + FFT_samp;
x = x_full(start:finish, 1);

% Run FFT and take magnitude
y = abs(fftshift(fft(x)));
y = y(:,1);
f = linspace(-Fs/2, Fs/2*(length(y)-1)/length(y), length(y))';
y_full = [f y];

% Plot frequency response
figure(1);
plot(f, y);
ylim([0 1150]);
xlabel("Frequency (Hz)");
ylabel("Magnitude");
title("Frequency Response of Sample Tune");

LED_set = zeros(NUM_LED, 3);

l = (FREQ_LOW(1) < f) & (f < FREQ_LOW(2));
y_low = y_full(l,:);
y_low = imresize(y_low, [120, 2]);
LED_set(:, 1) = y_low(:,2);

m = (FREQ_MID(1) < f) & (f < FREQ_MID(2));
y_mid = y_full(m,:);
y_mid = imresize(y_mid, [120, 2]);
LED_set(:, 2) = y_mid(:,2);

h = (FREQ_HIGH(1) < f) & (f < FREQ_HIGH(2));
y_high = y_full(h,:);
y_high = imresize(y_high, [120, 2]);
LED_set(:, 3) = y_high(:,2);

% Normalization
LED_set = abs(LED_set)./ max(max(LED_set)); 

LED_set = abs(LED_set) * max_brightness;

% Plot frequency response with colors
figure(2);
plot(y_low(:,1), y_low(:,2), "r", y_mid(:,1), y_mid(:,2), "g", y_high(:,1), y_high(:,2), "b");
ylim([0 1150]);
xlabel("Frequency (Hz)");
ylabel("Magnitude");
title("Frequency Response of Sample Tune");
legend("C3 Octave (Red)", "C4 Octave (Green)", "C5 Octave (Blue)");

% Plot LED color assignments
figure(3);
plot(LED_range, LED_set(:,1), "r", LED_range, LED_set(:,2), "g", LED_range, LED_set(:,3), "b");
ylim([0,0.8]);
xlabel("LED Number");
ylabel("LED Brightness");
title("LED Color Assignment for Sample Tune");
legend("C3 Octave (Red)", "C4 Octave (Green)", "C5 Octave (Blue)");
% writeColor(neostrip, LED_range, LED_set);