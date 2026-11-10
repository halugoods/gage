for p in [r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\shop_screen.dart',
           r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\farm_screen.dart',
           r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\build_screen.dart',
           r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\babe\presentation\babe_screen.dart']:
    with open(p, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    print('===', p)
    for i in range(min(160, len(lines))):
        if 'initState' in lines[i] or 'gps' in lines[i].lower() or 'location' in lines[i].lower():
            print(f'  L{i+1}: {lines[i].strip()}')
