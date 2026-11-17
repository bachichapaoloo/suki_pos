import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils PIN Hashing Tests', () {
    test('hashes 6-digit PIN deterministically with SHA-256 salt', () {
      final hash1 = CryptoUtils.hashPin('050724');
      final hash2 = CryptoUtils.hashPin('050724');

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
      expect(
        hash1,
        equals('b20ffa13826016dbed1458d16511c7bc35243c5dd451c3f26e57ce7d84d77dd2'),
      );
      expect(CryptoUtils.isHashed(hash1), isTrue);
    });

    test('does not double-hash an already hashed SHA-256 digest', () {
      final digest = CryptoUtils.hashPin('123456');
      expect(CryptoUtils.hashPin(digest), equals(digest));
    });

    test('identifies plaintext PINs vs SHA-256 digests', () {
      expect(CryptoUtils.isHashed('050724'), isFalse);
      expect(CryptoUtils.isHashed('123456'), isFalse);
      expect(
        CryptoUtils.isHashed(
          'b20ffa13826016dbed1458d16511c7bc35243c5dd451c3f26e57ce7d84d77dd2',
        ),
        isTrue,
      );
    });
  });
}
