# Let's read getMerchantMenu logic from gage_api_client.dart
with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart', 'r', encoding='utf-8') as f:
    client_code = f.read()

# Find getMerchantMenu definition
start_pos = client_code.find('static Future<List<Map<String, dynamic>>> getMerchantMenu(')
end_pos = client_code.find('// 4. ORDER CREATION', start_pos)
get_menu_func = client_code[start_pos:end_pos]

merchant_ids = [
    'build-cat-indah',
    'build-griya-indah',
    'build-mega-jaya',
    'build-sinar-mandiri',
    'build-sumber-bangunan',
    'build-tb-bangkit',
    'build-ud-besi',
    'farm-depot-harapan',
    'farm-kios-sedayu',
    'farm-kios-subur',
    'farm-poultry-berkah',
    'farm-sentra-mandiri',
    'farm-sumber-rejeki',
    'farm-tani-lestari',
    'farm-ud-berkah-joho',
    'mch-dimsum-01',
    'mch-mie-01',
    'mch-rc-01',
    'mch-roti-01',
    'mch-seblak-01',
    'shop-berkah-fajar',
    'shop-grosir-sentosa',
    'shop-kelontong-bu-sri',
    'shop-lapak-siti',
    'shop-minimarket-losari',
    'shop-sayur-bu-marti',
    'shop-sumber-lancar',
    'shop-telur-jaya',
]

print("Scanning matching logic...")
for mid in merchant_ids:
    matched = None
    if 'rc' in mid or 'rocket' in mid or 'ayam' in mid:
        matched = "Rocket Chicken"
    elif 'mie' in mid or 'bakso' in mid:
        matched = "Mie Ayam"
    elif 'seblak' in mid or 'snack' in mid or 'jajan' in mid:
        matched = "Seblak"
    elif any(k in mid for k in ['shop', 'ret', 'sembako', 'lapak', 'telur', 'sayur', 'grosir', 'siti', 'fajar', 'kelontong', 'minimarket', 'lancar']):
        matched = "Shop / Sembako"
    elif any(k in mid for k in ['farm', 'tani', 'ternak', 'pakan', 'subur', 'mandiri', 'lestari', 'depot', 'sedayu', 'poultry', 'rejeki', 'joho']):
        matched = "Farm / Tani"
    elif any(k in mid for k in ['build', 'tb', 'bangunan', 'semen', 'baja', 'cat', 'besi', 'griya', 'mega', 'sinar', 'sumber']):
        matched = "Build / Bangunan"
    elif 'roti' in mid:
        matched = "Roti Gembong"
    else:
        matched = "DEFAULT (Dimsum Sewu)"
    print(f"[{mid}]: -> {matched}")
