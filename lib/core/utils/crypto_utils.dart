import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  CryptoUtils._();

  static const String _pinSalt = 'suki_pos_v2_salt_';
  static final RegExp _sha256HexRegex = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Returns true if [value] is already a 64-character SHA-256 hex digest.
  static bool isHashed(String value) {
    return _sha256HexRegex.hasMatch(value.trim());
  }

  /// Hashes a 6-digit PIN or password using salted SHA-256.
  /// If [pinOrHash] is already a 64-char SHA-256 digest, returns it as-is.
  static String hashPin(String pinOrHash) {
    final clean = pinOrHash.trim();
    if (clean.isEmpty) return '';
    if (isHashed(clean)) return clean.toLowerCase();

    final bytes = utf8.encode('$_pinSalt$clean');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
