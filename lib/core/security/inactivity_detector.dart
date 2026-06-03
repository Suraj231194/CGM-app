import 'dart:async';

import 'package:flutter/widgets.dart';

/// Monitors user inactivity and triggers a callback (e.g., auto-logout)
/// after a specified timeout period.
///
/// Usage: Wrap your MaterialApp with [InactivityDetector].
class InactivityDetector extends StatefulWidget {
  const InactivityDetector({
    super.key,
    required this.child,
    required this.onTimeout,
    this.timeoutDuration = const Duration(minutes: 15),
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTimeout;
  final Duration timeoutDuration;
  final bool enabled;

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(InactivityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _resetTimer();
      } else {
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!widget.enabled) return;
    _timer = Timer(widget.timeoutDuration, widget.onTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
