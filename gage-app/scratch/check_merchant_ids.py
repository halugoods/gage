import glob
import re

for p in glob.glob(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\*_screen.dart'):
    with open(p, 'r', encoding='utf-8') as f:
        cnt = f.read()
        ids = re.findall(r"'id':\s*'([^']+)'", cnt)
        if ids:
            print(p, ids[:10])

with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\home_merchant_showcase_section.dart', 'r', encoding='utf-8') as f:
    cnt = f.read()
    ids = re.findall(r"'id':\s*'([^']+)'", cnt)
    print("SHOWCASE IDS:", ids)
