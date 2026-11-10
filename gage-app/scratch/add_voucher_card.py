p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

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
            cart.removeFoodPromo();
          } else {
            cart.removeDeliveryPromo();
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

# Replace the final closing brace of _RestoDetailScreenState
idx = text.rfind('}')
assert idx != -1, "Last brace not found"
text = text[:idx] + method_code

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added _buildInteractiveVoucherCard to resto_detail_screen.dart!")
