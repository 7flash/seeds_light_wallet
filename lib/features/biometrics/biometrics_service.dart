import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:seeds/features/biometrics/auth_commands.dart';
import 'package:seeds/features/biometrics/auth_type.dart';

class BiometricsService {
  final LocalAuthentication _localAuth;

  BiometricsService(LocalAuthentication localAuth) : _localAuth = localAuth;

  Future<bool> checkBiometrics() async {
    try {
      return _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  Future<bool> authenticate(AuthenticateCmd cmd) async {
    var androidAuthStrings;
    switch(cmd.type) {
      case AuthType.fingerprint:
        androidAuthStrings = AndroidAuthMessages(
          fingerprintHint: "Touch Sensor",
          signInTitle: "Fingerprint Authentication",
        );
        break;
      case AuthType.face:
        androidAuthStrings = AndroidAuthMessages(
          fingerprintHint: "Face Sensor",
          signInTitle: "Face Authentication",
        );
        break;
      default: {
        androidAuthStrings = AndroidAuthMessages(
          signInTitle: "Authenticate using biometric credentials",
        );
      }
    }

    try {
      return _localAuth.authenticateWithBiometrics(
          androidAuthStrings: androidAuthStrings,
          localizedReason: 'Use your device to authenticate',
          useErrorDialogs: false,
          stickyAuth: true);
    } on PlatformException catch (e) {
      print(e);
      return Future.error(e);
    }
  }

  Future<bool> cancelAuthentication() {
    try {
      return _localAuth.stopAuthentication();
    } catch (e) {
      print(e);
      return Future.error(e);
    }
  }
}
