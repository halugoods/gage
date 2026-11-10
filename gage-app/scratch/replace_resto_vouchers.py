path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = None
end_idx = None

for i, l in enumerate(lines):
    if "SingleChildScrollView(" in l and i > 1330:
        start_idx = i
        break

for i in range(start_idx, start_idx + 130):
    if "// 4. DAFTAR MENU MAKANAN" in lines[i]:
        end_idx = i - 3 # before the closing of SliverToBoxAdapter
        break

print(f"Replacing SingleChildScrollView from line {start_idx+1} to {end_idx+1}")

new_voucher_widget = '''                    child: SizedBox(
                      height: 84,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // 1. Voucher DISKON50
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 275,
                              child: GageTicketVoucherCard(
                                compact: true,
                                voucher: const {
                                  'id': 'v-food-50',
                                  'code': 'DISKON50',
                                  'service': 'GAGE Food',
                                  'type': 'order',
                                  'title': 'Diskon 50% Pengguna Baru',
                                  'discountText': 'Diskon 50% s/d Rp15rb',
                                  'minOrder': 20000,
                                  'quantity': 3,
                                  'tag': 'Pengguna Baru',
                                  'expiry': '31 Des 2026',
                                  'terms': ['Diskon 50% s/d Rp 15.000', 'Min. belanja Rp 20.000'],
                                },
                                isApplied: cart.foodPromoCode == 'DISKON50',
                                isEligible: cart.subtotal >= 20000,
                                onApply: () {
                                  if (cart.subtotal < 20000) {
                                    GageToast.show(context, 'Min. belanja Rp 20.000 untuk pakai voucher ini.', type: GageToastType.warning);
                                    return;
                                  }
                                  final disc = (cart.subtotal * 0.5).round().clamp(0, 15000);
                                  cart.setFoodPromo('DISKON50', disc);
                                  GageToast.show(context, 'Voucher DISKON50 terpasang!', type: GageToastType.success);
                                },
                                onTermsTap: () {},
                              ),
                            ),
                          ),
                          // 2. Voucher ONGKIRGRATIS
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 275,
                              child: GageTicketVoucherCard(
                                compact: true,
                                voucher: const {
                                  'id': 'v-ongkir-01',
                                  'code': 'ONGKIRGRATIS',
                                  'service': 'GAGE Food',
                                  'type': 'delivery',
                                  'title': 'Gratis Ongkir Xtra s/d Rp7rb',
                                  'discountText': 'Gratis Ongkir s/d Rp7rb',
                                  'minOrder': 25000,
                                  'quantity': 5,
                                  'tag': 'Semua Resto',
                                  'expiry': '31 Des 2026',
                                  'terms': ['Potongan ongkir s/d Rp 7.000', 'Min. belanja Rp 25.000'],
                                },
                                isApplied: cart.deliveryPromoCode == 'ONGKIRGRATIS',
                                isEligible: cart.subtotal >= 25000,
                                onApply: () {
                                  if (cart.subtotal < 25000) {
                                    GageToast.show(context, 'Min. belanja Rp 25.000 untuk gratis ongkir.', type: GageToastType.warning);
                                    return;
                                  }
                                  cart.setDeliveryPromo('ONGKIRGRATIS', 7000);
                                  GageToast.show(context, 'Voucher ONGKIRGRATIS terpasang!', type: GageToastType.success);
                                },
                                onTermsTap: () {},
                              ),
                            ),
                          ),
                          // 3. Voucher KULINER20
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 275,
                              child: GageTicketVoucherCard(
                                compact: true,
                                voucher: const {
                                  'id': 'v-food-20',
                                  'code': 'KULINER20',
                                  'service': 'GAGE Food',
                                  'type': 'order',
                                  'title': 'Diskon 20% Kuliner Santai',
                                  'discountText': 'Diskon 20% s/d Rp20rb',
                                  'minOrder': 50000,
                                  'quantity': 2,
                                  'tag': 'Diskon Terus',
                                  'expiry': '31 Des 2026',
                                  'terms': ['Diskon 20% s/d Rp 20.000', 'Min. belanja Rp 50.000'],
                                },
                                isApplied: cart.foodPromoCode == 'KULINER20',
                                isEligible: cart.subtotal >= 50000,
                                onApply: () {
                                  if (cart.subtotal < 50000) {
                                    GageToast.show(context, 'Min. belanja Rp 50.000 untuk pakai voucher ini.', type: GageToastType.warning);
                                    return;
                                  }
                                  final disc = (cart.subtotal * 0.2).round().clamp(0, 20000);
                                  cart.setFoodPromo('KULINER20', disc);
                                  GageToast.show(context, 'Voucher KULINER20 terpasang!', type: GageToastType.success);
                                },
                                onTermsTap: () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
'''

new_lines = lines[:start_idx] + [new_voucher_widget] + lines[end_idx:]
with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Updated resto_detail_screen.dart voucher section successfully!")
