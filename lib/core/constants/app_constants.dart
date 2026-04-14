import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voip_app/core/shared_preference.dart';

class AppConstants {
  static String usernameCtrl = "";
  static String passwordCtrl = "";
  static String ipAddress = "192.168.100.101";

  static String? registeredUser;
  static String? fcmToken;

  /// When true, the app is handling a background FCM/CallKit recovery.
  /// Error handlers MUST NOT logout, stop SIP, or navigate to LoginScreen.
  static bool isInBackgroundRecovery = false;

  /// Silently restores user credentials from SharedPreferences into
  /// the volatile in-memory fields. Returns true if credentials were found.
  static Future<bool> restoreSession() async {
    debugPrint("[APP_LOG] Attempting silent session restore from SharedPreferences...");
    final creds = await SharedPref.getCredentials();
    if (creds.username != null && creds.username!.isNotEmpty) {
      registeredUser = creds.username;
      debugPrint("[APP_LOG] Session restored: registeredUser=${creds.username}");
      return true;
    }
    debugPrint("[APP_LOG] No saved credentials found for session restore.");
    return false;
  }
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<AudioPlayer> _buttonPlayers = List.generate(
    5,
    (index) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
  );
  static int _buttonPlayerIdx = 0;

  static final AudioPlayer _successPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> playButtonSound() async {
    try {
      final player = _buttonPlayers[_buttonPlayerIdx];
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.play(AssetSource('audio/button_press.mp3'));
      _buttonPlayerIdx = (_buttonPlayerIdx + 1) % _buttonPlayers.length;
    } catch (e) {
      debugPrint("Error playing button sound: $e");
    }
  }

  static Future<void> playSuccessSound() async {
    try {
      if (_successPlayer.state == PlayerState.playing) {
        await _successPlayer.stop();
      }
      await _successPlayer.play(AssetSource('audio/success.mp3'));
    } catch (e) {
      debugPrint("Error playing success sound: $e");
    }
  }

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showToast({String? title, String? message, bool? isError}) {
    final backgroundColor = isError == true
        ? Colors.red.shade800
        : (isError == false ? Colors.green.shade800 : Colors.grey.shade900);
    if (isError == false) playSuccessSound();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            Text(
              message ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void navigate(
    Widget page, {
    BuildContext? context,
    String type = 'rightToLeft',
    bool keep = false,
  }) {
    final navigator = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState;

    if (navigator == null) {
      debugPrint("❌ Navigation failed: No navigator available.");
      return;
    }

    Offset startOffset;

    switch (type) {
      case 'leftToRight':
        startOffset = const Offset(-1.0, 0.0);
        break;
      case 'bottomToTop':
        startOffset = const Offset(0.0, 1.0);
        break;
      case 'topToBottom':
        startOffset = const Offset(0.0, -1.0);
        break;
      case 'rightToLeft':
      default:
        startOffset = const Offset(1.0, 0.0);
        break;
    }

    final route = PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(
          begin: startOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(position: anim.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (keep) {
      navigator.push(route);
    } else {
      navigator.pushAndRemoveUntil(route, (_) => false);
    }
  }
}
