import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:voip_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:rxdart/rxdart.dart'; // REQUIRED for Perfect Sync

import '/core/constants/app_constants.dart';
import '/core/shared_preference.dart';
import '/core/sip/sip_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // CRITICAL: Must be the first line. Without this, SharedPreferences
  // and other platform channels silently crash in the background isolate.
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("--- FCM DATA RECEIVED (Background) ---");
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print("Firebase data: ${message.data}");

  if (message.data['action'] == 'incoming_call') {
    // Mark the app as in background recovery mode
    AppConstants.isInBackgroundRecovery = true;

    // Retrieve persisted credentials (volatile memory is wiped on cold boot)
    final creds = await SharedPref.getCredentials();

    // Proactively restore in-memory session data
    await AppConstants.restoreSession();

    await CallManager.showCallkitIncoming(
      callerName: "Caller ${message.data['caller']}",
      callerExt: message.data['caller'] ?? 'Unknown',
      targetExt: message.data['handle'] ?? creds.username ?? 'Unknown',
      hostIp: message.data['host_ip'] ?? creds.hostIp ?? '',
    );
  }
}

class CallManager extends ChangeNotifier {
  final SIPHelper sipHelper = SIPHelper();

  final BehaviorSubject<MyCallSession?> _callSessionController =
      BehaviorSubject<MyCallSession?>();
  Stream<MyCallSession?> get onCallSession => _callSessionController.stream;

  bool _initialized = false;
  StreamSubscription? _callSub;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _setupMessaging();
    _listenToCallEvents();
    await _checkActiveCalls();
  }

  Future<void> _checkActiveCalls() async {
    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    if (activeCalls is List && activeCalls.isNotEmpty) {
      final callData = activeCalls.first;
      final extra = callData['extra'];

      if (extra != null) {
        debugPrint(
          "[APP_LOG] Cold Start: Found active call, buffering session...",
        );

        // Enter background recovery mode
        AppConstants.isInBackgroundRecovery = true;
        await AppConstants.restoreSession();

        // Retrieve persisted credentials for fallback
        final creds = await SharedPref.getCredentials();

        final session = MyCallSession(
          callerExt: extra['caller'] ?? 'Unknown',
          targetExt: extra['handle'] ?? creds.username ?? 'Unknown',
          hostIp: extra['host_ip'] ?? creds.hostIp ?? '',
          autoAnswerPending: true,
        );
        _callSessionController.add(session);
      }
    }
  }

  // ===================== FCM =====================

  Future<void> _setupMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await getPlatformToken();
    AppConstants.fcmToken = token ?? "";

    // Also persist the FCM token
    if (token != null) {
      await SharedPref.setFcmToken(token);
    }
    debugPrint("FCM TOKEN: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final tokenToSave = await getPlatformToken() ?? newToken;
      AppConstants.fcmToken = tokenToSave;
      await SharedPref.setFcmToken(tokenToSave);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data['action'] != 'incoming_call') return;

    // Retrieve persisted credentials for fallback
    final creds = await SharedPref.getCredentials();

    CallManager.showCallkitIncoming(
      callerName: "Caller ${message.data['caller']}",
      callerExt: message.data['caller'] ?? 'Unknown',
      targetExt: message.data['handle'] ?? creds.username ?? 'Unknown',
      hostIp: message.data['host_ip'] ?? creds.hostIp ?? '',
    );
  }

  Future<String?> getPlatformToken() async {
    return Platform.isIOS
        ? await FirebaseMessaging.instance.getAPNSToken()
        : await FirebaseMessaging.instance.getToken();
  }

  // ===================== CALLKIT =====================

  void _listenToCallEvents() {
    _callSub?.cancel();

    _callSub = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event?.event == Event.actionCallAccept) {
        final extra = event!.body['extra'];

        // Enter background recovery mode
        AppConstants.isInBackgroundRecovery = true;
        await AppConstants.restoreSession();

        // Retrieve persisted credentials for fallback
        final creds = await SharedPref.getCredentials();

        final session = MyCallSession(
          callerExt: extra['caller'] ?? 'Unknown',
          targetExt: extra['handle'] ?? creds.username ?? 'Unknown',
          hostIp: extra['host_ip'] ?? creds.hostIp ?? '',
          autoAnswerPending: true,
        );

        _callSessionController.add(session);
      } else if (event?.event == Event.actionCallDecline) {
        sipHelper.hangup();
        _callSessionController.add(null);
      }
    });
  }

  static Future<void> showCallkitIncoming({
    required String callerName,
    required String callerExt,
    required String targetExt,
    required String hostIp,
  }) async {
    final params = CallKitParams(
      id: const Uuid().v4(),
      nameCaller: callerName,
      appName: 'Sip Phone',
      extra: {'caller': callerExt, 'handle': targetExt, 'host_ip': hostIp},
      ios: const IOSParams(handleType: 'generic'),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  @override
  void dispose() {
    FlutterCallkitIncoming.endAllCalls();
    _callSub?.cancel();
    _callSessionController.close();
    super.dispose();
  }
}

class MyCallSession {
  final String callerExt;
  final String targetExt;
  final String hostIp;
  final bool autoAnswerPending;

  MyCallSession({
    required this.callerExt,
    required this.targetExt,
    required this.hostIp,
    this.autoAnswerPending = false,
  });
}
