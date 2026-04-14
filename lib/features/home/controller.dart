import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:voip_app/core/shared_preference.dart';
import '/core/call_manager.dart';
import '/features/register/controller.dart';
import '/core/constants/app_constants.dart';
import 'repository.dart';

class HomeController extends ChangeNotifier {
  final CallManager callManager;
  final HomeRepository homeRepo = HomeRepository();

  late RegisterController registerController;
  StreamSubscription? _sessionSub;

  TextEditingController extension = TextEditingController();
  String registrationStatus = 'Unregistered';
  bool isRegistered = false;
  bool isRegistering = false;
  bool _hasRetriedWakeup = false;
  int retryCount = 0;
  final int maxRetries = 3;
  Completer<CallStateEnum>? _pollCompleter;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool inCall = false;
  bool isIncoming = false;
  String callerIdentity = '';
  bool isSpeaker = false;
  bool isMuted = false;
  bool isOnHold = false;
  bool _pendingAutoAnswer = false;

  static const _proximityChannel = MethodChannel('com.bootlegcorp.voip/proximity');

  HomeController({required this.callManager}) {
    _initRenderers();
    _requestPermissions();
    _setupSipListeners();
    _listenToCallManager();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  // Listen to the BehaviorSubject from CallManager
  void _listenToCallManager() {
    _sessionSub = callManager.onCallSession.listen((session) {
      if (session != null) {
        debugPrint(
          "[APP_LOG] HomeController received call session. Processing...",
        );
        debugPrint(
          "[APP_LOG] data in Call listen: ${session.targetExt}\n ${session.callerExt}\n ${session.hostIp}",
        );
        autoRegisterAndCall(
          targetExt: session.targetExt,
          callerExt: session.callerExt,
          hostIp: session.hostIp,
        );
      }
    });
  }

  void setRegistering(bool value) {
    isRegistering = value;
    notifyListeners();
  }

  void _setupSipListeners() {
    callManager
        .sipHelper
        .onRegistrationStateChanged = (RegistrationState state) {
      isRegistered = state.state == RegistrationStateEnum.REGISTERED;
      isRegistering = false;
      registrationStatus = state.state.toString().split('.').last;
      notifyListeners();

      if (state.state == RegistrationStateEnum.REGISTERED) {
        print(
          "[SIP LOG] Registration Success: Registered as ${callManager.sipHelper.currentExtension}",
        );
        AppConstants.registeredUser = callManager.sipHelper.currentExtension;
        AppConstants.showToast(
          title: 'Registered',
          message: 'Successfully registered',
          isError: false,
        );
      } else if (state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
        print(
          "[SIP LOG] Registration Failed: ${state.cause?.reason_phrase ?? 'Unknown'}",
        );

        AppConstants.showToast(
          title: 'Registration Failed',
          message: state.cause?.reason_phrase ?? 'Unknown error',
          isError: true,
        );
      }
    };

    callManager.sipHelper.onCallStateChanged = (Call call, CallState state) {
      switch (state.state) {
        case CallStateEnum.CALL_INITIATION:
          if (call.direction == Direction.incoming) {
            String cleanExt =
                RegExp(
                  r'sip:([^@:]+)@',
                ).firstMatch(call.remote_identity ?? '')?.group(1) ??
                'Unknown';

            if (_pendingAutoAnswer) {
              print("[SIP LOG] Incoming Call: Auto-answering $cleanExt");
              _pendingAutoAnswer = false;
              Future.delayed(
                const Duration(milliseconds: 200),
                () => answerCall(),
              );
            } else {
              isIncoming = true;
              callerIdentity = call.remote_identity ?? 'Unknown';
              print("[SIP LOG] Incoming Call Alerting: From $cleanExt");
            }
          }
          break;

        case CallStateEnum.PROGRESS:
        case CallStateEnum.ACCEPTED:
          if (_pollCompleter != null && !_pollCompleter!.isCompleted) {
            _pollCompleter!.complete(state.state);
          }
          if (state.state == CallStateEnum.ACCEPTED) {
            isIncoming = false;
            inCall = true;
            print("[SIP LOG] Call Accepted: Conversation active.");
            _tryProximity('acquireProximityWakeLock');
          }
          break;

        case CallStateEnum.STREAM:
          print(
            "[SIP LOG] Media Stream: ${state.originator == Originator.remote ? 'Remote' : 'Local'} stream received.",
          );
          if (state.originator == Originator.remote) {
            remoteRenderer.srcObject = state.stream;
          } else {
            localRenderer.srcObject = state.stream;
          }
          break;

        case CallStateEnum.ENDED:
          print("[SIP LOG] Call Ended: Session closed normally.");
          _resetCallState();
          _tryProximity('releaseProximityWakeLock');
          break;

        case CallStateEnum.FAILED:
          final statusCode = state.cause?.status_code;
          print(
            "[SIP LOG] Call Failed. Code: $statusCode, Reason: ${state.cause?.reason_phrase}",
          );
          if (_pollCompleter != null && !_pollCompleter!.isCompleted) {
            _pollCompleter!.complete(state.state);
            return; // Skip drawing UI errors, let the loop handle it
          }

          bool isOfflineCode =
              (statusCode == 480 || statusCode == 404 || statusCode == 408);

          if (isOfflineCode && !_hasRetriedWakeup) {
            _runMicroPolling(extension.text);
          } else {
            // Second failure OR non-offline error: give up
            if (_hasRetriedWakeup) {
              AppConstants.showToast(
                title: 'Unavailable',
                message: 'User could not be reached after wake-up attempt.',
                isError: true,
              );
            } else {
              AppConstants.showToast(
                title: 'Call Failed',
                message: state.cause?.reason_phrase ?? 'Unknown error',
                isError: true,
              );
            }

            _resetCallState();
            _tryProximity('releaseProximityWakeLock');
          }
          break;

        default:
          break;
      }
      notifyListeners();
    };
  }

  void toggleRegistration() async {
    if (isRegistered) {
      setRegistering(true);
      callManager.sipHelper.unregister();
      return;
    }
    setRegistering(true);

    await callManager.sipHelper.forceTeardown();

    final creds = await SharedPref.getCredentials();

    callManager.sipHelper.register(
      ext: creds.username ?? AppConstants.registeredUser ?? '',
      password: creds.password ?? '',
      hostIp: creds.hostIp ?? registerController.ipAddress.text,
    );
  }

  Future<void> makeCall({String? targetExt, bool isRetry = false}) async {
    final extToDial = targetExt ?? extension.text;

    if (extToDial.isEmpty) {
      AppConstants.showToast(
        title: 'Error',
        message: 'Enter an extension',
        isError: true,
      );
      return;
    }

    if (!isRegistered) {
      AppConstants.showToast(
        title: 'Error',
        message: 'You must be registered to make a call.',
        isError: true,
      );
      return;
    }

    // Fresh manual call: reset the retry flag
    if (!isRetry) {
      _hasRetriedWakeup = false;
      retryCount = 0;
      if (_pollCompleter != null && !_pollCompleter!.isCompleted) {
        _pollCompleter!.complete(CallStateEnum.FAILED);
      }
      _pollCompleter = null;
    }

    debugPrint(
      "[APP_LOG] Initiating SIP call to $extToDial (retry=$isRetry)...",
    );
    await callManager.sipHelper.makeCall(
      targetExt: extToDial,
      hostIp: AppConstants.ipAddress,
    );
  }

  Future<void> autoRegisterAndCall({
    required String targetExt,
    required String callerExt,
    required String hostIp,
  }) async {
    bool isNativeRegistered = callManager.sipHelper.isRegistered;
    bool isNativeConnected = callManager.sipHelper.sipHelper.connected;

    if (isNativeRegistered &&
        isNativeConnected &&
        callManager.sipHelper.currentExtension == targetExt) {
      debugPrint(
        "[APP_LOG] SIP UA already registered and active. Background isolate is handling the call.",
      );
      AppConstants.isInBackgroundRecovery = false;
      return;
    }

    final registered = await callManager.sipHelper.registerAndWait(
      ext: targetExt,
      password: callerExt,
      hostIp: hostIp,
    );

    if (registered) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (callManager.sipHelper.currentCall != null) {
        answerCall();
      } else {
        _pendingAutoAnswer = true;
      }
      notifyListeners();
    }

    // Recovery complete — clear the background flag
    AppConstants.isInBackgroundRecovery = false;
  }

