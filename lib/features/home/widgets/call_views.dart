import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../controller.dart';

// ==========================================
// 1. INCOMING CALL VIEW (Now with Pulse!)
// ==========================================
class IncomingCallView extends StatefulWidget {
  final HomeController ctrl;

  const IncomingCallView({super.key, required this.ctrl});

  @override
  State<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<IncomingCallView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Breathing/Pulsing animation for the caller avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                // Animated Pulsing Avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.orange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(
                                alpha: 0.3 * _pulseAnimation.value,
                              ),
                              blurRadius: 30 * _pulseAnimation.value,
                              spreadRadius: 10 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.orange,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                const Text(
                  'INCOMING CALL',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.ctrl.callerIdentity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            // Action Buttons with Haptics and Bounce
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBounceBtn(
                  icon: Icons.close,
                  label: 'Decline',
                  bgColor: Colors.transparent,
                  iconColor: Colors.white,
                  borderColor: Colors.white24,
                  onTap: widget.ctrl.declineCall,
                ),
                _ActionBounceBtn(
                  icon: Icons.phone,
                  label: 'Accept',
                  bgColor: Colors.orange,
                  iconColor: Colors.black,
                  borderColor: Colors.orange,
                  isPrimary: true,
                  onTap: widget.ctrl.answerCall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. ACTIVE CALL VIEW
// ==========================================
class ActiveCallView extends StatelessWidget {
  final HomeController ctrl;

  const ActiveCallView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RTCVideoView(
            ctrl.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: Colors.black,
                      child: RTCVideoView(
                        ctrl.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconBounceBtn(
                      icon: ctrl.isMuted ? Icons.mic_off : Icons.mic,
                      isActive: ctrl.isMuted,
                      onTap: ctrl.toggleMute,
                    ),
                    const SizedBox(width: 16),
                    _IconBounceBtn(
                      icon: ctrl.isOnHold ? Icons.pause : Icons.play_arrow,
                      isActive: ctrl.isOnHold,
                      onTap: ctrl.toggleHold,
                    ),
                    const SizedBox(width: 16),
                    _ActionBounceBtn(
                      icon: Icons.call_end,
                      label: '', // No label for bottom bar
                      bgColor: Colors.orange,
                      iconColor: Colors.black,
                      borderColor: Colors.orange,
                      isPrimary: true,
                      size: 64,
                      iconSize: 32,
                      onTap: ctrl.hangup,
                    ),
                    const SizedBox(width: 16),
                    _IconBounceBtn(
                      icon: ctrl.isSpeaker ? Icons.volume_up : Icons.hearing,
                      isActive: ctrl.isSpeaker,
                      onTap: ctrl.toggleSpeaker,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. REUSABLE ANIMATED COMPONENTS
// ==========================================

/// Large animated button for Accept, Decline, and Hangup
class _ActionBounceBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool isPrimary;
  final double size;
  final double iconSize;

  const _ActionBounceBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
    this.isPrimary = false,
    this.size = 72,
    this.iconSize = 36,
  });

  @override
  State<_ActionBounceBtn> createState() => _ActionBounceBtnState();
}

class _ActionBounceBtnState extends State<_ActionBounceBtn> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact(); // Tactile click when pressed
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0, // Shrinks smoothly on tap
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.bgColor,
                border: Border.all(color: widget.borderColor, width: 2),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: Colors.orange.withValues(
                            alpha: _isPressed ? 0.6 : 0.4,
                          ),
                          blurRadius: _isPressed ? 25 : 20,
                          spreadRadius: _isPressed ? 4 : 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: widget.iconSize,
              ),
            ),
            if (widget.label.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small animated toggle button for Mic, Hold, and Speaker
class _IconBounceBtn extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _IconBounceBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_IconBounceBtn> createState() => _IconBounceBtnState();
}

class _IconBounceBtnState extends State<_IconBounceBtn> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick(); // Different subtle haptic for toggles
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0, // Deep press feel
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive ? Colors.white : Colors.transparent,
            border: Border.all(
              color: widget.isActive ? Colors.white : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.isActive ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
