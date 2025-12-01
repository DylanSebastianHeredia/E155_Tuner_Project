#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"
#include <stdint.h>
#include "main_lcd.h"

static void lcd_delay_us(volatile uint32_t n) {
    while (n--) {
        __asm__("nop");
    }
}

static inline void lcd_write_pin(int pin, int val) {
    digitalWrite(pin, val);
}

static inline void lcd_pulse_enable(void) {
    lcd_write_pin(LCD_EN, 1);
    lcd_delay_us(3000);
    lcd_write_pin(LCD_EN, 0);
    lcd_delay_us(3000);
}

static void lcd_write_4bit(uint8_t nib) {
    lcd_write_pin(LCD_D4, (nib >> 0) & 1);
    lcd_write_pin(LCD_D5, (nib >> 1) & 1);
    lcd_write_pin(LCD_D6, (nib >> 2) & 1);
    lcd_write_pin(LCD_D7, (nib >> 3) & 1);
    lcd_pulse_enable();
}

void lcd_send_cmd(uint8_t cmd) {
    lcd_write_pin(LCD_RS, 0);
    lcd_write_4bit(cmd >> 4);
    lcd_write_4bit(cmd & 0x0F);
    lcd_delay_us(5000);
}

void lcd_send_data(uint8_t data) {
    lcd_write_pin(LCD_RS, 1);
    lcd_write_4bit(data >> 4);
    lcd_write_4bit(data & 0x0F);
    lcd_delay_us(5000);
}

void lcd_init(void) {
    gpioEnable(GPIO_PORT_A);

    pinMode(LCD_RS, GPIO_OUTPUT);
    pinMode(LCD_EN, GPIO_OUTPUT);
    pinMode(LCD_D4, GPIO_OUTPUT);
    pinMode(LCD_D5, GPIO_OUTPUT);
    pinMode(LCD_D6, GPIO_OUTPUT);
    pinMode(LCD_D7, GPIO_OUTPUT);

    lcd_write_pin(LCD_RS, 0);
    lcd_write_pin(LCD_EN, 0);

    lcd_delay_us(50000);

    lcd_write_4bit(0x03);
    lcd_delay_us(5000);

    lcd_write_4bit(0x03);
    lcd_delay_us(2000);

    lcd_write_4bit(0x03);
    lcd_delay_us(2000);

    lcd_write_4bit(0x02);
    lcd_delay_us(2000);

    lcd_send_cmd(0x28);
    lcd_send_cmd(0x0C);
    lcd_send_cmd(0x01);
    lcd_delay_us(5000);
    lcd_send_cmd(0x06);
}

void lcd_clear(void) {
    lcd_send_cmd(0x01);
    lcd_delay_us(5000);
}

void lcd_home(void) {
    lcd_send_cmd(0x02);
    lcd_delay_us(5000);
}

void lcd_set_cursor(uint8_t col, uint8_t row) {
    uint8_t addr = (row == 0 ? 0x00 : 0x40) + col;
    lcd_send_cmd(0x80 | addr);
}

void lcd_print(char *str) {
    while (*str) {
        lcd_send_data(*str++);
    }
}

void lcd_write_char(char c) {
    lcd_send_data(c);
}

void lcd_create_char(uint8_t location, uint8_t pattern[8]) {
    location &= 0x07; // Only slots 0–7
    lcd_send_cmd(0x40 | (location << 3));  // Set CGRAM address to slot*8

    for (int i = 0; i < 8; i++) {
        lcd_send_data(pattern[i]);
    }
}

// ==========================
// main.c (integrated)
// ==========================

uint8_t flat_char[8] = {
    0b00100,
    0b00100,
    0b00100,
    0b00110,
    0b00101,
    0b00101,
    0b00110,
    0b00000
};

int main(void) {

    gpioEnable(GPIO_PORT_A);

    lcd_init();
    
 // load flat symbol into slot 0
    lcd_create_char(0, flat_char);

    lcd_set_cursor(0, 1);
    lcd_print("Note: A4");     // prints B
    lcd_write_char(0);    // prints flat sign

    lcd_set_cursor(4, 0);
    lcd_print("Freq:1000 Hz");

    lcd_set_cursor(10, 1);
    lcd_print("Cents:+0");

    while (1) { }

    return 0;
}





