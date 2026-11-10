path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\providers\cart_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if 'promo' in l.lower():
        print(f'{i+1}: {l.strip()}')
