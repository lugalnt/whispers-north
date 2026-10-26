from PIL import Image
import os

p = r"c:\Users\luisa\OneDrive\Desktop\whispers of the north\assets\models\DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02\c03_foun_03.png"
img = Image.open(p)
print("c03_foun_03:", img.size, img.mode)
# Check alpha values
alphas = [img.getpixel((x, y))[3] for y in range(img.height) for x in range(img.width)]
print("Min alpha:", min(alphas), "Max alpha:", max(alphas), "Unique alphas:", len(set(alphas)))
colors = set(img.getpixel((x, y)) for y in range(img.height) for x in range(img.width))
print("Sample colors:", list(colors)[:10])
