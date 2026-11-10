path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(1420, 1455):
    print(lines[i].encode('ascii', errors='replace').decode('ascii'), end='')
