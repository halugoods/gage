import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_video_upload_screen.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// CreatorProfileHeader
/// Header Profil Semi-Sosmed ala TikTok & Instagram Creator
/// Menampilkan Avatar, Centang Verifikasi, Statistik Pengikut/Mengikuti/Suka/Cuan, Bio, dan Tombol Aksi.
class CreatorProfileHeader extends StatefulWidget {
  final String displayName;
  final String handle;
  final String avatarUrl;
  final String bio;
  final bool isVerified;
  final bool isOwnProfile;
  final String? targetId;

  const CreatorProfileHeader({
    super.key,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    required this.bio,
    this.isVerified = true,
    this.isOwnProfile = true,
    this.targetId,
  });

  @override
  State<CreatorProfileHeader> createState() => _CreatorProfileHeaderState();
}

class _CreatorProfileHeaderState extends State<CreatorProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialService = SocialProfileService.instance;
    final stats = socialService.stats;
    final isFollowing = widget.targetId != null && socialService.isFollowing(widget.targetId!);

    return Column(
      children: [
        const SizedBox(height: 10),

        // Avatar Lingkaran dengan Ring Gradien Elegan & Centang Verifikasi
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE52320), Color(0xFFF59E0B), Color(0xFFE52320)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: widget.avatarUrl.isNotEmpty
                      ? Image.network(
                          widget.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(isDark),
                        )
                      : _buildFallbackAvatar(isDark),
                ),
              ),
            ),
            if (widget.isVerified)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2563EB), // Official Blue Verified
                  size: 22,
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Nama Tampilan & Handle
        Text(
          widget.displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.handle.startsWith('@') ? widget.handle : '@${widget.handle}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 16),

        // Barisan Angka Metrik Sosial Murni (Mengikuti, Pengikut, Suka)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'Mengikuti',
                value: _formatNumber(stats.followingCount),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildStatItem(
                label: 'Pengikut',
                value: _formatNumber(stats.followersCount),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildStatItem(
                label: 'Suka',
                value: _formatNumber(stats.likesCount),
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Bio Deskripsi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Barisan Tombol Aksi Utama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: widget.isOwnProfile
              ? Row(
                  children: [
                    // Tombol Edit Profil
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        child: const Text(
                          'Edit Profil',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Bagikan Profil
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          GageToast.show(
                            context,
                            'Link profil @${widget.handle} berhasil disalin!',
                            type: GageToastType.success,
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 14),
                        label: const Text(
                          'Bagikan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Buat Video (Kreator / Kerkun)
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 1,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AffiliateVideoUploadScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text(
                          'Buat Video',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Tombol Ikuti / Mengikuti
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                              : GageTheme.primary,
                          foregroundColor: isFollowing
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          if (widget.targetId != null) {
                            final nowFollowed = await socialService.toggleFollow(widget.targetId!);
                            setState(() {});
                            if (mounted) {
                              GageToast.show(
                                context,
                                nowFollowed
                                    ? 'Anda sekarang mengikuti ${widget.displayName}'
                                    : 'Berhenti mengikuti ${widget.displayName}',
                                type: GageToastType.info,
                              );
                            }
                          }
                        },
                        icon: Icon(
                          isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isFollowing ? 'Mengikuti' : 'Ikuti',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Kirim Pesan
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          GageToast.show(
                            context,
                            'Membuka obrolan dengan ${widget.displayName}...',
                            type: GageToastType.info,
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                        label: const Text(
                          'Kirim Pesan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // Entri Cuan & Kreator (Hanya untuk pemilik profil)
        if (widget.isOwnProfile) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.amber.withValues(alpha: 0.25) : const Color(0xFFFED7AA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GAGE Cuan & Program Kreator',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF9A3412),
                              ),
                            ),
                            Text(
                              'Saldo Komisi: Rp ${_formatRupiahShort(stats.cuanCoinBalance)} • Cek performa & tarik dana',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white54 : const Color(0xFF9A3412),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackAvatar(bool isDark) {
    return Container(
      color: GageTheme.primary.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.person_rounded, color: GageTheme.primary, size: 44),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHighlight) ...[
                  const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: isHighlight
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  String _formatRupiahShort(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return '$amount';
  }
}
