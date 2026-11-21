import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/chat_hub_screen.dart';
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
  final VoidCallback? onChatTap;
  final VoidCallback? onCreateVideoTap;

  const CreatorProfileHeader({
    super.key,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    required this.bio,
    this.isVerified = false,
    this.isOwnProfile = true,
    this.targetId,
    this.onChatTap,
    this.onCreateVideoTap,
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
              child: _buildAvatarImage(isDark),
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

        // Barisan Tombol Aksi Utama (Chat Unboxed Icon + Buat Video Compact, Terpusat di Tengah)
        if (widget.isOwnProfile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Chat (Hanya Ikon Murni Tanpa Kontainer Box, Seragam dengan Header Beranda)
                IconButton(
                  tooltip: 'Pesan',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (widget.onChatTap != null) {
                      widget.onChatTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatHubScreen()),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.chat_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Buat Video (Kompak, Tidak Melebar Penuh)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 1,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onCreateVideoTap?.call();
                  },
                  icon: const Icon(Icons.video_call_rounded, size: 20),
                  label: const Text(
                    'Buat Video',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
                      isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
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
                    icon: const Icon(Icons.chat_bubble_rounded, size: 15),
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

  Widget _buildAvatarImage(bool isDark) {
    if (widget.avatarUrl.trim().isEmpty) {
      return _buildFallbackAvatar(isDark);
    }
    final trimmed = widget.avatarUrl.trim();
    if (trimmed.startsWith('assets/')) {
      return Image.asset(trimmed, fit: BoxFit.cover);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(isDark),
      );
    }
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return _buildFallbackAvatar(isDark);
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
