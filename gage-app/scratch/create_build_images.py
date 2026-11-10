from PIL import Image, ImageDraw, ImageFont
import os

images_dir = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\assets\images'

def create_product_badge(filename, bg_color, accent_color, title, subtitle):
    img = Image.new('RGBA', (300, 300), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Rounded container border
    draw.rounded_rectangle([15, 15, 285, 285], radius=24, outline=accent_color, width=4)
    
    # Inner badge
    draw.rounded_rectangle([30, 30, 270, 160], radius=16, fill=accent_color)
    
    # Try default font or basic
    draw.text((150, 95), title, fill="white", anchor="mm")
    draw.text((150, 210), subtitle, fill=(40, 40, 40), anchor="mm")
    draw.text((150, 245), "Kualitas SNI Pracimantoro", fill=(100, 100, 100), anchor="mm")
    
    p = os.path.join(images_dir, filename)
    img.save(p)
    print(f"Created {p}")

create_product_badge('prod_semen.png', (245, 247, 250, 255), (100, 116, 139, 255), "SEMEN GRESIK", "PCC 40 KG")
create_product_badge('prod_cat.png', (254, 242, 242, 255), (225, 29, 72, 255), "CAT TEMBOK", "Dulux Catylac 5 Kg")
create_product_badge('prod_besi.png', (248, 250, 252, 255), (71, 85, 105, 255), "BESI BETON", "Ulir 10mm SNI")
print("All 3 build images created successfully!")
