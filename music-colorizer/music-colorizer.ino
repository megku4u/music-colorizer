// A script that sets specific LED colors based on audio input.

#include <Adafruit_NeoPixel.h>
#include <arduinoFFT.h>

arduinoFFT FFT = arduinoFFT(); // create FFT object

/*
FFT constants
*/
const uint16_t samples = 256; //This value MUST ALWAYS be a power of 2
const double samplingFrequency = 9000;
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

// Which pin on the Arduino is connected to the NeoPixels?
#define LED_PIN 53

// How many NeoPixels are attached to the Arduino?
#define LED_COUNT 120

#define LowBand A0
#define MidBand A1
#define UpperBand A2

#define MAX_BRIGHT 255

// Declare our NeoPixel strip object:
Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);
// Argument 1 = Number of pixels in NeoPixel strip
// Argument 2 = Arduino pin number (most are valid)
// Argument 3 = Pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
//   NEO_RGBW    Pixels are wired for RGBW bitstream (NeoPixel RGBW products)

class peak_FFT {
  public:
    int x_low;
    int x_mid;
    int x_high;
};

void setup() {
  strip.begin();           // INITIALIZE NeoPixel strip object (REQUIRED)
  strip.show();            // Turn OFF all pixels ASAP
  strip.setBrightness(50); // Set BRIGHTNESS to about 1/5 (max = 255)
  Serial.begin(115200); // initialize Serial Monitor
}


// Main loop
void loop() {
  /* Collect data */
  for (uint16_t i = 0; i < samples; i++)
  {
    vReal0[i] = analogRead(LowBand);
    vReal1[i] = analogRead(MidBand);
    vReal2[i] = analogRead(UpperBand);

    vImag0[i] = 0.0; //Imaginary part must be zeroed in case of looping to avoid wrong calculations and overflows
    vImag1[i] = 0.0; //Imaginary part must be zeroed in case of looping to avoid wrong calculations and overflows
    vImag2[i] = 0.0; //Imaginary part must be zeroed in case of looping to avoid wrong calculations and overflows
  }
  
   FFT.Windowing(vReal0, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);  /* Weigh data */
   FFT.Windowing(vReal1, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);
   FFT.Windowing(vReal2, samples, FFT_WIN_TYP_HAMMING, FFT_FORWARD);
   FFT.Compute(vReal0, vImag0, samples, FFT_FORWARD); /* Compute FFT */
   FFT.Compute(vReal1, vImag1, samples, FFT_FORWARD);
   FFT.Compute(vReal2, vImag2, samples, FFT_FORWARD);
   FFT.ComplexToMagnitude(vReal0, vImag0, samples); /* Compute magnitudes */
   FFT.ComplexToMagnitude(vReal1, vImag1, samples);
   FFT.ComplexToMagnitude(vReal2, vImag2, samples);
   peak_FFT peaks;
   peaks.x_low = (int) FFT.MajorPeak(vReal0, samples, samplingFrequency) % LED_COUNT; // TODO: change to rescale using map()
   peaks.x_mid = (int) FFT.MajorPeak(vReal1, samples, samplingFrequency) % LED_COUNT;
   peaks.x_high = (int) FFT.MajorPeak(vReal2, samples, samplingFrequency) % LED_COUNT;
    Serial.print("Peaks: ");
    Serial.print("\t");
    Serial.print(FFT.MajorPeak(vReal0, samples, samplingFrequency));
    Serial.print("\t");
    Serial.print(FFT.MajorPeak(vReal1, samples, samplingFrequency));
    Serial.print("\t");
    Serial.println(FFT.MajorPeak(vReal2, samples, samplingFrequency));
   colorPeak(peaks, 10, 100); 
}

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
