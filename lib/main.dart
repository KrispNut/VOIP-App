import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:voip_app/features/splash/controller.dart';

import 'firebase_options.dart';
import 'core/call_manager.dart';
import 'features/home/controller.dart';
import 'features/register/controller.dart';
import '/features/splash/splash.dart';
import '/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallManager()..init()),
        ChangeNotifierProxyProvider<CallManager, RegisterController>(
          create: (context) => RegisterController(
            callManager: Provider.of<CallManager>(context, listen: false),
          ),
          update: (context, callManager, previous) =>
              previous ?? RegisterController(callManager: callManager),
        ),
        ChangeNotifierProxyProvider<CallManager, SplashController>(
          create: (context) => SplashController(
            callManager: Provider.of<CallManager>(context, listen: false),
          ),
          update: (context, callManager, previous) =>
              previous ?? SplashController(callManager: callManager),
        ),
        ChangeNotifierProxyProvider<CallManager, HomeController>(
          create: (context) {
            final callManager = Provider.of<CallManager>(
              context,
              listen: false,
            );
            final homeCtrl = HomeController(callManager: callManager);
            homeCtrl.registerController = Provider.of<RegisterController>(
              context,
              listen: false,
            );
            return homeCtrl;
          },
          update: (context, callManager, previous) {
            final ctrl = previous ?? HomeController(callManager: callManager);
            ctrl.registerController = Provider.of<RegisterController>(
              context,
              listen: false,
            );
            return ctrl;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoIP App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      navigatorKey: AppConstants.navigatorKey,
      home: const SplashScreen(),
    );
  }
}
