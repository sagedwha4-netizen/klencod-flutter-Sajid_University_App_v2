// PLACEHOLDER CONFIGURATION.
// Run `flutterfire configure` and replace this file with the generated
// firebase_options.dart before enabling FirebaseConfig.enabled.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static bool get isConfigured => false;

  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:android:replace_me',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project',
  );
}
