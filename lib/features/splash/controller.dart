import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:voip_app/core/call_manager.dart';
import 'package:voip_app/core/shared_preference.dart';
import 'package:voip_app/features/base/base_screen.dart';
import '/core/constants/app_constants.dart';
import '/features/register/register_screen.dart';

class SplashController extends ChangeNotifier {
  bool _hasStarted = false;
  final CallManager callManager;
  StreamSubscription? sessionSubscription;
  Timer? _autoAnswerTimeout;

  SplashController({required this.callManager}) {
    listenToIncomingSessions();
  }

  void init(BuildContext context) async {
    if (_hasStarted) return;
    listenToIncomingSessions();
    _hasStarted = true;

    try {
      // 🔥 STEP 1: Check for active CallKit session FIRST
      var activeCalls = await FlutterCallkitIncoming.activeCalls();

      if (activeCalls is List && activeCalls.isNotEmpty) {
        debugPrint("[APP_LOG] Active CallKit session detected. Bypassing Login.");

        // Restore saved credentials silently
        await AppConstants.restoreSession();

        if (context.mounted) {
           AppConstants.navigate(
             context: context,
             const BaseScreen(),
             type: 'bottomToTop',
             keep: false,
           );
        }
        return;
      }

      await Future.delayed(const Duration(seconds: 2));

      final creds = await SharedPref.getCredentials();
      bool hasSession = creds.username != null && creds.username!.isNotEmpty;

      if (!context.mounted) return;

      if (hasSession) {
        AppConstants.navigate(
          context: context,
          const BaseScreen(),
          type: 'bottomToTop',
          keep: false,
        );
      } else {
        AppConstants.navigate(
          context: context,
          const LoginScreen(),
          type: 'bottomToTop',
          keep: false,
        );
      }
    } catch (e) {
      debugPrint("[APP_LOG] Splash init error: $e");
      if (context.mounted) {
        AppConstants.navigate(
          context: context,
          const LoginScreen(),
          type: 'bottomToTop',
          keep: false,
        );
      }
    }
  }

  void listenToIncomingSessions() {
    sessionSubscription = callManager.onCallSession.listen((session) async {
      if (session != null) {
        debugPrint(
          "SplashController: Received session data from stream! Registering...",
        );
        print("SplashController: callerExt: ${session.callerExt}");
        print("SplashController: targetExt: ${session.targetExt}");
        print("SplashController: hostIp: ${session.hostIp}");
        print("SplashController: autoAnswer: ${session.autoAnswerPending}");

        // Retrieve the saved password from SharedPreferences
        final savedPassword = await SharedPref.getPassword();

        // --- REGISTRATION GUARD ---
        bool registered = false;
        bool isAlreadyRegistered = callManager.sipHelper.isRegistered;
        bool isAlreadyConnected = callManager.sipHelper.sipHelper.connected;

        if (isAlreadyRegistered && isAlreadyConnected) {
          debugPrint("[APP_LOG] SIP UA already registered and active. Skipping UI registration.");
          registered = true;
        } else {
          // Use registerAndWait so we know when SIP registration completes
          registered = await callManager.sipHelper.registerAndWait(
            ext: session.targetExt, // The user receiving the call
            password: savedPassword ?? '', // Actual saved password
            hostIp: session.hostIp,
          );
        }

        debugPrint("[AutoAnswer] Registration result: $registered");

        // Auto-answer only if the user accepted from CallKit (cold boot)
        if (registered && session.autoAnswerPending) {

          // Start a 10-second safety timeout
          bool autoAnswerExpired = false;
          _autoAnswerTimeout?.cancel();
          _autoAnswerTimeout = Timer(const Duration(seconds: 10), () {
            debugPrint(
              "[AutoAnswer] Safety timeout: No INVITE received in 10s. "
              "Clearing auto-answer flag.",
            );
            autoAnswerExpired = true;
          });

          await _autoAnswerIncomingCall(
            onExpiredCheck: () => autoAnswerExpired,
          );

          // Clean up the timer regardless of outcome
          _autoAnswerTimeout?.cancel();
          _autoAnswerTimeout = null;
        }

        // Recovery complete — clear the background flag
        AppConstants.isInBackgroundRecovery = false;

        AppConstants.navigate(BaseScreen(), keep: false);
      }
    });
  }

  /// Waits for the incoming SIP INVITE, stabilizes WebRTC, then answers.
  Future<void> _autoAnswerIncomingCall({
    required bool Function() onExpiredCheck,
  }) async {
    debugPrint("[AutoAnswer] Waiting for incoming SIP INVITE...");

    final call = await callManager.sipHelper.waitForIncomingCall(
      timeout: const Duration(seconds: 10),
    );

    // Check if the safety timeout already expired
    if (onExpiredCheck()) {
      debugPrint("[AutoAnswer] Safety timeout already fired. Aborting.");
      return;
    }

    if (call == null) {
      debugPrint("[AutoAnswer] No incoming call received. Aborting.");
      return;
    }

    debugPrint("[AutoAnswer] Incoming call detected. Stabilizing WebRTC...");

    // Delay to let ICE candidates and WebSocket stabilize
    await Future.delayed(const Duration(milliseconds: 1500));

    // Safety check: make sure the call wasn't hung up during the delay
    if (callManager.sipHelper.currentCall == null) {
      debugPrint("[AutoAnswer] Call ended during stabilization. Aborting.");
      return;
    }

    // Final check before answering
    if (onExpiredCheck()) {
      debugPrint(
        "[AutoAnswer] Safety timeout fired during stabilization. Aborting.",
      );
      return;
    }

    debugPrint("[AutoAnswer] Answering call now.");
    callManager.sipHelper.answerCall();
  }
}
