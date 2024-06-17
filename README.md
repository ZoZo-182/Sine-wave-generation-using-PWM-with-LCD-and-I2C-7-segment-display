# Sine Wave Generation Using PWM with LCD and I2C 7-Segment Display

This repository holds the project for developing and implementing a Pulse Wave Modulator (PWM) system aimed at producing sinusoidal waveforms using the Altera DE2-115 Board and various peripherals.

## Parts List

1. Altera DE2-115 Board
2. Sparkfun 7-segment display (with I2C)
3. Op-Amps
4. Breadboard, resistors, and capacitors

## System Design

### Overview

The system produces sinusoidal waveforms by generating PWM signals from 16-bit samples stored in the high-speed asynchronous SRAM of the DE2-115 board. The SRAM is initialized with data from a ROM, using a memory initialization file (MIF) that depicts a 16-bit sinusoidal function with a DC offset equivalent to the signal's amplitude.

### Functionality

The system reads 256 samples from the SRAM at variable rates, generating PWM signals that represent sine waves at different frequencies: 60 Hz, 120 Hz, and 1000 Hz. The PWM signal output passes through a low-pass active filter to produce smoother sine functions suitable for display on an oscilloscope.

### Modes of Operation

The system operates in four modes: Initialization, Test, Pause, and PWM Generation.

1. **Initialization Mode**
   - Upon power on or pressing the KEY0 button, the system enters Initialization mode.
   - SRAM loads a default data sequence from a 1-Port ROM.
   - The LCD displays "Initializing" during this phase.
   - Releasing KEY0 defaults the system to Test Mode.

2. **Test Mode**
   - First line of the LCD displays "Test Mode".
   - The 8-bit address (in Hex) and the 16-bit data (in Hex) from the SRAM are displayed on the second line of the LCD and updated at a readable speed.
   - The 16-bit data (in Hex) from the SRAM is also displayed on an external 7-segment I2C display.
   - Pressing KEY1 toggles between Test Mode and Pause Mode.

3. **Pause Mode**
   - First line of the LCD displays "Pause Mode".
   - The address and data freeze at the current value.

4. **PWM Generation Mode**
   - Pressing KEY2 toggles between Test Mode and PWM Generation mode.
   - KEY3 cycles through the three frequencies: 60 Hz (default), 120 Hz, and 1000 Hz.
   - The second line of the LCD displays the frequency of the PWM signal.

## LCD Display

The system's status is visually represented on the DE2 board's 16x2 LCD panel, capable of displaying 16 alphanumeric characters across its 2 lines. The displayed message on the LCD denotes the system's status, including:

- "Initializing" during Initialization mode.
- "Test Mode" or "Pause Mode" based on the current mode.
- The 8-bit address and 16-bit data from SRAM in Test Mode.
- The PWM signal frequency in PWM Generation mode.

## Note

Please take a look at the project concept diagram included in the repository for an idea of how each component connects and interacts.
