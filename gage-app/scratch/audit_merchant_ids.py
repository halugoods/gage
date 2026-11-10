import re

files = [
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\home_merchant_showcase_section.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\food_explore_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\shop_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\farm_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\build_screen.dart',
]

merchant_ids = set()
for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    matches = re.findall(r"'id':\s*'([^']+)'", content)
    for m in matches:
        if not m.startswith('v-') and not m.startswith('prod-') and not m.startswith('menu-') and not m.startswith('cuan-'):
            merchant_ids.add((m, fpath.split('\\')[-1]))

print(f'Total merchant IDs found: {len(merchant_ids)}')
for mid, src in sorted(merchant_ids):
    print(f'{mid} (from {src})')
