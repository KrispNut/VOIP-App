import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/home/controller.dart';
import '/core/constants/app_constants.dart';
import '/features/register/register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                const SizedBox(height: 32),
                _buildAvatar(homeCtrl.isRegistered),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    AppConstants.registeredUser ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildStatusToggle(homeCtrl),
                const SizedBox(height: 32),
                _buildLogoutButton(context, homeCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isOnline) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 80, color: Colors.orange),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(HomeController ctrl) {
    return GestureDetector(
      onTap: () => !ctrl.isRegistering ? ctrl.toggleRegistration() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: ctrl.isRegistered
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ctrl.isRegistered ? Colors.green : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctrl.isRegistering)
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              )
            else
              Text(
                ctrl.isRegistered ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: ctrl.isRegistered
                      ? Colors.greenAccent
                      : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, HomeController ctrl) {
    return ElevatedButton(
      onPressed: () async {
        await ctrl.logout();
        if (context.mounted) {
          AppConstants.navigate(
            context: context,
            const LoginScreen(),
            type: 'leftToRight',
            keep: false,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: const Text('Logout'),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
