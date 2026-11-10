import re

with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\build_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()
imgs = re.findall(r"'image':\s*'([^']+)'", text)
print('Build screen store images:', set(imgs))

with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\farm_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()
imgs_farm = re.findall(r"'image':\s*'([^']+)'", text)
print('Farm screen store images:', set(imgs_farm))