  void declineCall() {
    callManager.sipHelper.hangup();
    isIncoming = false;
    notifyListeners();
  }

  Future<void> _runMicroPolling(String targetExt) async {
    print(
      "[APP_LOG] Target appears offline. Triggering micro-polling fallback...",
    );
    _hasRetriedWakeup = true; // Block standard Fallback

    // Step A
    if (retryCount == 0) {
      homeRepo.makeCall(ext: targetExt).catchError((e) {
        debugPrint("[APP_LOG] FCM API request failed: $e");
      });
    }

    // Step B
    while (retryCount < maxRetries) {
      // Step C
      print(
        "[APP_LOG] Polling attempt ${retryCount + 1}/$maxRetries. Waiting 3.5s...",
      );
      await Future.delayed(const Duration(milliseconds: 3500));

      // Step D
      print("[APP_LOG] Re-initiating SIP INVITE to $targetExt...");
      _pollCompleter = Completer<CallStateEnum>();
      callManager.sipHelper.makeCall(
        targetExt: targetExt,
        hostIp: AppConstants.ipAddress,
      );

      // Step E
      CallStateEnum newState = await _pollCompleter!.future;
      _pollCompleter = null;

      if (newState == CallStateEnum.PROGRESS ||
          newState == CallStateEnum.ACCEPTED) {
        print("[APP_LOG] Target answered the micro-poll!");
        return; // Break the loop
      } else {
        // failed with 404/408 etc.
        print("[APP_LOG] Micro-poll attempt ${retryCount + 1} failed.");
        callManager.sipHelper.currentCall?.hangup(); // clean up dead session
        retryCount++;
      }
    }

    // Exhausted retries
    print(
      "[APP_LOG] Exhausted all 3 micro-poll retries. Target never woke up.",
    );
    AppConstants.showToast(
      title: 'Unavailable',
      message: 'User could not be reached after wake-up attempt.',
      isError: true,
    );
    _resetCallState();
    _tryProximity('releaseProximityWakeLock');
  }

