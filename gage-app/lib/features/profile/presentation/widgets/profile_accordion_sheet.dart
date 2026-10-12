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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.shade300,
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
                            color: Colors.grey.shade100,
                            border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3), width: 2),
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
                              border: Border.all(color: Colors.white, width: 2),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'MEMBER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
                          MaterialUriRoute(builder: (ctx) => const EditProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 24, thickness: 1),

              // 3. Menu Accordion Interaktif
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Accordion Item 1: Kelola Profil & Alamat
                    _buildAccordionCard(
                      icon: Icons.badge_outlined,
                      title: 'Data Profil & Alamat Pengantaran',
                      subtitle: 'Ubah biodata, foto, dan titik antar',
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline, color: GageTheme.primary, size: 20),
                          title: const Text('Buka Layar Penuh Ubah Profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialUriRoute(builder: (ctx) => const EditProfileScreen()),
                            );
                          },
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
                          title: const Text('Alamat Pengantaran Utama', style: TextStyle(fontSize: 13)),
                          subtitle: const Text('Kecamatan Pracimantoro, Wonogiri', style: TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.edit_location_alt_outlined, size: 18),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialUriRoute(builder: (ctx) => const EditProfileScreen()),
                            );
                          },
                        ),
                        if (widget.onOpenFullProfile != null)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.account_box_outlined, color: Colors.teal, size: 20),
                            title: const Text('Buka Tab Pengaturan Akun Lengkap', style: TextStyle(fontSize: 13)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onOpenFullProfile!();
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Accordion Item 2: Ganti Akun / Switch Profile (Sesuai Request User)
                    _buildAccordionCard(
                      icon: Icons.switch_account_outlined,
                      title: 'Ganti Akun / Switch Profile',
                      subtitle: 'Beralih antar profil pengguna atau bisnis',
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
                                    color: isCurrent ? GageTheme.primary : Colors.grey.shade400,
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
                                            color: isCurrent ? GageTheme.primary : Colors.black87,
                                          ),
                                        ),
                                        Text(acc['subtitle']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

                    // Accordion Item 3: Bantuan & Hubungi Admin CS GAGE
                    _buildAccordionCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Bantuan & Layanan Pelanggan',
                      subtitle: 'Hubungi admin WhatsApp & panduan order',
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF16A34A), size: 20),
                          title: const Text('Chat WhatsApp CS GAGE Pracimantoro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Layanan bantuan kendala order & informasi', style: TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.open_in_new, size: 16),
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
                      onTap: () => _showLogoutDialog(context, auth),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
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
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Keluar dari sesi akun aktif di perangkat ini',
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade400),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: GageTheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Keluar Akun?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun GAGE ini? Anda dapat masuk kembali kapan saja dengan nomor WhatsApp Anda.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              Navigator.pop(context); // Tutup sheet
              auth.signOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class MaterialUriRoute<T> extends MaterialPageRoute<T> {
  MaterialUriRoute({required super.builder});
}
