import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256, so a copied PIN hash cannot be reversed by trying
/// every PIN quickly.
class PinHasher {
  const PinHasher({this.iterations = 120000});

  final int iterations;

  Future<String> hash(String pin, List<int> salt) =>
      Isolate.run(() => _pbkdf2(utf8.encode(pin), salt, iterations));

  /// Compares in constant time so timing reveals nothing about the PIN.
  Future<bool> matches(String pin, List<int> salt, String expectedHash) async {
    final actual = await hash(pin, salt);
    if (actual.length != expectedHash.length) return false;
    var difference = 0;
    for (var index = 0; index < actual.length; index++) {
      difference |= actual.codeUnitAt(index) ^ expectedHash.codeUnitAt(index);
    }
    return difference == 0;
  }
}

String _pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  final firstBlockSalt = Uint8List.fromList([...salt, 0, 0, 0, 1]);
  var block = hmac.convert(firstBlockSalt).bytes;
  final result = Uint8List.fromList(block);
  for (var round = 1; round < iterations; round++) {
    block = hmac.convert(block).bytes;
    for (var index = 0; index < result.length; index++) {
      result[index] ^= block[index];
    }
  }
  return base64.encode(result);
}
