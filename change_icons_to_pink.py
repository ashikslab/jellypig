#!/usr/bin/env python3
"""
Change all blue colors to BRIGHT PINK in tvOS icon files.
Converts blue hues to vibrant hot pink/magenta.
"""

from PIL import Image
import colorsys
import glob
import os

def blue_to_bright_pink(r, g, b, a):
    """Convert blue colors to VERY BRIGHT PINK, preserving other colors."""
    # Convert RGB to HSV
    h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)

    # Blue hues are roughly 180-240 degrees (0.5-0.67 in 0-1 range)
    # Convert to BRIGHT PINK/MAGENTA
    if 0.45 < h < 0.75:  # Blue range (including cyan-blue)
        # Use hot pink hue (around 330 degrees = 0.917)
        h = 0.917  # Bright hot pink
        # MAX saturation for vibrant color
        s = 1.0
        # Boost brightness significantly
        v = min(1.0, v * 1.3)

    # Convert back to RGB
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return int(r * 255), int(g * 255), int(b * 255), a

def process_image(input_path, output_path):
    """Process a single PNG image to change blue to bright pink."""
    print(f"Processing: {input_path}")

    # Open image
    img = Image.open(input_path).convert('RGBA')
    pixels = img.load()

    # Process each pixel
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Only process non-transparent pixels
            if a > 0:
                pixels[x, y] = blue_to_bright_pink(r, g, b, a)

    # Save the modified image
    img.save(output_path, 'PNG')
    print(f"Saved: {output_path}")

def main():
    # Base path for tvOS icons
    base_path = "jellypig tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets"

    # Find all PNG files in the icon directories
    pattern = os.path.join(base_path, "**/*.png")
    png_files = glob.glob(pattern, recursive=True)

    print(f"Found {len(png_files)} PNG files to process")

    for png_file in png_files:
        process_image(png_file, png_file)

    print("\nDone! All icons converted from blue to BRIGHT PINK.")

if __name__ == "__main__":
    main()
