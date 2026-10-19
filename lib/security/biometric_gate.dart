import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps the fingerprint / face unlock plugin so its errors stay here.
class BiometricGate {
  BiometricGate({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// False when the owner cancels or the sensor fails; the PIN still works.
  Future<bool> confirmOwner() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Money Path',
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
