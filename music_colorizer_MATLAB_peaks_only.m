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

% Set constants
Fs = 44100; % Sampling frequency

max_brightness = 0.8; % Max Neopixel brightness (scale of 0 to 1)
num_LEDs = 120;
half_LED = floor(num_LEDs / 2);
LED_range = 1:num_LEDs;
spread = 10;

% Control how many samples go into FFT per cycle - adjust number to account
% for lag in processing FFT and changing lights
% ~0.33 for pulsing, 0.08 for single light
FFT_samp = Fs * 0.33; 

% Bandpass filter cutoffs
% FREQ_LOW = [15.9, 241];
% FREQ_MID = [263.5, 1771.9];
% FREQ_HIGH = [2635, 7957.7];

% FREQ_LOW = [129, 265];
% FREQ_MID = [247, 523.4];
% FREQ_HIGH = [523, 1047];

FREQ_LOW = [15.9, 600];
FREQ_MID = [601, 1771.9];
FREQ_HIGH = [2635, 7957.7];

% For recording data
bits = 16;
channels = 1;
recorder = audiorecorder(Fs, bits, channels);

% Initialize Arduino Mega 2560 - adjust port number as necessary
% a = arduino('COM8', 'Mega2560', 'Libraries', 'Adafruit/NeoPixel');
% neostrip = addon(a, 'Adafruit/NeoPixel', 'D53', 120);

% UNCOMMENT THIS CODE TO PLAY STORED MP3 FILE
% [x_full, Fs] = audioread("data/bensound-sunny.mp3");
% soundsc(x_full, Fs);

% CHANGE LOOP IF USING RECORDED DATA
% for i = 1:(floor(length(x_full) / FFT_samp)-1)
for i = 1:1000
    % UNCOMMENT THIS LINE TO PLAY STORED MP3 FILE
%     start = i * FFT_samp - (FFT_samp - 1);
%     finish = i * FFT_samp + FFT_samp;
%     x = x_full(start:finish, 1);
    
    % UNCOMMENT THIS CODE TO RECORD FROM MICROPHONE
    recordblocking(recorder, 0.05);
    x = getaudiodata(recorder);
    
    y = abs(fftshift(fft(x)));
    y = y(:,1);
    f = linspace(-Fs/2, Fs/2*(length(y)-1)/length(y), length(y))';
    y_full = [f y];

    l = (FREQ_LOW(1) < f) & (f < FREQ_LOW(2));
    y_low = y_full(l,:);

    m = (FREQ_MID(1) < f) & (f < FREQ_MID(2));
    y_mid = y_full(m,:);

    h = (FREQ_HIGH(1) < f) & (f < FREQ_HIGH(2));
    y_high = y_full(h,:);

    [Ml, I_low] = max(y_low(:,2));
    [Mm, I_mid] = max(y_mid(:,2));
    [Mh, I_high] = max(y_high(:,2));

    y_low(I_low);
    y_mid(I_mid);
    y_high(I_high);

    LED_low = ceil((y_low(I_low) - FREQ_LOW(1)) / (FREQ_LOW(2) - FREQ_LOW(1)) * 120);
    LED_mid = ceil((y_mid(I_mid) - FREQ_MID(1)) / (FREQ_MID(2) - FREQ_MID(1)) * 120);
    LED_high = ceil((y_high(I_high) - FREQ_HIGH(1)) / (FREQ_HIGH(2) - FREQ_HIGH(1)) * 120);

    LED_set = zeros(num_LEDs, 3);

    
    % V1: color peak only, non-symmetrical
%     for curr_LED = 1:num_LEDs
%         if abs(LED_low - curr_LED) < spread
%             LED_set(curr_LED, 1) = max_brightness - 0.1 *(LED_low - curr_LED);
%         end
%         if abs(LED_mid - curr_LED) < spread
%             LED_set(curr_LED, 2) = max_brightness - 0.1 * (LED_mid - curr_LED);
%         end
%         if abs(LED_high - curr_LED) < spread
%             LED_set(curr_LED, 3) = max_brightness - 0.1 *(LED_high - curr_LED);
%         end
%     end
    
    % V2: Color peak only, symmetrical
    
    LED_low = round(LED_low / 2);
    LED_mid = round(LED_mid / 2);
    LED_high = round(LED_high / 2);
    
    for curr_LED = 1:half_LED
        if abs(LED_low - curr_LED) < spread
            LED_set([half_LED - curr_LED + 1, half_LED + curr_LED], 1) = max_brightness / (1.5 ^ abs(LED_low - curr_LED));
        end 
        if abs(LED_mid - curr_LED) < spread
            LED_set([half_LED - curr_LED + 1, half_LED + curr_LED], 2) = max_brightness / (1.5 ^ abs(LED_mid - curr_LED));
        end
        if abs(LED_high - curr_LED) < spread
            LED_set([half_LED - curr_LED + 1, half_LED + curr_LED], 3) = max_brightness / (1.5 ^ abs(LED_high - curr_LED));
        end
    end
    
    writeColor(neostrip, LED_range, LED_set);
    
    for j = 1:2
        LED_set = LED_set ./ 2;
        writeColor(neostrip, LED_range, LED_set);
    end
  end

writeColor(neostrip, LED_range, zeros(num_LEDs, 3));
