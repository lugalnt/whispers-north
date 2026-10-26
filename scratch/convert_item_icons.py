import os
from PIL import Image

brain_dir = r"C:\Users\luisa\.gemini\antigravity-ide\brain\20e8ea9d-b8a4-4ef3-b2ca-851f42297cb2"
dest_dir = r"c:\Users\luisa\OneDrive\Desktop\whispers of the north\assets\sprites\items"
os.makedirs(dest_dir, exist_ok=True)

files = [
    ("item_queso_nordico_1792708158740.jpg", "queso_nordico.png"),
    ("item_fragmento_ceramica_1792708173429.jpg", "fragmento_ceramica.png"),
    ("item_llave_antigua_1792708186912.jpg", "llave_antigua.png")
]

for src_name, dst_name in files:
    src_path = os.path.join(brain_dir, src_name)
    dst_path = os.path.join(dest_dir, dst_name)
    
    img = Image.open(src_path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    # Replace white/near-white pixels with transparent
    for item in datas:
        r, g, b, a = item
        # If very close to white (background is flat white in the generation)
        if r > 240 and g > 240 and b > 240:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    # Resize to clean standard icon resolution (64x64 or 128x128 with nearest neighbor for crisp pixel art)
    img_crisp = img.resize((64, 64), Image.Resampling.NEAREST)
    img_crisp.save(dst_path, "PNG")
    print(f"Saved {dst_name} to {dst_path}")

print("Done converting item icons.")
