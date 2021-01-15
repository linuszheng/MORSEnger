import 'package:flash_chat/actions.dart';

class TiltHandler {
  static const int speedUnit = 150;

  String _tiltValues = '';

  int _curAccX = 0;
  int prevAccX = 0;
  int timeIdleX = 0;
  int accRightCount = 0;

  double anglePos = 0; // sum of gyro values
  double driftOffset = -.013; // default (value taken from my iphone)
  bool curUp = false;
  bool prevUp = false;
  double upTime = 0;
  bool upCounted = false;
  double downTime = 0;

  bool calibrating = false;
  double timestamp = 0;

  String getTiltValues() {
    return _tiltValues;
  }

  void startCalibrate() {
    calibrating = true;
    timestamp = 0;
    anglePos = 0;
  }

  bool isCalibrating() {
    return calibrating;
  }

  String getTimeDisplay() {
    if (!calibrating) return 'START';
    int timeRounded = 10 - (timestamp / 100).floor();
    return timeRounded.toString();
  }

  void calibrate(double gyroX) {
    anglePos += gyroX;
    timestamp++;
    print(anglePos);
    if (timestamp == 1000) {
      calibrating = false;
      driftOffset = -anglePos / timestamp;
      print('NEW DRIFT OFFSET: $driftOffset');
      anglePos = 0;
    }
  }

  void reset() {
    _tiltValues = '';
  }

  void updateTyping(double gyroX) {
    anglePos += gyroX + driftOffset;
    print(anglePos);
    if (anglePos > 2)
      curUp = true;
    else
      curUp = false;
    if (!prevUp && curUp) {
      upTime = 0;
      upCounted = false;
    } else if (prevUp && curUp) {
      upTime++;
      if (!upCounted && upTime > 100) {
        upCounted = true;
        print('LONG');
        longVibrate();
        _tiltValues += '-';
      }
    } else if (prevUp && !curUp) {
      if (!upCounted) {
        print('SHORT');
        shortVibrate();
        _tiltValues += '.';
      }
      downTime = 0;
    } else {
      downTime++;
    }
    if (downTime == 200 &&
        _tiltValues != '' &&
        _tiltValues[_tiltValues.length - 1] != ' ') {
      print('SPACE');
      shortVibrate();
      _tiltValues += ' ';
    } else if (downTime == 400 &&
        _tiltValues != '' &&
        _tiltValues[_tiltValues.length - 2] != '/') {
      print('SLASH');
      longVibrate();
      _tiltValues += '/ ';
    }
    if (downTime == 2000 || upTime == 2000) {
      print('RESET');
      longVibrate();
      longVibrate();
      anglePos = 0; // reset
      downTime = 0;
      upTime = 0;
      prevUp = false;
    } else {
      prevUp = curUp;
    }
  }

  void updateBackspace(double accelX) async {}
}
