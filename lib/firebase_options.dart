import 'package:firebase_core/firebase_core.dart';

class FirebaseOptionsProvider {
  static FirebaseOptions get currentPlatform {
    if (isAndroidPlatform()) {
      // Konfigurasi untuk platform Android
      return FirebaseOptions(
        appId: '',
        apiKey: ' ',
        projectId: '',
        messagingSenderId: '',
        storageBucket: '',
      );
    } else {
      // Konfigurasi untuk platform web
      return FirebaseOptions(
        appId: '',
        apiKey: '',
        projectId: '',
        messagingSenderId: '',
        storageBucket: '',
        authDomain: '',
        measurementId: '',
      );
    }
  }

  static bool isAndroidPlatform() {
    return true;
  }
}
