import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../home/controller.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../home/widgets/call_views.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();
    final bool showNav = !ctrl.isIncoming && !ctrl.inCall;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: showNav
            ? Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 8,
                ),
                child: GNav(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  gap: 8,
                  activeColor: Colors.orange,
                  iconSize: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: Colors.grey.shade400.withValues(
                    alpha: 0.1,
                  ),
                  color: Colors.grey[300],
                  tabs: const [
                    GButton(icon: Icons.home, text: 'Home'),
                    GButton(icon: Icons.person, text: 'Profile'),
                  ],
                  selectedIndex: _currentIndex,
                  onTabChange: (index) => setState(() => _currentIndex = index),
                ),
              )
            : null,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _screens),
            // Overlay Call Views if a call is active or incoming
            if (!showNav)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: ctrl.isIncoming
                      ? IncomingCallView(ctrl: ctrl)
                      : ActiveCallView(ctrl: ctrl),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
