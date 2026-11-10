# 1. Update gage_pricing_service.dart
pricing_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\services\gage_pricing_service.dart'
with open(pricing_path, 'r', encoding='utf-8') as f:
    pricing_content = f.read()

old_shipping_calc = '''  static int calculateCustomerShippingFee({
    required double distanceKm,
    String deliveryOption = 'REGULER',
    int merchantCount = 1,
  }) {
    final lower = deliveryOption.toLowerCase();
    final isHemat = lower.contains('hemat');
    final isCar = lower.contains('car');

    if (isCar) {
      if (isHemat) {
        if (distanceKm <= 3.0) return 14000;
        final raw = 14000 + ((distanceKm - 3.0) * 4500);
        return roundUpTo500(raw.round());
      } else {
        if (distanceKm <= 3.0) return 16000;
        final raw = 16000 + ((distanceKm - 3.0) * 5000);
        return roundUpTo500(raw.round());
      }
    }

    if (distanceKm <= 0) {
      return isHemat ? rideHematBase : rideRegulerBase;
    }
    return calculateTieredFare(distanceKm: distanceKm, isReguler: !isHemat);
  }'''

new_shipping_calc = '''  static int calculateCustomerShippingFee({
    required double distanceKm,
    String deliveryOption = 'REGULER',
    int merchantCount = 1,
  }) {
    final lower = deliveryOption.toLowerCase();
    final isHemat = lower.contains('hemat');
    final isPrioritas = lower.contains('prioritas');
    final isCar = lower.contains('car');

    if (isCar) {
      if (isHemat) {
        if (distanceKm <= 3.0) return 14000;
        final raw = 14000 + ((distanceKm - 3.0) * 4500);
        return roundUpTo500(raw.round());
      } else if (isPrioritas) {
        if (distanceKm <= 3.0) return 20000;
        final raw = 20000 + ((distanceKm - 3.0) * 5500);
        return roundUpTo500(raw.round());
      } else {
        if (distanceKm <= 3.0) return 16000;
        final raw = 16000 + ((distanceKm - 3.0) * 5000);
        return roundUpTo500(raw.round());
      }
    }

    if (distanceKm <= 0) {
      if (isPrioritas) return rideRegulerBase + 4000;
      return isHemat ? rideHematBase : rideRegulerBase;
    }
    final baseFare = calculateTieredFare(distanceKm: distanceKm, isReguler: !isHemat);
    if (isPrioritas) {
      return baseFare + 4000;
    }
    return baseFare;
  }'''

if old_shipping_calc in pricing_content:
    pricing_content = pricing_content.replace(old_shipping_calc, new_shipping_calc)
    with open(pricing_path, 'w', encoding='utf-8') as f:
        f.write(pricing_content)
    print("Updated gage_pricing_service.dart successfully!")
else:
    print("WARNING: old_shipping_calc not found in gage_pricing_service.dart")

# 2. Update cart_provider.dart
cart_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\providers\cart_provider.dart'
with open(cart_path, 'r', encoding='utf-8') as f:
    cart_content = f.read()

old_cart_shipping = '''  // Ongkir Customer dengan perhitungan Decoy Effect (0-3km: 9rb vs 12rb)
  int get rawShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: _deliveryOption,
        merchantCount: merchantCount,
      );

  // Opsi Reguler (Decoy Prioritas: 0-3km Rp 12.000)
  int get regulerShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'REGULER',
        merchantCount: merchantCount,
      );

  // Opsi Hemat (Tarif Dasar: 0-3km Rp 9.000)
  int get hematShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'HEMAT',
        merchantCount: merchantCount,
      );'''

new_cart_shipping = '''  // 1. Opsi Prioritas (Express Direct: Reguler + Rp 4.000)
  int get prioritasShippingFee => regulerShippingFee + 4000;

  // 2. Opsi Reguler (Decoy Standar: 0-3km Rp 12.000)
  int get regulerShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'REGULER',
        merchantCount: merchantCount,
      );

  // 3. Opsi Hemat (Tarif Dasar Saver Batch: 0-3km Rp 9.000)
  int get hematShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'HEMAT',
        merchantCount: merchantCount,
      );

  // Syarat Opsi Hemat: Hanya aktif jika jarak >= 2.5 km (untuk melindungi upah minimum driver)
  bool get isHematAvailable => _distanceKm >= 2.5;

  // Ongkir Customer Terpilih (Sesuai Opsi Aktif Tanpa Mengubah Getter Masing-Masing)
  int get rawShippingFee {
    final opt = _deliveryOption.toUpperCase();
    if (opt == 'PRIORITAS') {
      return prioritasShippingFee;
    } else if (opt == 'HEMAT') {
      return isHematAvailable ? hematShippingFee : regulerShippingFee;
    } else {
      return regulerShippingFee;
    }
  }'''

if old_cart_shipping in cart_content:
    cart_content = cart_content.replace(old_cart_shipping, new_cart_shipping)
    with open(cart_path, 'w', encoding='utf-8') as f:
        f.write(cart_content)
    print("Updated cart_provider.dart successfully!")
else:
    print("WARNING: old_cart_shipping not found in cart_provider.dart")

# 3. Update checkout_screen.dart
checkout_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\checkout\presentation\checkout_screen.dart'
with open(checkout_path, 'r', encoding='utf-8') as f:
    checkout_content = f.read()

old_checkout_radio = '''                                    // Reguler
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('REGULER'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Reguler', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('25-35 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format(cart.rawShippingFee),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'REGULER' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'REGULER' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('Langsung ke kamu, pasti tepat waktu', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // Hemat
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('HEMAT'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Hemat', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('45-55 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format((cart.rawShippingFee - 3000).clamp(5000, 999999)),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'HEMAT' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'HEMAT' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('Rute pengantaran gabungan, ongkir lebih hemat', style: TextStyle(fontSize: 11.5, color: Color(0xFFEA580C))),
                                          ],
                                        ),
                                      ),
                                    ),'''

new_checkout_radio = '''                                    // 1. Prioritas (Express Direct)
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('PRIORITAS'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Prioritas', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('15-25 min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format(cart.prioritasShippingFee),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'PRIORITAS' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'PRIORITAS' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('⚡ Kurir langsung jalan, jaminan makanan hangat & cepat', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // 2. Reguler (Paling Populer)
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('REGULER'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Reguler', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('25-35 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format(cart.regulerShippingFee),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'REGULER' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'REGULER' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('Langsung ke kamu, pasti tepat waktu', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // 3. Hemat (Saver Batch)
                                    InkWell(
                                      onTap: cart.isHematAvailable ? () => cart.setDeliveryOption('HEMAT') : null,
                                      child: Opacity(
                                        opacity: cart.isHematAvailable ? 1.0 : 0.45,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('Hemat', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                    child: const Text('45-55 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    currencyFormatter.format(cart.hematShippingFee),
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    cart.deliveryOption == 'HEMAT' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                    color: cart.deliveryOption == 'HEMAT' ? GageTheme.primary : Colors.grey,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cart.isHematAvailable
                                                    ? '🍃 Rute pengantaran gabungan kurir, ongkir lebih hemat'
                                                    : '🍃 Khusus pengantaran jarak jauh (> 2.5 km)',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: cart.isHematAvailable ? const Color(0xFFEA580C) : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),'''

if old_checkout_radio in checkout_content:
    checkout_content = checkout_content.replace(old_checkout_radio, new_checkout_radio)
    with open(checkout_path, 'w', encoding='utf-8') as f:
        f.write(checkout_content)
    print("Updated checkout_screen.dart successfully!")
else:
    print("WARNING: old_checkout_radio not found in checkout_screen.dart")
