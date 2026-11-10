import re

for fname in ['shop_screen.dart', 'farm_screen.dart', 'build_screen.dart', 'home_merchant_showcase_section.dart', 'food_explore_screen.dart']:
    p = rf'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\{fname}'
    if 'home' in fname:
        p = rf'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\{fname}'
    with open(p, 'r', encoding='utf-8') as f:
        text = f.read()
    stores = re.findall(r"'id':\s*'([^']+)'", text)
    real_stores = [s for s in stores if not s.startswith('v-') and not s.startswith('prod-') and not s.startswith('menu-')]
    print(f"=== {fname} ===")
    for s in set(real_stores):
        print(f"  - {s}")
