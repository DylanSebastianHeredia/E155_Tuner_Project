//////////////////////////////////////////////////////////////////////
//                     STM32L432KC FFT portion                      
//           reads 512ppt FFT results from FPGA over spi              
//    finds dominant frequency, note name, and cents deviation       
//                       Displays on LCD    
//    Broderick Bownds & sebastian Heredia
//    brbownds@hmc.edu, dheredia@hmc.edu                    
//////////////////////////////////////////////////////////////////////

#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "STM32L432KC.h"
#include "lcd.h"


// defintions
#define FFT_SIZE        512
#define NUM_USED_BINS   (FFT_SIZE / 2)      // bins 0..255
#define FS_HZ           16000.0f            // FPGA sample rate
#define BIN_WIDTH_HZ    (FS_HZ / FFT_SIZE)  // = 31.25 Hz/bin
// also fpga interpace pins
#define DONE PA8    // FPGA DONE pin
#define RST PA9      // FPGA reset/start pin
#define FULL_RST PA10 // optional full reset (prolly use)


// SPI is 8-bit on your MCU. FPGA sends:
static uint32_t spi_read_fft_word(void) {
    uint8_t b1 = spiSendReceive(0);
    uint8_t b2 = spiSendReceive(0);
    uint8_t b3 = spiSendReceive(0);
    uint8_t b4 = spiSendReceive(0);

    uint32_t word = ((uint32_t)b1 << 24) | ((uint32_t)b2 << 16) | ((uint32_t)b3 <<  8) | ((uint32_t)b4);

    return word;
}


// Note Table
static const char *note_names[12] = {
    "A", "Bb", "B", "C", "Db", "D",
    "Eb", "E", "F", "Gb", "G", "Ab"
};

static float note_frequency_from_index(int semitone_offset) {
    return 440.0f * powf(2.0f, semitone_offset / 12.0f);
}

// Frequency to Note Conversion

static void frequency_to_note_and_cents(
        float freq,
        char *out_note,
        int *out_cents
    )
{
    if (freq <= 0.0f) {
        out_note[0] = '-';
        out_note[1] = '\0';
        *out_cents = 0;
        return;
    }

    float n = 12.0f * (logf(freq / 440.0f) / logf(2.0f)); // semitones
    int nearest_n = (int)roundf(n);

    float exact_note_freq = note_frequency_from_index(nearest_n);
    int cents = (int)roundf(1200.0f * (logf(freq / exact_note_freq) / logf(2.0f)));

    int note_name = nearest_n % 12;
    if (note_name < 0) note_name += 12;

    strcpy(out_note, note_names[note_name]);
    *out_cents = cents;
}

//
// LCD Output
static void display_all(uint16_t freq_hz, char *note, int cents) {
    char buf[16];

    lcd_clear();

    // Row 0: Frequency
    lcd_set_cursor(0, 0);
    sprintf(buf, "Freq:%uHz", freq_hz);
    lcd_print(buf);

    // Row 1: Note + cents
    lcd_set_cursor(0, 1);
    lcd_print("Note:");
    lcd_print(note);

    lcd_set_cursor(8, 1);
    sprintf(buf, "%+d", cents);
    lcd_print(buf);
}


int main(void) {
    
    // System Init
    configureFlash();
    configureClock();
    gpioEnable(GPIO_PORT_A);

    lcd_init();
    lcd_clear();
    lcd_set_cursor(0, 0);
    lcd_print("FPGA FFT Tuner");
    lcd_set_cursor(0, 1);
    lcd_print("Waiting...");

    // SPI Init
    initSPI(5, 0, 0); // 8-bit SPI mode, CPOL=0, CPHA=0

    // FFT Buffers
    static int16_t fft_real[FFT_SIZE];
    static int16_t fft_imag[FFT_SIZE];

    // Main Loop
    while (1) {

        // 1) Wait for FPGA DONE (frame complete)
        while (!digitalRead(DONE));

      // Read 512 FFT bins (each = 4 bytes)
        for (uint16_t i = 0; i < FFT_SIZE; i++) {
            uint32_t w = spi_read_fft_word();

            fft_real[i] = (int16_t)(w >> 16);
            fft_imag[i] = (int16_t)(w & 0xFFFF);
        }

 // Find strongest bin (max)
      
        uint32_t max_mag = 0;
        uint16_t max_i = 0;

        for (uint16_t i = 1; i < NUM_USED_BINS; i++) {
            int32_t re = fft_real[i];
            int32_t im = fft_imag[i];

            uint32_t mag = (uint32_t)(re * (int32_t)re + im * (int32_t)im);

            if (mag > max_mag) {
                max_mag = mag;
                max_i = i;
            }
        }


        // 4) Convert to frequency
        float freq_f = max_i * BIN_WIDTH_HZ;
        uint16_t freq_hz = (uint16_t)(freq_f + 0.5f);
        // use frequency for note and cents
        char note[3];
        int cents = 0;
        frequency_to_note_and_cents(freq_f, note, &cents);

        // Update LCD
        display_all(freq_hz, note, cents);

        // Pulse RST to tell FPGA to start next frame
        togglePin(RST);
        togglePin(RST);
    }

    return 0;
}


