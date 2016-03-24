# board_test
This repository contains simple scripts for testing peripherals.


Tests:
* 6lowpan: pings a remote board.
* ethernet: pings given host (default: google.com).
* heartbeat_led: blinks the led for 10 seconds by default.
* nand: checks if partition /dev/mtd4 exists.
* nor: checks if partition /dev/mtd0 exists.
* sdcard/eMMC: tries to read/write to sdcard/eMMC. Formats to ext4 if no partition is found.
* spi_uart_leds: switch on/off each led for 50 ms.
* switch: checks that interrupts from pushing switch is triggered and that it corresponds to the right switch.
* audio: outputs a sine wave twice.