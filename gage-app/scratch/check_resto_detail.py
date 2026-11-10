path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
print("Uses ItemVariantSheet:", "ItemVariantSheet" in text)
print("Uses RestoDetailScreen:", "class RestoDetailScreen" in text)
print("Uses category chips:", "categories" in text.lower())
