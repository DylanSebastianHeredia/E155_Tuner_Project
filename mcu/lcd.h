#ifndef LCD_H
#define LCD_H

#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"
#include <stdint.h>


// USER PIN DEFINITIONS (CHANGE IF NEEDED)

#define LCD_RS   PA1
#define LCD_EN   PA2
#define LCD_D4   PA3
#define LCD_D5   PA4
#define LCD_D6   PA5
#define LCD_D7   PA6


// PUBLIC API

void lcd_init(void);
void lcd_clear(void);
void lcd_home(void);
void lcd_set_cursor(uint8_t col, uint8_t row);
void lcd_print(char *str);
void lcd_write_char(char c);
void lcd_create_char(uint8_t location, uint8_t pattern [8]);

// Lower-level commands (used internally)
void lcd_send_cmd(uint8_t cmd);
void lcd_send_data(uint8_t data);

#endif

