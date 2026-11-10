import os
import glob

for root, dirs, files in os.walk(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib'):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(root, f)
            with open(p, 'r', encoding='utf-8') as file:
                lines = file.readlines()
                for i, l in enumerate(lines):
                    if '6000' in l or '6.000' in l:
                        print(f"{os.path.basename(p)}:{i+1}: {l.strip()}")
