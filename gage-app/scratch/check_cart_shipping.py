with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\providers\cart_provider.dart', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.splitlines()
for i, l in enumerate(lines):
    if 'shippingfee' in l.lower() or 'deliveryoption' in l.lower() or 'ishematavailable' in l.lower():
        print(f'{i+1}: {l}')
