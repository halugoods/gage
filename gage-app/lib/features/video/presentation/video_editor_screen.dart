import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:gage_app/core/services/gage_sound_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_video_upload_screen.dart';

/// Layar Video Editor Pra-Posting ala TikTok / Reels
/// Tempat memilih musik/sound pengiring & mengatur volume suara asli vs musik
class VideoEditorScreen extends StatefulWidget {
  final String videoPath;
  final String videoName;
  final Map<String, dynamic>? initialMerchant;
  final Map<String, dynamic>? initialProduct;
  final GageSound? initialSound;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    required this.videoName,
    this.initialMerchant,
    this.initialProduct,
    this.initialSound,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _videoCtrl;
  GageSound? _selectedSound;
  double _originalAudioVolume = 1.0;
  double _musicVolume = 1.0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.initialSound;

    if (widget.videoPath.isNotEmpty && File(widget.videoPath).existsSync()) {
      _videoCtrl = VideoPlayerController.file(File(widget.videoPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoCtrl?.setLooping(true);
            _videoCtrl?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _showSoundPickerSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSounds = GageSoundService.instance.sounds;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Musik / Suara',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (_selectedSound != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedSound = null);
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text(
                            'Hapus Musik',
                            style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: allSounds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final sound = allSounds[idx];
                      final isSelected = _selectedSound?.id == sound.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sound.albumArtUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFF334155),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                        title: Text(
                          sound.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? GageTheme.primary
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${sound.artist} • ${sound.duration}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? GageTheme.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            elevation: 0,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSound = sound);
                            Navigator.pop(sheetCtx);
                          },
                          child: Text(
                            isSelected ? 'Terpilih' : 'Gunakan',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVolumeMixerSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pengaturan Volume Suara',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 18),
                // Slider 1: Suara Asli Video
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suara Asli Video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${(_originalAudioVolume * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _originalAudioVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: GageTheme.primary,
                  onChanged: (val) {
                    setSheetState(() => _originalAudioVolume = val);
                    setState(() {
                      _originalAudioVolume = val;
                      _videoCtrl?.setVolume(val);
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Slider 2: Volume Musik Penambah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedSound != null ? 'Volume Musik (${_selectedSound!.title})' : 'Volume Musik Pengiring',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text('${(_musicVolume * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _musicVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: GageTheme.primary,
                  onChanged: (val) {
                    setSheetState(() => _musicVolume = val);
                    setState(() => _musicVolume = val);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNext() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AffiliateVideoUploadScreen(
          initialMerchant: widget.initialMerchant,
          initialProduct: widget.initialProduct,
          initialVideoPath: widget.videoPath,
          initialVideoName: widget.videoName,
          selectedSoundTitle: _selectedSound?.title,
          selectedSoundArtist: _selectedSound?.artist,
          originalAudioVolume: _originalAudioVolume,
          musicVolume: _musicVolume,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _videoCtrl != null && _videoCtrl!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Preview Area
          GestureDetector(
            onTap: () {
              if (_videoCtrl != null && isInitialized) {
                setState(() {
                  if (_videoCtrl!.value.isPlaying) {
                    _videoCtrl!.pause();
                    _isPlaying = false;
                  } else {
                    _videoCtrl!.play();
                    _isPlaying = true;
                  }
                });
              }
            },
            child: isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoCtrl!.value.size.width,
                      height: _videoCtrl!.value.size.height,
                      child: VideoPlayer(_videoCtrl!),
                    ),
                  )
                : Container(
                    color: const Color(0xFF0A0D12),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_library_rounded, color: Colors.white54, size: 48),
                          SizedBox(height: 12),
                          Text('Pratinjau Video Editor', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Play Indicator if Paused
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
              ),
            ),

          // 3. Top Navigation & Sound Picker Pill
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Close button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                // Sound Picker Pill
                InkWell(
                  onTap: _showSoundPickerSheet,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            _selectedSound != null ? _selectedSound!.title : 'Tambah Suara',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 38), // Balance for left close button
              ],
            ),
          ),

          // 4. Right Tool Buttons (Volume, Filters)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Column(
              children: [
                // Volume Mixer
                _buildEditorToolButton(
                  icon: Icons.tune_rounded,
                  label: 'Volume',
                  onTap: _showVolumeMixerSheet,
                ),
                const SizedBox(height: 18),
                // Efek / Filter
                _buildEditorToolButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Filter',
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),

          // 5. Bottom Navigation Bar: "Lanjut" (Next)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                onPressed: _handleNext,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lanjut',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
