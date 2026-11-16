import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
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
    this.isVerified = false,
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

        // Avatar Lingkaran Bersih & Halus (Terkoneksi ke Edit Profil)
        GestureDetector(
          onTap: widget.isOwnProfile
              ? () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                }
              : null,
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
            child: ClipOval(
              child: widget.avatarUrl.isNotEmpty
                  ? (widget.avatarUrl.startsWith('assets/')
                      ? Image.asset(widget.avatarUrl, fit: BoxFit.cover)
                      : Image.network(
                          widget.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(isDark),
                        ))
                  : _buildFallbackAvatar(isDark),
            ),
          ),
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

        // Barisan Angka Metrik Sosial Murni (Mengikuti, Pengikut, Suka) - Unboxed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Buat Video (Langsung buka galeri pemilih video)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 1,
                        ),
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          try {
                            final picker = ImagePicker();
                            final XFile? picked = await picker.pickVideo(
                              source: ImageSource.gallery,
                              maxDuration: const Duration(minutes: 3),
                            );
                            if (!context.mounted) return;
                            if (picked != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AffiliateVideoUploadScreen(
                                    initialVideoPath: picked.path,
                                    initialVideoName: picked.name,
                                  ),
                                ),
                              );
                              return;
                            }
                          } catch (_) {}
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AffiliateVideoUploadScreen(),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.videocam_rounded, size: 17),
                        label: const Text(
                          'Buat Video',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
}
