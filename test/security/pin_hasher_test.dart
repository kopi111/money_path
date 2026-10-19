import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/security/pin_hasher.dart';

String hex(String base64Text) =>
    base64.decode(base64Text).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('matches the published PBKDF2-HMAC-SHA256 test vector', () async {
    final hash = await const PinHasher(iterations: 1).hash('password', utf8.encode('salt'));
    expect(hex(hash), '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
  });

  test('the right PIN matches its hash', () async {
    const hasher = PinHasher(iterations: 10);
    final hash = await hasher.hash('4821', [1, 2, 3]);
    expect(await hasher.matches('4821', [1, 2, 3], hash), isTrue);
  });

  test('a wrong PIN does not match', () async {
    const hasher = PinHasher(iterations: 10);
    final hash = await hasher.hash('4821', [1, 2, 3]);
    expect(await hasher.matches('4812', [1, 2, 3], hash), isFalse);
  });
}
