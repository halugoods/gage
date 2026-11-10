import os

files = [
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\food_explore_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\shop_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\farm_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\build_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\ride\presentation\ride_booking_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\ride\presentation\send_booking_screen.dart',
    r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\babe\presentation\babe_screen.dart',
]

for p in files:
    print('===', os.path.basename(p))
    with open(p, 'r', encoding='utf-8') as f:
        for i, l in enumerate(f):
            if 'locationservice' in l.lower() or 'geolocator' in l.lower() or 'gps' in l.lower():
                print(f'  L{i+1}: {l.strip()[:100]}')
