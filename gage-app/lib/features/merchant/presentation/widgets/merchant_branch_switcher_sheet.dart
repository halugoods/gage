import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/models/merchant_branch_model.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Floating sheet for switching active merchant branch or adding a new outlet branch.
class MerchantBranchSwitcherSheet extends StatefulWidget {
  const MerchantBranchSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GageFloatingSheet.show<void>(
      context: context,
      title: 'Kelola Cabang Outlet',
      builder: (_) => const MerchantBranchSwitcherSheet(),
    );
  }

  @override
  State<MerchantBranchSwitcherSheet> createState() => _MerchantBranchSwitcherSheetState();
}

class _MerchantBranchSwitcherSheetState extends State<MerchantBranchSwitcherSheet> {
  bool _showAddForm = false;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitNewBranch(MerchantOrderProvider provider) async {
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty || address.isEmpty) {
      GageToast.show(context, 'Nama cabang dan alamat wajib diisi', type: GageToastType.warning);
      return;
    }

    HapticFeedback.mediumImpact();
    final seq = (provider.branches.length + 1).toString().padLeft(2, '0');
    final newBranch = MerchantBranch(
      id: 'GAGE-PRC-FD01-$seq',
      name: name,
      address: address,
      landmark: _landmarkCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '085156955735',
      isPrimary: false,
      isOpen: true,
    );

    await provider.addBranch(newBranch);
    if (!mounted) return;
    Navigator.pop(context);
    GageToast.show(context, 'Cabang baru aktif: $name', type: GageToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();
    final branches = provider.branches;
    final activeId = provider.activeBranchId;

    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _showAddForm
                ? 'Daftarkan cabang baru di bawah akun kemitraan Anda.'
                : 'Pilih outlet yang sedang aktif atau tambah cabang baru.',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          const SizedBox(height: 14),

          if (!_showAddForm) ...[
            ...branches.map((branch) {
              final isSelected = branch.id == activeId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await provider.switchBranch(branch);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    GageToast.show(context, 'Cabang aktif: ${branch.name}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary.withValues(alpha: isDark ? 0.16 : 0.06)
                          : cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? GageTheme.primary : borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GageTheme.primary.withValues(alpha: 0.14)
                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: isSelected ? GageTheme.primary : subColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      branch.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: branch.isPrimary
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      branch.isPrimary ? 'PUSAT' : 'CABANG',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: branch.isPrimary
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                branch.address,
                                style: TextStyle(fontSize: 11.5, color: subColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? GageTheme.primary : subColor,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 6),

            // Add New Branch Button
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showAddForm = true);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GageTheme.primary),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18, color: GageTheme.primary),
                label: const Text(
                  'Tambah Cabang Outlet Baru',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: GageTheme.primary,
                  ),
                ),
              ),
            ),
          ] else ...[
            _buildInput(_nameCtrl, 'Nama Cabang (Misal: Dimsum Sewu Baturetno)', Icons.store_rounded, isDark, cardBg, borderColor, textColor, subColor),
            const SizedBox(height: 10),
            _buildInput(_addressCtrl, 'Alamat Lengkap Kios', Icons.location_on_outlined, isDark, cardBg, borderColor, textColor, subColor),
            const SizedBox(height: 10),
            _buildInput(_landmarkCtrl, 'Patokan / Landmark (Opsional)', Icons.place_outlined, isDark, cardBg, borderColor, textColor, subColor),
            const SizedBox(height: 10),
            _buildInput(_phoneCtrl, 'Nomor WhatsApp Cabang', Icons.phone_outlined, isDark, cardBg, borderColor, textColor, subColor, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showAddForm = false),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold, color: subColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submitNewBranch(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Cabang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark,
    Color bg,
    Color borderColor,
    Color textColor,
    Color subColor, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: subColor),
        prefixIcon: Icon(icon, size: 18, color: GageTheme.primary),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
