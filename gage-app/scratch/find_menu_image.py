with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("Total lines:", len(lines))
for i, l in enumerate(lines):
    if '_getMenuItemImage' in l or 'dish_dimsum_original' in l:
        print(f"Line {i+1}: {l.strip()}")
