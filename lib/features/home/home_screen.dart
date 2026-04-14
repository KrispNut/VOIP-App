import 'controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _targetNumber = "";

  void _onKeypadTap(HomeController ctrl, String value) {
    if (value.isEmpty || _targetNumber.length >= 5) return;
    AppConstants.playButtonSound();
    setState(() {
      _targetNumber += value;
      ctrl.extension.text = _targetNumber;
    });
  }

  void _onBackspace(HomeController ctrl) {
    AppConstants.playButtonSound();
    if (_targetNumber.isNotEmpty) {
      setState(() {
        _targetNumber = _targetNumber.substring(0, _targetNumber.length - 1);
        ctrl.extension.text = _targetNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 24,
                      right: 24,
                    ),
                    child: Text(
                      _targetNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildRow(ctrl, ['1', '2', '3']),
                      _buildRow(ctrl, ['4', '5', '6']),
                      _buildRow(ctrl, ['7', '8', '9']),
                      _buildRow(ctrl, ['', '0', '']),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      _buildCallButton(ctrl),
                      _buildBackspaceButton(ctrl),
                    ],
                  ),
                ),
                const Text(
                  'AUDIO CALL',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            Positioned(
              top: 16,
              right: 34,
              child: _buildStatusBadge(ctrl.isRegistered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(HomeController ctrl, List<String> digits) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: digits.map((d) {
          if (d.isEmpty) {
            return const Expanded(child: SizedBox.shrink());
          }
          return Expanded(
            child: GlassDialButton(
              digit: d,
              onTap: () => _onKeypadTap(ctrl, d),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCallButton(HomeController ctrl) {
    return GestureDetector(
      onTap: () => ctrl.makeCall(),
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFE67E00)],
          ),
        ),
        child: const Icon(Icons.call, color: Colors.black, size: 36),
      ),
    );
  }

  Widget _buildBackspaceButton(HomeController ctrl) {
    return IconButton(
      icon: const Icon(Icons.backspace, color: Colors.grey, size: 48),
      onPressed: () => _onBackspace(ctrl),
      onLongPress: () => setState(() {
        _targetNumber = "";
        ctrl.extension.text = "";
      }),
    );
  }

  Widget _buildStatusBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.red,
          width: 0.5,
        ),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: isOnline ? Colors.greenAccent : Colors.redAccent,
          fontSize: 12,
        ),
      ),
    );
  }
}

class GlassDialButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const GlassDialButton({super.key, required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppConstants.playButtonSound();
        onTap();
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}
