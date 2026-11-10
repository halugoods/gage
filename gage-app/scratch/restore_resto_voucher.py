path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the voucher section
start_idx = None
end_idx = None

for i, l in enumerate(lines):
    if 'SizedBox(' in l and 'height: 84' in lines[i+1]:
        start_idx = i
        break

for i in range(start_idx, start_idx + 130):
    if '// 4. DAFTAR MENU MAKANAN' in lines[i]:
        end_idx = i - 3
        break

print(f"Replacing lines {start_idx+1} to {end_idx+1}")

old_voucher_widget = '''                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'GAGEHEMAT',
                            title: 'Diskon makanan Rp 8.000',
                            sub: 'Min. pembelian Rp 15.000',
                            discount: 8000,
                            isFood: true,
                            isDark: isDark,
                          ),
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'KULINER10',
                            title: 'Diskon makanan Rp 10.000',
                            sub: 'Min. pembelian Rp 30.000',
                            discount: 10000,
                            isFood: true,
                            isDark: isDark,
                          ),
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'ONGKIRFREE',
                            title: 'Gratis ongkir s/d 7rb',
                            sub: 'Min. pembelian Rp 20.000',
                            discount: 7000,
                            isFood: false,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
'''

lines[start_idx:end_idx] = [old_voucher_widget]

# Also ensure _buildInteractiveVoucherCard is at the end of class before the final closing brace
full_text = "".join(lines)

# Remove unused import if present
full_text = full_text.replace("import 'package:gage_app/features/home/presentation/widgets/gage_ticket_voucher_card.dart';\n", "")

method_code = '''
  Widget _buildInteractiveVoucherCard({
    required BuildContext context,
    required CartProvider cart,
    required String code,
    required String title,
    required String sub,
    required int discount,
    required bool isFood,
    required bool isDark,
  }) {
    // Sunset Orange (#EA580C) for Food discount, Deep Teal (#0D9488) for Delivery discount
    final activeColor = isFood ? const Color(0xFFEA580C) : const Color(0xFF0D9488);
    final bgColor = isFood
        ? (isDark ? const Color(0xFF2A170A) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF032726) : const Color(0xFFF0FDFA));
    final badgeTag = isFood ? '-${discount ~/ 1000}RB' : 'ONGKIR';
    final isApplied = isFood ? cart.foodPromoCode == code : cart.deliveryPromoCode == code;

    return GestureDetector(
      onTap: () {
        if (isApplied) {
          if (isFood) {
            cart.clearFoodPromo();
          } else {
            cart.clearDeliveryPromo();
          }
          GageToast.show(context, 'Voucher $code dilepas', type: GageToastType.info);
        } else {
          if (isFood) {
            cart.setFoodPromo(code, discount);
          } else {
            cart.setDeliveryPromo(code, discount);
          }
          GageToast.show(context, 'Voucher $code berhasil dipasang!', type: GageToastType.success);
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isApplied ? activeColor : activeColor.withValues(alpha: 0.35),
            width: isApplied ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFood ? Icons.local_offer_rounded : Icons.delivery_dining_rounded,
                color: activeColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeTag,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isApplied) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
'''

if '_buildInteractiveVoucherCard' not in full_text:
    last_brace = full_text.rfind('}')
    full_text = full_text[:last_brace] + method_code

with open(path, 'w', encoding='utf-8') as f:
    f.write(full_text)

print("Restored authentic _buildInteractiveVoucherCard in resto_detail_screen.dart successfully!")
