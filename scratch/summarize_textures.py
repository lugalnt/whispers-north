from PIL import Image

def summarize_img(name, path):
    im = Image.open(path)
    print(f"=== {name} ({im.size}, {im.mode}) ===")
    colors = im.getcolors(maxcolors=256)
    if colors:
        print(f"  Num colors: {len(colors)}")
        # Print top 5 colors
        top = sorted(colors, key=lambda x: x[0], reverse=True)[:5]
        print(f"  Top colors: {top}")

base = r"c:\Users\luisa\OneDrive\Desktop\whispers of the north\assets\models\DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02"
for f in ["c03_foun_01.png", "c03_foun_02.png", "c03_foun_03.png", "c3bay_yuka1.png", "c3_line.png", "c3_yuka2.png", "h_kage.png"]:
    import os
    summarize_img(f, os.path.join(base, f))
