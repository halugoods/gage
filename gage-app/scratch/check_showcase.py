path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\home_merchant_showcase_section.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re
print("Occurrences of ShopStoreDetailScreen:", content.count("ShopStoreDetailScreen"))
