import 'dart:async';
import '/core/call_manager.dart';
import 'package:flutter/material.dart';
import 'package:voip_app/core/shared_preference.dart';
import 'package:voip_app/features/register/model.dart';
import 'package:voip_app/core/constants/app_constants.dart';
import 'package:voip_app/features/register/repository.dart';

class RegisterController extends ChangeNotifier {
  final CallManager callManager;

  final TextEditingController usernameCtrl = TextEditingController(
    text: AppConstants.usernameCtrl,
  );
  final TextEditingController passwordCtrl = TextEditingController(
    text: AppConstants.passwordCtrl,
  );
  final TextEditingController ipAddress = TextEditingController(
    text: AppConstants.ipAddress,
  );
  RegisterController({required this.callManager});

  Future<void> toggleRegister() async {
    RegisterRepository repo = RegisterRepository();

    LoginResponse? loginResponse = await repo.register(
      username: usernameCtrl.text,
      password: passwordCtrl.text,
      token: AppConstants.fcmToken ?? '',
    );

    if (loginResponse != null &&
        loginResponse.success == true &&
        loginResponse.data != null) {
      print("Registration successful!");

      debugPrint(
        'Saving Credentials: '
        'Username: ${loginResponse.data?.extension}, '
        'Password: ${loginResponse.data?.extensionPassword}, '
        'Host IP: ${ipAddress.text}',
      );
      // ─── Persist credentials to SharedPreferences ───
      await SharedPref.saveCredentials(
        username: loginResponse.data!.extension,
        password: loginResponse.data!.extensionPassword,
        hostIp: ipAddress.text,
      );
      debugPrint("[PrefsHelper] Credentials saved to SharedPreferences.");

      // Teardown any ghost SIP instance, then re-read saved creds
      await callManager.sipHelper.forceTeardown();

      final savedCreds = await SharedPref.getCredentials();
      callManager.sipHelper.register(
        ext: savedCreds.username ?? '',
        password: savedCreds.password ?? '',
        hostIp: savedCreds.hostIp ?? ipAddress.text,
      );
    } else {
      print("Registration failed or returned null data.");
    }
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    ipAddress.dispose();
    super.dispose();
  }
}
