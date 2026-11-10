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

def simulate(merchantId):
    if 'rc' in merchantId:
        return 'RC'
    if 'mie' in merchantId:
        return 'MIE'
    if 'seblak' in merchantId:
        return 'SEBLAK'
    if any(k in merchantId for k in ['shop', 'ret', 'sembako', 'lapak', 'telur', 'sayur', 'grosir', 'siti', 'fajar']):
        return 'SHOP'
    if any(k in merchantId for k in ['farm', 'tani', 'ternak', 'kios', 'mandiri', 'lestari', 'rejeki', 'subur']):
        return 'FARM'
    if any(k in merchantId for k in ['build', 'tb', 'bangun', 'cat', 'besi', 'griya', 'jaya', 'bangkit']):
        return 'BUILD'
    if 'roti' in merchantId:
        return 'ROTI'
    return 'DEFAULT (Dimsum Sewu)'

for m in merchant_ids:
    result = simulate(m)
    print(f"Merchant {m:<25} -> {result}")
