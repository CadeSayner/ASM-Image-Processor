# ASM-Image-Processor
Image processing in MIPS assembly.

The program increase_brightness.asm is designed to enhance a color PPM image. It does this by incrementing each RGB (Red, Green, Blue) value by 10. 
If this addition exceeds 255, the value is capped at 255. The modified image is then saved to a new file. Additionally, 
the program calculates and displays the average RGB values of both the original and modified images as double precision values on the console. 
This program effectively brightens the image without over-saturating the colors.


The MIPS program greyscale.asm is designed to transform a color PPM P3 image into a greyscale PPM P2 image. This conversion is accomplished by calculating the greyscale value of each pixel. 
The greyscale value is determined by averaging its RGB values. Any decimal fractions are truncated to the nearest whole number. For instance, given RGB values of 166, 186, and 181, 
the resulting greyscale pixel value will be 177. The program also ensures that the file type in the header of the newly created greyscale file is appropriately set to "P2". 
This program effectively converts a colored image into a greyscale representation, simplifying visual information for various applications.
