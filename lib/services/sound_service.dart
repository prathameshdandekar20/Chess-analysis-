import 'package:flutter/services.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  void playMove() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void playCapture() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void playCheck() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    if (soundEnabled) SystemSound.play(SystemSoundType.alert);
  }

  void playBlunder() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }

  void playBrilliant() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
    }
  }
}
