path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\promo_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(30, 85):
    print(lines[i].encode('ascii', errors='replace').decode('ascii'), end='')
