%{
Proof of concept script that takes frequency response of music file, applies
ideal bandpass filters, and converts peaks to LED light intensities.

Required Hardware:
Arduino Mega 2560
Neopixel light strip (120 pixels)

Required Packages:
MATLAB Support Package for Arduino Hardware
Neopixel Add-On Library for MATLAB
%}

% Set constants
Fs = 44100; % Sampling frequency

max_brightness = 0.8; % Max Neopixel brightness (scale of 0 to 1)
num_LEDs = 120;
LED_range = 1:num_LEDs;

% Control how many samples go into FFT per cycle - adjust number to account
% for lag in processing FFT and changing lights
FFT_samp = Fs * 0.08; 

% Bandpass filter cutoffs

FREQ_LOW = [129, 265];
FREQ_MID = [247, 523.4];
FREQ_HIGH = [523, 1047];

% Initialize Arduino Mega 2560 - adjust port number as necessary
a = arduino('COM8', 'Mega2560', 'Libraries', 'Adafruit/NeoPixel');
neostrip = addon(a, 'Adafruit/NeoPixel', 'D53', 120);

% Play stored MP3 file
[x_full, Fs] = audioread("data/bensound-sunny.mp3");
soundsc(x_full, Fs);

for i = 1:(floor(length(x_full) / FFT_samp)-1)

    start = i * FFT_samp - (FFT_samp - 1);
    finish = i * FFT_samp + FFT_samp;
    x = x_full(start:finish, 1);
    
    y = abs(fftshift(fft(x)));
    y = y(:,1);
    f = linspace(-Fs/2, Fs/2*(length(y)-1)/length(y), length(y))';
    y_full = [f y];
    
    LED_set = zeros(num_LEDs, 3);

    l = (FREQ_LOW(1) < f) & (f < FREQ_LOW(2));
    y_low = y_full(l,:);
    y_low = imresize(y_low, [120, 2]);
    
    m = (FREQ_MID(1) < f) & (f < FREQ_MID(2));
    y_mid = y_full(m,:);
    y_mid = imresize(y_mid, [120, 2]);
    
    h = (FREQ_HIGH(1) < f) & (f < FREQ_HIGH(2));
    y_high = y_full(h,:);
    y_high = imresize(y_high, [120, 2]);
    
    LED_set(:, 1) = y_low(:,2) / max(y_low(:, 2));
    LED_set(:, 2) = y_mid(:,2) / max(y_mid(:, 2));
    LED_set(:, 3) = y_high(:,2) / max(y_high(:, 2));
    
    LED_set(:, 1) = y_low(:,2);
    LED_set(:, 2) = y_mid(:,2);
    LED_set(:, 3) = y_high(:,2);
    
    LED_set = abs(LED_set)./ max(max(LED_set));
    
    LED_set = LED_set .* max_brightness;
    
    figure(2);
    plot(y_low(:,1), y_low(:,2), "r", y_mid(:,1), y_mid(:,2), "g", y_high(:,1), y_high(:,2), "b");
    figure(3);
    plot(LED_range, LED_set(:,1), "r", LED_range, LED_set(:,2), "g", LED_range, LED_set(:,3), "b");

    writeColor(neostrip, LED_range, LED_set);
   
end

writeColor(neostrip, LED_range, zeros(num_LEDs, 3));
