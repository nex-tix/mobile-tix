// File: audio_feedback_service.dart
// Service untuk feedback audio (beep) dan getar (haptic) saat scan tiket.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import '../config/env_config.dart';

/// Mengelola umpan balik audio dan haptic saat tiket dipindai.
///
/// Membedakan hasil valid (beep 1x + getar halus) dari hasil ditolak
/// (beep 2x / peringatan + getar tegas).
class AudioFeedbackService {
  AudioFeedbackService._();

  static final AudioFeedbackService instance = AudioFeedbackService._();
  factory AudioFeedbackService() => instance;

  AudioPlayer? _player;
  bool _initialized = false;

  /// Inisialisasi audio player (opsional, lazy load saat pertama kali dipakai).
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _player = AudioPlayer();
      _initialized = true;
    } catch (e) {
      debugPrint('[AudioFeedbackService] Gagal inisialisasi AudioPlayer: $e');
    }
  }

  /// Umpan balik untuk tiket VALID: 1x nada sukses + haptic ringan.
  Future<void> playSuccess() async {
    if (!EnvConfig.enableAudioFeedback) return;

    // 1. Haptic feedback
    try {
      await HapticFeedback.lightImpact();
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 80, amplitude: 128);
      }
    } catch (_) {
      // Abaikan platform tanpa vibrator
    }

    // 2. Audio click / beep
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Abaikan jika tidak didukung
    }
  }

  /// Umpan balik untuk tiket REJECTED (used, expired, cancelled, not found):
  /// nada peringatan + haptic ganda/tegas.
  Future<void> playError() async {
    if (!EnvConfig.enableAudioFeedback) return;

    // 1. Haptic feedback ganda
    try {
      await HapticFeedback.heavyImpact();
      final hasPattern = await Vibration.hasCustomVibrationsSupport();
      if (hasPattern == true) {
        await Vibration.vibrate(
          pattern: [0, 120, 80, 120],
          intensities: [0, 255, 0, 255],
        );
      } else {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 250);
        }
      }
    } catch (_) {
      // Abaikan platform tanpa vibrator
    }

    // 2. Audio alert
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Fallback
    }
  }

  /// Bersihkan resource.
  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _initialized = false;
  }
}
