import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageKeys {
  const SecureStorageKeys._();
  static const accessToken = 'auth.accessToken';
  static const refreshToken = 'auth.refreshToken';
}

class SecureStorage {
  SecureStorage(this._backing);

  final FlutterSecureStorage _backing;

  Future<String?> read(String key) => _backing.read(key: key);
  Future<void> write(String key, String value) => _backing.write(key: key, value: value);
  Future<void> delete(String key) => _backing.delete(key: key);
  Future<void> clear() => _backing.deleteAll();
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );
});
