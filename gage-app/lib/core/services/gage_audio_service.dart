import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Lightweight self-contained audio service for voice notes and in-app sound effects.
/// Generates clean PCM WAV audio in-memory so it works 100% offline without missing asset files.
class GageAudioService {
  GageAudioService._();
  static final GageAudioService instance = GageAudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingId => _currentlyPlayingId;

  /// Generate a valid 16-bit Mono WAV in memory.
  static Uint8List createWav({
    required int sampleRate,
    required double durationSec,
    required double Function(double t) waveform,
  }) {
    final int numSamples = (sampleRate * durationSec).toInt();
    final int byteLength = numSamples * 2;
    final ByteData bd = ByteData(44 + byteLength);

    // RIFF header
    bd.setUint8(0, 0x52); // 'R'
    bd.setUint8(1, 0x49); // 'I'
    bd.setUint8(2, 0x46); // 'F'
    bd.setUint8(3, 0x46); // 'F'
    bd.setUint32(4, 36 + byteLength, Endian.little);
    bd.setUint8(8, 0x57);  // 'W'
    bd.setUint8(9, 0x41);  // 'A'
    bd.setUint8(10, 0x56); // 'V'
    bd.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    bd.setUint8(12, 0x66); // 'f'
    bd.setUint8(13, 0x6D); // 'm'
    bd.setUint8(14, 0x74); // 't'
    bd.setUint8(15, 0x20); // ' '
    bd.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    bd.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    bd.setUint16(22, 1, Endian.little);  // NumChannels (1 mono)
    bd.setUint32(24, sampleRate, Endian.little); // SampleRate
    bd.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    bd.setUint16(32, 2, Endian.little);  // BlockAlign
    bd.setUint16(34, 16, Endian.little); // BitsPerSample (16)

    // data subchunk
    bd.setUint8(36, 0x64); // 'd'
    bd.setUint8(37, 0x61); // 'a'
    bd.setUint8(38, 0x74); // 't'
    bd.setUint8(39, 0x61); // 'a'
    bd.setUint32(40, byteLength, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double sample = waveform(t).clamp(-1.0, 1.0);
      final int intSample = (sample * 32767).toInt().clamp(-32768, 32767);
      bd.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return bd.buffer.asUint8List();
  }

  /// Play a recording start chime (880Hz -> 1320Hz double beep).
  Future<void> playRecordStartChime() async {
    try {
      final wav = createWav(
        sampleRate: 22050,
        durationSec: 0.18,
        waveform: (t) {
          final freq = t < 0.08 ? 880.0 : 1320.0;
          final env = 1.0 - (t / 0.18);
          return sin(2 * pi * freq * t) * 0.35 * env;
        },
      );
      await _player.stop();
      await _player.play(BytesSource(wav));
    } catch (e) {
      debugPrint('[GageAudio] playRecordStartChime error: $e');
    }
  }

  /// Play a realistic voice message audio clip through the phone's speaker.
  /// Modulates voice frequencies (~200Hz - 600Hz) with human-like cadence.
  Future<void> playVoiceNote({
    required String voiceNoteId,
    double durationSeconds = 3.0,
    VoidCallback? onComplete,
  }) async {
    try {
      if (_isPlaying && _currentlyPlayingId == voiceNoteId) {
        await stopVoiceNote();
        return;
      }

      await _player.stop();
      _isPlaying = true;
      _currentlyPlayingId = voiceNoteId;

      final wav = createWav(
        sampleRate: 22050,
        durationSec: durationSeconds,
        waveform: (t) {
          // Voice fundamental and harmonics
          final double f0 = 220.0 + 30.0 * sin(2 * pi * 2.5 * t);
          final double h1 = sin(2 * pi * f0 * t) * 0.4;
          final double h2 = sin(2 * pi * (f0 * 2) * t) * 0.25;
          final double h3 = sin(2 * pi * (f0 * 3) * t) * 0.15;
          
          // Speech cadence envelope (simulates word pauses and natural flow)
          final double cadence = (0.5 + 0.5 * sin(2 * pi * 3.0 * t)).clamp(0.1, 1.0);
          final double fade = (t < 0.05) ? (t / 0.05) : ((durationSeconds - t < 0.05) ? (durationSeconds - t) / 0.05 : 1.0);

          return (h1 + h2 + h3) * cadence * fade * 0.65;
        },
      );

      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentlyPlayingId = null;
        if (onComplete != null) onComplete();
      });

      await _player.play(BytesSource(wav));
    } catch (e) {
      debugPrint('[GageAudio] playVoiceNote error: $e');
      _isPlaying = false;
      _currentlyPlayingId = null;
    }
  }

  /// Stop current playback.
  Future<void> stopVoiceNote() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentlyPlayingId = null;
    } catch (e) {
      debugPrint('[GageAudio] stopVoiceNote error: $e');
    }
  }
}
