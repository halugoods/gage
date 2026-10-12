import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';

class ProfileAccordionSheet extends StatefulWidget {
  final VoidCallback? onOpenFullProfile;

  const ProfileAccordionSheet({
    super.key,
    this.onOpenFullProfile,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onOpenFullProfile}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileAccordionSheet(onOpenFullProfile: onOpenFullProfile),
    );
  }

  @override
  State<ProfileAccordionSheet> createState() => _ProfileAccordionSheetState();
}

class _ProfileAccordionSheetState extends State<ProfileAccordionSheet> {
  // Akun aktif tersimpan untuk simulasi switch account profesional
  int _selectedAccountIndex = 0;
  final List<Map<String, String>> _availableAccounts = [
    {
      'role': 'Akun Utama (Pribadi)',
      'subtitle': 'Pelanggan GAGE Pracimantoro',
      'icon': 'user',
    },
    {
      'role': 'Akun Belanja Bisnis / Toko',
      'subtitle': 'Khusus belanja operasional & grosir',
      'icon': 'business',
    },
    {
      'role': 'Akun Keluarga / Titip Antar',
      'subtitle': 'Alamat Dusun & Kerabat',
      'icon': 'family',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?.name ?? 'Pengguna GAGE';
    final userPhone = user?.phone ?? '0812-3456-7890';
    final userEmail = user?.email ?? 'pengguna@gage.id';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? GageTheme.darkBackground : Colors.white;
    final cardBg = isDark ? GageTheme.darkSurface : Colors.grey.shade50;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header Mini Akun Aktif
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Avatar Profil
                    Stack(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? GageTheme.darkSurface : Colors.grey.shade100,
                            border: Border.all(color: GageTheme.primary.withValues(alpha: 0.5), width: 2),
                          ),
                          child: ClipOval(
                            child: _buildAvatarImage(user?.avatarUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? GageTheme.darkBackground : Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Info Nama & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'MEMBER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSubColor,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Edit Profil Cepat
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: GageTheme.primary, size: 28),
                      tooltip: 'Ubah Profil',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const EditProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Divider(height: 24, thickness: 1, color: borderCol),

              // 3. Menu Accordion Interaktif (Profil Saya, Ganti Akun, Hubungi CS WhatsApp, Logout)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Accordion Item 1: Profil Saya (Data Profil & Alamat Pengantaran)
                    _buildAccordionCard(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      title: 'Profil Saya & Alamat',
                      subtitle: 'Biodata akun, alamat pengantaran, dan pengaturan',
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textColor: textColor,
                      textSubColor: textSubColor,
                      isDark: isDark,
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.badge_outlined, color: GageTheme.primary, size: 20),
                          title: Text('Buka Layar Penuh Ubah Profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          trailing: Icon(Icons.chevron_right, size: 18, color: textSubColor),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => const EditProfileScreen()),
                            );
                          },
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
                          title: Text('Alamat Pengantaran Utama', style: TextStyle(fontSize: 13, color: textColor)),
                          subtitle: Text('Kecamatan Pracimantoro, Wonogiri', style: TextStyle(fontSize: 11, color: textSubColor)),
                          trailing: Icon(Icons.edit_location_alt_outlined, size: 18, color: textSubColor),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => const EditProfileScreen()),
                            );
                          },
                        ),
                        if (widget.onOpenFullProfile != null)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.account_box_outlined, color: Colors.teal, size: 20),
                            title: Text('Buka Tab Pengaturan Akun Lengkap', style: TextStyle(fontSize: 13, color: textColor)),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSubColor),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onOpenFullProfile!();
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Accordion Item 2: Ganti Akun / Switch Profile
                    _buildAccordionCard(
                      context: context,
                      icon: Icons.switch_account_outlined,
                      title: 'Ganti Akun / Switch Profile',
                      subtitle: 'Beralih antar profil pribadi, bisnis toko, atau keluarga',
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textColor: textColor,
                      textSubColor: textSubColor,
                      isDark: isDark,
                      children: [
                        ...List.generate(_availableAccounts.length, (idx) {
                          final acc = _availableAccounts[idx];
                          final isCurrent = _selectedAccountIndex == idx;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedAccountIndex = idx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Beralih ke: ${acc['role']}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: GageTheme.primary,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isCurrent ? GageTheme.primary : (isDark ? Colors.white38 : Colors.grey.shade400),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc['role']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            color: isCurrent ? GageTheme.primary : textColor,
                                          ),
                                        ),
                                        Text(acc['subtitle']!, style: TextStyle(fontSize: 11, color: textSubColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              side: const BorderSide(color: GageTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size.fromHeight(38),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                            label: const Text('Tambah Akun Baru / Masuk Akun Lain', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur login multi-akun sedang disiapkan'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Accordion Item 3: Hubungi CS WhatsApp
                    _buildAccordionCard(
                      context: context,
                      icon: Icons.support_agent_rounded,
                      title: 'Hubungi CS WhatsApp',
                      subtitle: 'Bantuan admin WhatsApp & layanan kendala pesanan',
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textColor: textColor,
                      textSubColor: textSubColor,
                      isDark: isDark,
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                          title: Text(
                            'Chat WhatsApp Admin GAGE Pracimantoro',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          subtitle: Text(
                            '0812-3456-7890 • Respons cepat jam operasional',
                            style: TextStyle(fontSize: 11, color: textSubColor),
                          ),
                          trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF16A34A)),
                          onTap: () async {
                            final uri = Uri.parse('https://wa.me/6281234567890?text=Halo%20Admin%20GAGE,%20saya%20butuh%20bantuan%20terkait%20pesanan.');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 4. Tombol Log Out / Keluar Akun (Aksen Merah)
                    InkWell(
                      onTap: () => _showLogoutDialog(context, auth, isDark),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A1215) : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF5A1B20) : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keluar Akun (Log Out)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Keluar dari sesi akun aktif di perangkat ini',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.red.shade200.withValues(alpha: 0.7) : Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.red.shade400, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccordionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderCol,
    required Color textColor,
    required Color textSubColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkBackground : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderCol),
            ),
            child: Icon(icon, color: GageTheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: textSubColor),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover);
    }
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(avatarUrl, fit: BoxFit.cover);
    }
    if (avatarUrl.startsWith('/') || avatarUrl.contains(':\\')) {
      return Image.file(File(avatarUrl), fit: BoxFit.cover);
    }
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Keluar Akun?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun GAGE ini? Anda dapat masuk kembali kapan saja dengan nomor WhatsApp Anda.',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
