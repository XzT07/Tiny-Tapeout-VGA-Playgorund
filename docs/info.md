<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

XzT is a small VGA demo made only with logic gates. There is no CPU and no memory: the color of each pixel is calculated in real time while the screen is drawn, at 640x480 and 60 Hz.

A frame counter decides which scene is shown. There are 6 scenes, each one lasts about 2 seconds, and the sequence repeats forever:

| Scene | Effect |
|-------|--------|
| 0 | "XzT" title over moving squares |
| 1 | Colorful XOR pattern |
| 2 | Circular waves |
| 3 | Diamond tunnel |
| 4 | Color bars |
| 5 | "XzT" title over waves, flashing to the beat |

The shapes come from simple math on the pixel position, like the distance to the center of the screen. The "XzT" letters are drawn with lines and bars instead of a stored font. The output has 2 bits per color (64 colors) and goes to the TinyVGA PMOD.

Based on "Drop" by Renaldas Zioma, Erik Hemming and Matthias Kampa.


## How to test

1. Connect a TinyVGA PMOD to the output pins and a VGA monitor to it.
2. Set the clock to 25.175 MHz.
3. Reset the design. The demo starts with the "XzT" title.
4. Watch the 6 scenes play in a loop. No inputs are needed.

You can also try it without hardware in the VGA Playground (https://vga-playground.com) by pasting the code there.
