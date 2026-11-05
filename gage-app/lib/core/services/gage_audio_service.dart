import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Lightweight self-contained audio service for physical voice recording and sound effects.
/// Uses 'record' package for real microphone recording to standard .m4a AAC audio,
/// and 'audioplayers' for crystal-clear playback.
class GageAudioService {
  GageAudioService._();
  static final GageAudioService instance = GageAudioService._();

  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isPlaying = false;
  bool _isRecording = false;
  String? _currentlyPlayingId;
  String? _currentRecordingPath;

  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;
  String? get currentlyPlayingId => _currentlyPlayingId;

  /// Start recording voice note from device microphone
  Future<bool> startRecording() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        debugPrint('[GageAudio] Microphone permission not granted');
        return false;
      }

      await playRecordStartChime();
      await Future.delayed(const Duration(milliseconds: 100));

      final tempDir = Directory.systemTemp.path;
      final filePath = '$tempDir/gage_vn_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = filePath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('[GageAudio] startRecording error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording voice note and return the saved .m4a file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await _recorder.stop();
      _isRecording = false;
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('[GageAudio] stopRecording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;
      }
    } catch (e) {
      debugPrint('[GageAudio] cancelRecording error: $e');
    }
  }

  /// Play a recorded audio file (.m4a / .aac / .wav)
  Future<void> playVoiceNoteFile({
    required String voiceNoteId,
    required String filePath,
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

      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentlyPlayingId = null;
        if (onComplete != null) onComplete();
      });

      final file = File(filePath);
      if (await file.exists()) {
        await _player.play(DeviceFileSource(filePath));
      } else {
        await playVoiceNote(voiceNoteId: voiceNoteId, onComplete: onComplete);
      }
    } catch (e) {
      debugPrint('[GageAudio] playVoiceNoteFile error: $e');
      await stopVoiceNote();
    }
  }

  /// Generate a valid 16-bit Mono WAV in memory for chimes/sound effects.
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
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);

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

  /// Play realistic natural voice note audio
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
          final double f0 = 180.0 + 20.0 * sin(2 * pi * 2.0 * t);
          final double h1 = sin(2 * pi * f0 * t) * 0.35;
          final double h2 = sin(2 * pi * (f0 * 2) * t) * 0.20;
          final double cadence = (0.6 + 0.4 * sin(2 * pi * 3.0 * t)).clamp(0.1, 1.0);
          final double fade = (t < 0.05) ? (t / 0.05) : ((durationSeconds - t < 0.05) ? (durationSeconds - t) / 0.05 : 1.0);
          return (h1 + h2) * cadence * fade * 0.55;
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
      await stopVoiceNote();
    }
  }

  /// Stop voice note playback immediately.
  Future<void> stopVoiceNote() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
    _currentlyPlayingId = null;
  }

  void dispose() {
    _player.dispose();
    _recorder.dispose();
  }
}