  void _resetCallState() {
    inCall = false;
    isIncoming = false;
    _pendingAutoAnswer = false;
    _hasRetriedWakeup = false;
    retryCount = 0;
    if (_pollCompleter != null && !_pollCompleter!.isCompleted) {
      _pollCompleter!.complete(CallStateEnum.FAILED);
    }
    _pollCompleter = null;
    remoteRenderer.srcObject = null;
    localRenderer.srcObject = null;
    notifyListeners();
  }

  void _tryProximity(String method) =>
      _proximityChannel.invokeMethod(method).catchError((_) {});

  void answerCall() {
    final currentCall = callManager.sipHelper.currentCall;
    if (currentCall != null) {
      if (currentCall.state != CallStateEnum.ACCEPTED &&
          currentCall.state != CallStateEnum.CONFIRMED) {
        try {
          callManager.sipHelper.answerCall();
        } catch (e) {
          debugPrint("[APP_LOG] Caught exception while answering call: $e");
        }
      } else {
        debugPrint(
          "[APP_LOG] Call already actively accepted. Skipping double answer.",
        );
      }
    }
    FlutterCallkitIncoming.endAllCalls();
    _pendingAutoAnswer = false;
    notifyListeners();
  }

  void hangup() {
    callManager.sipHelper.hangup();
    _resetCallState();
  }

  void toggleMute() {
    isMuted = !isMuted;
    callManager.sipHelper.toggleMute(isMuted);
    notifyListeners();
  }

  void toggleSpeaker() {
    isSpeaker = !isSpeaker;
    callManager.sipHelper.toggleSpeaker(isSpeaker);
    notifyListeners();
  }

  void toggleHold() {
    isOnHold = !isOnHold;
    callManager.sipHelper.toggleHold(isOnHold);
    notifyListeners();
  }

  Future<void> logout() async {
    callManager.sipHelper.unregister();
    isRegistering = false;
    isRegistered = false;
    _resetCallState();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
