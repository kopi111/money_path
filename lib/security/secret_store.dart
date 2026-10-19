import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_hasher.dart';

/// Keeps the database key and the PIN hash in the Android Keystore-backed
/// secure storage, never in the database or in plain files.
class SecretStore {
  SecretStore({FlutterSecureStorage? storage, PinHasher hasher = const PinHasher()})
      : _storage = storage ?? const FlutterSecureStorage(),
        _hasher = hasher;

  final FlutterSecureStorage _storage;
  final PinHasher _hasher;

  static const _databaseKey = 'database_key';
  static const _pinHash = 'pin_hash';
  static const _pinSalt = 'pin_salt';

  Future<String> databaseKey() async {
    final existing = await _storage.read(key: _databaseKey);
    if (existing != null) return existing;
    final created = _randomHex(32);
    await _storage.write(key: _databaseKey, value: created);
    return created;
  }

  Future<bool> hasPin() async => await _storage.read(key: _pinHash) != null;

  Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    await _storage.write(key: _pinSalt, value: base64.encode(salt));
    await _storage.write(key: _pinHash, value: await _hasher.hash(pin, salt));
  }

  Future<bool> checkPin(String pin) async {
    final salt = await _storage.read(key: _pinSalt);
    final hash = await _storage.read(key: _pinHash);
    if (salt == null || hash == null) {
      throw StateError('No PIN has been set');
    }
    return _hasher.matches(pin, base64.decode(salt), hash);
  }
}

final _random = Random.secure();

List<int> _randomBytes(int count) => List<int>.generate(count, (_) => _random.nextInt(256));

String _randomHex(int byteCount) =>
    _randomBytes(byteCount).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
