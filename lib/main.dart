import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart'; // Menggunakan file firebase_options.dart yang telah didefinisikan sebelumnya
import 'router/app_routes.dart';
import 'router/routes.dart';
import 'themes/colors.dart';
import 'package:firebase_core/firebase_core.dart'; // Menambahkan impor untuk Firebase Core
import 'package:firebase_auth/firebase_auth.dart'; // Menambahkan impor untuk Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Menambahkan impor untuk Cloud Firestore
import 'package:firebase_messaging/firebase_messaging.dart'; // Menambahkan impor untuk Firebase Messaging

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptionsProvider.currentPlatform, // Menggunakan opsi Firebase dari FirebaseOptionsProvider.currentPlatform
    name: 'app_name',
  );

  // Initialize App
  await initApp();

  // Initialize ScreenUtil
  await ScreenUtil.ensureScreenSize();

  // Run App
  runApp(
    MyApp(appRoute: AppRoute()),
  );
}

late String? initialRoute;

Future<void> initApp() async {
  final logger = Logger();
  final auth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance;

  // Compare Versions
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  DocumentSnapshot newestVersionDetails =
      await fireStore.collection('version').doc('newest').get();
  Version newestVersion = Version.parse(newestVersionDetails['version']);
  Version currentVersion = Version.parse(packageInfo.version);
  int compareResult = newestVersion.compareTo(currentVersion);
  if (compareResult > 0) {
    logger.i('New Version Available');
  }

  // Get initial user state
  User? user = auth.currentUser;

  if (compareResult == 0) {
    if (user == null || !user.emailVerified) {
      initialRoute = Routes.loginScreen;
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? localAuth = prefs.getBool('auth_screen_enabled') ?? false;
      initialRoute = localAuth == true ? Routes.authScreen : Routes.homeScreen;
    }
  } else {
    initialRoute = Routes.updateScreen;
  }

  // Request notification permission
  final message = FirebaseMessaging.instance;
  await message.requestPermission();

  // Listen for token refresh
  message.onTokenRefresh.listen(
    (fcmToken) {
      fireStore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .update({'mtoken': fcmToken});
    },
    onError: (err) {
      logger.e(err);
    },
  );

  // Listen for auth state changes
  auth.authStateChanges().listen(
    (user) async {
      if (compareResult == 0) {
        if (user == null || !user.emailVerified) {
          initialRoute = Routes.loginScreen;
        } else {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool? localAuth = prefs.getBool('auth_screen_enabled') ?? false;
          initialRoute = localAuth == true ? Routes.authScreen : Routes.homeScreen;
        }
      } else {
        initialRoute = Routes.updateScreen;
      }
    },
  );
}


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class MyApp extends StatefulWidget {
  final AppRoute appRoute;
  const MyApp({
    super.key,
    required this.appRoute,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        title: 'Chat App',
        theme: ThemeData(
          useMaterial3: true,
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: ColorsManager.greenPrimary,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: ColorsManager.greenPrimary,
          ),
          scaffoldBackgroundColor: ColorsManager.backgroundDefaultColor,
          appBarTheme: const AppBarTheme(
            foregroundColor: Colors.white,
            backgroundColor: ColorsManager.appBarBackgroundColor,
          ),
        ),
        onGenerateRoute: widget.appRoute.onGenerateRoute,
        initialRoute: initialRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
