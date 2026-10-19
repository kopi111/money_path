import 'dart:async';

import 'package:flutter/foundation.dart';

import 'biometric_gate.dart';
import 'secret_store.dart';

enum AppLockState { checking, needsPin, locked, unlocked }

/// Owns whether the app is showing its contents. Locks on start, after the
/// app has been in the background too long, and after idle time in the app.
class LockController extends ChangeNotifier {
  LockController({required SecretStore secrets, required BiometricGate biometrics})
      : _secrets = secrets,
        _biometrics = biometrics;

  final SecretStore _secrets;
  final BiometricGate _biometrics;

  static const maxAttempts = 5;
  static const cooldown = Duration(seconds: 30);

  AppLockState _state = AppLockState.checking;
  int _failedAttempts = 0;
  DateTime _lockedOutUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _backgroundedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _idleTimer;
  Duration _autoLockAfter = const Duration(seconds: 60);

  AppLockState get state => _state;

  bool get isLockedOut => DateTime.now().isBefore(_lockedOutUntil);

  Duration get lockoutRemaining => _lockedOutUntil.difference(DateTime.now());

  Future<void> start() async {
    _state = await _secrets.hasPin() ? AppLockState.locked : AppLockState.needsPin;
    notifyListeners();
  }

  set autoLockAfter(Duration value) => _autoLockAfter = value;

  Future<void> choosePin(String pin) async {
    await _secrets.setPin(pin);
    _unlock();
  }

  /// True when the PIN was right.
  Future<bool> tryPin(String pin) async {
    if (isLockedOut) return false;
    if (await _secrets.checkPin(pin)) {
      _unlock();
      return true;
    }
    _recordFailure();
    return false;
  }

  Future<void> tryBiometrics() async {
    if (await _biometrics.confirmOwner()) _unlock();
  }

  /// Follows the owner's setting; off until they switch it on.
  bool biometricsEnabled = false;

  Future<bool> biometricsAvailable() async => biometricsEnabled && await _biometrics.isAvailable();

  Future<bool> deviceSupportsBiometrics() => _biometrics.isAvailable();

  Future<bool> confirmPinForChange(String pin) => _secrets.checkPin(pin);

  Future<void> changePin(String newPin) => _secrets.setPin(newPin);

  void lock() {
    if (_state != AppLockState.unlocked) return;
    _idleTimer?.cancel();
    _state = AppLockState.locked;
    notifyListeners();
  }

  void wentToBackground() => _backgroundedAt = DateTime.now();

  void cameBack() {
    if (DateTime.now().difference(_backgroundedAt) >= _autoLockAfter) lock();
  }

  /// Called on every touch; the app locks after [_autoLockAfter] without one.
  void noteActivity() {
    if (_state != AppLockState.unlocked) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_autoLockAfter, lock);
  }

  void _unlock() {
    _failedAttempts = 0;
    _state = AppLockState.unlocked;
    noteActivity();
    notifyListeners();
  }

  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _failedAttempts = 0;
      _lockedOutUntil = DateTime.now().add(cooldown);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
