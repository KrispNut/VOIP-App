import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/constants/app_constants.dart';
import '/core/widgets/custom_text_field.dart';
import '/features/base/base_screen.dart';
import '/features/register/controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final registerCtrl = context.watch<RegisterController>();
    debugPrint("[APP_LOG] LoginScreen build");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo(),
                  const SizedBox(height: 32),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your credentials to connect',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  CustomTextField(
                    controller: registerCtrl.usernameCtrl,
                    label: 'Username',
                    prefixIcon: Icons.person,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: registerCtrl.passwordCtrl,
                    label: 'Password',
                    prefixIcon: Icons.lock,
                    isPassword: false,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: registerCtrl.ipAddress,
                    label: 'Server IP',
                    prefixIcon: Icons.dns,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        debugPrint("[APP_LOG] Register button pressed");
                        await context
                            .read<RegisterController>()
                            .toggleRegister();
                        AppConstants.navigate(
                          context: context,
                          const BaseScreen(),
                          type: 'bottomToTop',
                          keep: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget logo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: const Icon(
        Icons.settings_input_component,
        color: Colors.orange,
        size: 40,
      ),
    );
  }
}
