import '/generated/assets.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voip_app/features/splash/controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashController>().init(context);
    });

    return Scaffold(
      backgroundColor: Colors.amber,
      body: Center(child: Lottie.asset(Assets.lottie.user.path)),
    );
  }
}
