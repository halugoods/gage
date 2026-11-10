path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if "merchantId.contains('shop')" in l:
        print(f"Starts at line {i+1}")
        for j in range(i, min(i+110, len(lines))):
            print(f"{j+1}: {repr(lines[j])}")
        break
