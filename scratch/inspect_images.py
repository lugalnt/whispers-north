from PIL import Image
import os

folder = r"c:\Users\luisa\OneDrive\Desktop\whispers of the north\assets\models\DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02"
for f in os.listdir(folder):
    if f.endswith(".png"):
        p = os.path.join(folder, f)
        img = Image.open(p)
        print(f"{f}: size={img.size}, mode={img.mode}")
