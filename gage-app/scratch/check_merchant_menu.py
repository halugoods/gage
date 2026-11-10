path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if 'getMerchantMenu' in l:
        print(f'Line {i+1}: {l}')
        for j in range(i+130, min(i+250, len(lines))):
            print(f'{j+1}: {lines[j]}', end='')
        break
