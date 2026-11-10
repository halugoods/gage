p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\home_merchant_showcase_section.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("'image': 'assets/icons/ic_build.png'", "'image': 'assets/images/babe_hero_banner.png'")

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)
print('Updated _buildStores cover images in home_merchant_showcase_section.dart!')
