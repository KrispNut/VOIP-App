import 'dart:async';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SIPHelper implements SipUaHelperListener {
  SIPUAHelper sipHelper = SIPUAHelper();

  Function(RegistrationState state)? onRegistrationStateChanged;
  Function(Call call, CallState state)? onCallStateChanged;
  Function(SIPMessageRequest msg)? onNewMessageReceived;
  Function(String message, bool isError)? onTransportEvent;

  Call? _currentCall;
  Call? get currentCall => _currentCall;
  String? _currentExtension;
  String? get currentExtension => _currentExtension;
  int? lastFailureCode;
  Completer<Call?>? _incomingCallCompleter;

  SIPHelper() {
    sipHelper.addSipUaHelperListener(this);
  }

  Future<void> forceTeardown() async {
    try {
      sipHelper.unregister();
      sipHelper.stop();
    } catch (e) {
      debugPrint("[APP_LOG] Teardown exception swallowed: $e");
    }

    // 🔥 ALWAYS wait — regardless of state
    await Future.delayed(const Duration(seconds: 3));

    // 🔥 HARD RESET — destroy ghost UA instance
    sipHelper = SIPUAHelper();
    sipHelper.addSipUaHelperListener(this);
  }

  void register({
    required String ext,
    required String password,
    required String hostIp,
  }) {
    UaSettings settings = UaSettings();
    settings.webSocketUrl = 'wss://$hostIp:8089/ws';
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = 'sip:$ext@$hostIp';
    settings.authorizationUser = ext;
    settings.password = password;
    settings.displayName = ext;
    settings.userAgent = 'Flutter SIP UA';
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.transportType = TransportType.WS;

    // ICE/STUN servers for proper NAT traversal
    settings.iceServers = [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];

    _currentExtension = ext;
    sipHelper.start(settings);
  }

  Future<bool> registerAndWait({
    required String ext,
    required String password,
    required String hostIp,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint("START registerAndWait: ext=$ext, host=$hostIp");

    await forceTeardown();

    final completer = Completer<bool>();
    final tempListener = _TempRegistrationListener(completer);

    sipHelper.addSipUaHelperListener(tempListener);
    register(ext: ext, password: password, hostIp: hostIp);

    return completer.future
        .timeout(
          timeout,
          onTimeout: () {
            debugPrint("Registration TIMEOUT reached for $ext");
            return false;
          },
        )
        .whenComplete(() {
          sipHelper.removeSipUaHelperListener(tempListener);
        });
  }

  void unregister() {
    sipHelper.stop();
    _currentExtension = null;
  }

  bool get isRegistered {
    return sipHelper.registered;
  }

  Future<bool> makeCall({
    required String targetExt,
    required String hostIp,
    bool isVideo = false,
  }) async {
    try {
      await sipHelper.call('sip:$targetExt@$hostIp', voiceOnly: !isVideo);
      return true;
    } catch (e) {
      debugPrint('Error making call: $e');
      return false;
    }
  }

  void sendMessage(String target, String body) {
    try {
      sipHelper.sendMessage(target, body);
    } catch (e) {
      debugPrint('Error sending SIP MESSAGE to $target: $e');
    }
  }

  void hangup() {
    try {
      _currentCall?.hangup();
    } catch (e) {
      debugPrint('Error during hangup (safe to ignore): $e');
    } finally {
      _currentCall = null;
    }
  }

  void cleanupMedia() {
    if (_currentCall != null && _currentCall!.peerConnection != null) {
      for (var stream in _currentCall!.peerConnection!.getLocalStreams()) {
        if (stream != null) {
          for (var track in stream.getTracks()) {
            track.stop();
          }
        }
      }
    }
  }

  void answerCall() {
    if (_currentCall != null) {
      _currentCall!.answer(sipHelper.buildCallOptions(true));
    }
  }

  /// Waits for an incoming SIP INVITE after registration.
  /// Returns the Call object, or null on timeout.
  Future<Call?> waitForIncomingCall({
    Duration timeout = const Duration(seconds: 15),
  }) {
    // If there's already an incoming call queued, return it immediately
    if (_currentCall != null) {
      return Future.value(_currentCall);
    }

    _incomingCallCompleter = Completer<Call?>();
    return _incomingCallCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint("[AutoAnswer] Timed out waiting for incoming SIP INVITE.");
        _incomingCallCompleter = null;
        return null;
      },
    );
  }

  void toggleMute(bool isMuted) {
    if (_currentCall != null) {
      if (isMuted) {
        _currentCall!.mute(true, false);
      } else {
        _currentCall!.unmute(true, false);
      }
    }
  }

  void toggleHold(bool onHold) {
    if (_currentCall != null) {
      if (onHold) {
        _currentCall!.hold();
      } else {
        _currentCall!.unhold();
      }
    }
  }

  void toggleSpeaker(bool enabled) {
    Helper.setSpeakerphoneOn(enabled);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _currentCall = call;

    // Complete the incoming-call completer if someone is waiting
    if (_incomingCallCompleter != null &&
        !_incomingCallCompleter!.isCompleted &&
        (state.state == CallStateEnum.CALL_INITIATION ||
            state.state == CallStateEnum.PROGRESS)) {
      _incomingCallCompleter!.complete(call);
      _incomingCallCompleter = null;
    }

    if (state.state == CallStateEnum.ENDED ||
        state.state == CallStateEnum.FAILED) {
      if (state.state == CallStateEnum.FAILED) {
        lastFailureCode = state.cause?.status_code;
      }
      _currentCall = null;
    }

    onCallStateChanged?.call(call, state);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    onRegistrationStateChanged?.call(state);
  }

  @override
  void transportStateChanged(TransportState state) {
    if (state.state == TransportStateEnum.CONNECTED) {
      onTransportEvent?.call('WebSocket connected to server', false);
    } else if (state.state == TransportStateEnum.DISCONNECTED) {
      final reason = state.cause?.reason_phrase ?? 'Connection lost';
      onTransportEvent?.call('Disconnected: $reason', true);
    } else if (state.state == TransportStateEnum.CONNECTING) {
      onTransportEvent?.call('Connecting to server...', false);
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    onNewMessageReceived?.call(msg);
  }

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}
}

class _TempRegistrationListener implements SipUaHelperListener {
  final Completer<bool> completer;

  _TempRegistrationListener(this.completer);

  @override
  void registrationStateChanged(RegistrationState state) {
    if (!completer.isCompleted) {
      if (state.state == RegistrationStateEnum.REGISTERED) {
        completer.complete(true);
      } else if (state.state == RegistrationStateEnum.REGISTRATION_FAILED) {
        completer.complete(false);
      }
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void transportStateChanged(TransportState state) {}
}
