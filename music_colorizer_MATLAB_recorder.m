%{
Proof of concept script that takes frequency response of live microphone audio, applies
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

% Set constants
Fs = 44100; % Sampling frequency

max_brightness = 0.8; % Max Neopixel brightness (scale of 0 to 1)
NUM_LED = 120;
LED_range = 1:NUM_LED;

% Bandpass filter cutoffs
FREQ_LOW = [129, 265];
FREQ_MID = [247, 523.4];
FREQ_HIGH = [523, 1047];

% For recording data
bits = 16;
channels = 1;
recorder = audiorecorder(Fs, bits, channels);

% Initialize Arduino Mega 2560 - adjust port number as necessary
a = arduino(COM, ARDUINO_TYPE, 'Libraries', 'Adafruit/NeoPixel');
neostrip = addon(a, 'Adafruit/NeoPixel', DIG_PIN, NUM_LED);

while true
    
    % Record snippet of microphone audio
    recordblocking(recorder, 0.2);
    x = getaudiodata(recorder);
    
    % Run FFT and take magnitude
    y = abs(fftshift(fft(x)));
    y = y(:,1);
    f = linspace(-Fs/2, Fs/2*(length(y)-1)/length(y), length(y))';
    y_full = [f y];
    
    % Initialize matrix to store LED data
    LED_set = zeros(NUM_LED, 3);
    
    % Idealized bandpass filters
    % Low (RED)
    l = (FREQ_LOW(1) < f) & (f < FREQ_LOW(2));
    y_low = y_full(l,:);
    y_low = imresize(y_low, [120, 2]);

    % Mid (GREEN)
    m = (FREQ_MID(1) < f) & (f < FREQ_MID(2));
    y_mid = y_full(m,:);
    y_mid = imresize(y_mid, [120, 2]);
    
    % High (BLUE)
    h = (FREQ_HIGH(1) < f) & (f < FREQ_HIGH(2));
    y_high = y_full(h,:);
    y_high = imresize(y_high, [120, 2]);
    
    LED_set(:, 1) = y_low(:,2);
    LED_set(:, 2) = y_mid(:,2);
    LED_set(:, 3) = y_high(:,2);
    
    % Normalization
    LED_set = abs(LED_set)./ max(max(LED_set)); 
    
    % Adjust for max_brightness
    LED_set = LED_set .* max_brightness;
    
    
    % COMMENT OUT BOTH FIGURES IF NOT PLOTTING
    figure(1);
    plot(y_low(:,1), y_low(:,2), "r", y_mid(:,1), y_mid(:,2), "g", y_high(:,1), y_high(:,2), "b");
    ylim([0 100]);
    xlabel("Frequency (Hz)");
    ylabel("Magnitude");
    title("Frequency Response of Live Audio");
    
    figure(2);
    plot(LED_range, LED_set(:,1), "r", LED_range, LED_set(:,2), "g", LED_range, LED_set(:,3), "b");
    ylim([0,0.8]);
    xlabel("LED Number");
    ylabel("LED Brightness");
    title("LED Color Assignment for Live Audio");
    
    % Write color to LEDs
    writeColor(neostrip, LED_range, LED_set);
    
end