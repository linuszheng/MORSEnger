import 'dart:io';

import 'package:flutter/services.dart';

const int speedUnit = 150;

longVibrate() {
  HapticFeedback.vibrate();
  sleep(
    const Duration(milliseconds: speedUnit * 4),
  );
}

shortVibrate() {
  HapticFeedback.heavyImpact();
  sleep(
    const Duration(milliseconds: speedUnit * 2),
  );
}

letterEnd() {
  sleep(
    const Duration(milliseconds: speedUnit * 2),
  );
}

wordEnd() {
  sleep(
    const Duration(milliseconds: speedUnit * 6),
  );
}

wordEndMinusLetterEnd() {
  sleep(
    const Duration(milliseconds: speedUnit * 4),
  );
}
