with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\checkout\presentation\checkout_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.splitlines()
for i, l in enumerate(lines):
    if 'currencyformatter' in l.lower() and ('shipping' in l.lower() or 'ongkir' in l.lower() or 'fee' in l.lower()):
        print(f'{i+1}: {l.strip()[:100]}')
