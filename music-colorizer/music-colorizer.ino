// A script that sets specific LED colors based on audio input.
// Designed for RGB LED strip.
// Authors: Megan Ku and Isabel Serrato

#include <Adafruit_NeoPixel.h>
#include <arduinoFFT.h>

arduinoFFT FFT_low = arduinoFFT(); // create FFT object
arduinoFFT FFT_mid = arduinoFFT();
arduinoFFT FFT_high = arduinoFFT();
/*
FFT constants
*/
const uint16_t samples = 128; // This value MUST ALWAYS be a power of 2 for the FFT function
const double samplingFrequency = 9000; // Stay below 10kHz
unsigned int sampling_period_us;
unsigned long microseconds;

/*
These are the input and output vectors
Input vectors receive computed results from FFT
*/
double vReal0[samples]; // low band
double vImag0[samples];
double vReal1[samples]; // mid band
double vImag1[samples];
double vReal2[samples]; // high band
double vImag2[samples];

#define SCL_INDEX 0x00
#define SCL_TIME 0x01
#define SCL_FREQUENCY 0x02
#define SCL_PLOT 0x03

// Digital pin for LED strip
#define LED_PIN 53

// Number of LED in strip
#define LED_COUNT 120

// Define microphone inputs
#define LowBand A5
#define MidBand A10
#define UpperBand A0

#define MAX_BRIGHT 255

// Declare NeoPixel strip object
Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
// Argument 1 = Number of pixels in NeoPixel strip
// Argument 2 = Arduino pin number (most are valid)
// Argument 3 = Pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)


// Object for storing FFT peak frequencies
class peak_FFT {
  public:
    int x_low;
    int x_mid;
    int x_high;
};

void setup() {
  sampling_period_us = round(1000000*(1.0/samplingFrequency));
  strip.begin();           // INITIALIZE NeoPixel strip object (REQUIRED)
  strip.show();            // Turn OFF all pixels ASAP
  strip.setBrightness(50); // Set BRIGHTNESS to about 1/5 (max = 255)
  Serial.begin(115200); // initialize Serial Monitor
}


// Main loop
void loop() {
  /* Collect data */
  microseconds = micros();
  for (uint16_t i = 0; i < samples; i++)
  {
    vReal0[i] = analogRead(LowBand);
    vReal1[i] = analogRead(MidBand);
    vReal2[i] = analogRead(UpperBand);
//
    Serial.print(vReal0[i]);
    Serial.print("\t");
    Serial.print(vReal1[i]);
    Serial.print("\t");
    Serial.println(vReal2[i]);

//    
    //Imaginary part must be zeroed in case of looping to avoid wrong calculations and overflows
    vImag0[i] = 0.0; 
    vImag1[i] = 0.0;
    vImag2[i] = 0.0;

    while(micros() - microseconds < sampling_period_us){
      //empty loop
    }
    microseconds += sampling_period_us;
  }
  
   FFT_low.Windowing(vReal0, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);  /* Weigh data */
   FFT_mid.Windowing(vReal1, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);
   FFT_high.Windowing(vReal2, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);
   
   FFT_low.Compute(vReal0, vImag0, samples, FFT_FORWARD); /* Compute FFT */
   FFT_mid.Compute(vReal1, vImag1, samples, FFT_FORWARD);
   FFT_high.Compute(vReal2, vImag2, samples, FFT_FORWARD);
   
   FFT_low.ComplexToMagnitude(vReal0, vImag0, samples); /* Compute magnitudes */
   FFT_mid.ComplexToMagnitude(vReal1, vImag1, samples);
   FFT_high.ComplexToMagnitude(vReal2, vImag2, samples);

   // Create peaks to store output
   peak_FFT peaks;

   // Calculate output and rescale based on number of LEDs
   double low = FFT_low.MajorPeak(vReal0, samples, samplingFrequency);
   double mid = FFT_mid.MajorPeak(vReal1, samples, samplingFrequency);
   double high = FFT_high.MajorPeak(vReal2, samples, samplingFrequency);

   Serial.print(low);
   Serial.print("\t");
   Serial.print(mid);
   Serial.print("\t");
   Serial.println(high);
   Serial.println("-");
   
   peaks.x_low =  constrain(map((long) low, 16, 241, 0, LED_COUNT - 1), 0, LED_COUNT - 1); // TODO: change to rescale using map()
   peaks.x_mid =  constrain(map((long) mid, 263, 1771, 0, LED_COUNT - 1), 0, LED_COUNT - 1);
   peaks.x_high =  constrain(map((long) high, 2635, 7957, 0, LED_COUNT - 1), 0, LED_COUNT - 1);



   // Change LED colors
   colorPeak(peaks, 10, 50); 
}

// Change LED colors to reflect peaks of signal
void colorPeak(peak_FFT peak, int spread, int wait) {
  strip.clear();
  int red;
  int green;
  int blue;
  for (int i=0; i < LED_COUNT; i++) {
    red = (abs(peak.x_low - i) < abs(spread)) ? (int) (MAX_BRIGHT / (abs(peak.x_low - i) + 1)) : 0;
    green = (abs(peak.x_mid - i) < abs(spread)) ? (int) (MAX_BRIGHT / (abs(peak.x_mid - i) + 1)) : 0;
    blue = (abs(peak.x_high - i) < abs(spread)) ? (int) (MAX_BRIGHT / (abs(peak.x_high - i) + 1)) : 0;

    strip.setPixelColor(i, red, green, blue);
  }
  strip.show();
  delay(wait);
}
