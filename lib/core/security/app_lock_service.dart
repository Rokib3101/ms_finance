import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService extends ChangeNotifier {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final LocalAuthentication _auth = LocalAuthentication();

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  AppLockService() {
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final pin = await _secureStorage.read(key: 'app_lock_pin');
    final bio = await _secureStorage.read(key: 'app_lock_biometric');
    _isPinSet = pin != null && pin.isNotEmpty;
    _biometricEnabled = bio == 'true';
    if (_isPinSet) {
      _isLocked = true;
    }
    notifyListeners();
  }

  Future<bool> isBiometricSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      await _secureStorage.write(key: 'app_lock_pin', value: pin);
      _isPinSet = true;
      _isLocked = false;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _secureStorage.read(key: 'app_lock_pin');
    if (storedPin == enteredPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: 'app_lock_pin');
    await _secureStorage.delete(key: 'app_lock_biometric');
    _isPinSet = false;
    _biometricEnabled = false;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _secureStorage.write(
        key: 'app_lock_biometric', value: enabled.toString());
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricEnabled) return false;
    try {
      final bool isSupported = await isBiometricSupported();
      if (!isSupported) return false;

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Personal Finance আনলক করতে আপনার পরিচয় নিশ্চিত করুন',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (didAuthenticate) {
        _isLocked = false;
        notifyListeners();
      }
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  void lockApp() {
    if (_isPinSet) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }
}
