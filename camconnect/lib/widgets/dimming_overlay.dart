import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that provides a dimming overlay over its child.
///
/// This widget displays a semi-transparent overlay over its child after a specified duration.
/// The overlay fades in gradually and can be dismissed by tapping on it.
class DimmingOverlay extends StatefulWidget {
  const DimmingOverlay({
    super.key,
    required this.child,
    required this.maxOpacity,
    required this.dimValueNotifier,
    this.dimAfter = const Duration(minutes: 2),
  }) : assert(maxOpacity >= 0.0 && maxOpacity <= 1.0);

  /// The widget over which the dimming overlay is applied.
  final Widget child;

  /// The maximum opacity of the overlay.
  final double maxOpacity;

  /// The duration after which the overlay should appear.
  final Duration dimAfter;

  /// A ValueNotifier<bool> that controls the visibility of the overlay.
  final ValueNotifier<bool> dimValueNotifier;

  @override
  State<DimmingOverlay> createState() => _DimmingOverlayState();
}

class _DimmingOverlayState extends State<DimmingOverlay> {
  Timer? _timer, _incrementTimer;
  Completer<bool>? _completer;

  double _opacity = 0.0;
  bool _dimScreen = false;
  static const _animationDuration = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    widget.dimValueNotifier.addListener(_onDimValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _cancelTimedOverlay();
    widget.dimValueNotifier.removeListener(_onDimValueChanged);
  }

  void _onDimValueChanged() {
    if (widget.dimValueNotifier.value == _dimScreen) {
      return; // ignore, already at it
    }
    _cancelTimedOverlay();
    if (widget.dimValueNotifier.value) {
      _showTimedOverlay();
    } else {
      setState(() => _dimScreen = false);
    }
  }

  void _showTimedOverlay() {
    _timer = Timer(widget.dimAfter, () async {
      _opacity = 0.2; // make initial dim noticeable
      setState(() => _dimScreen = true); // show overlay
      _incrementTimer?.cancel(); // cancel previous

      while (_dimScreen && _opacity < widget.maxOpacity) {
        setState(() => _opacity += 0.1);

        _completer = Completer<bool>();
        _incrementTimer = Timer(_animationDuration, () {
          if (!(_completer?.isCompleted ?? true)) {
            _completer?.complete(false);
          }
        });
        // stop changing opacity when completed with true.
        if (await _completer?.future ?? true) break;
      }
    });
  }

  void _cancelTimedOverlay() {
    _timer?.cancel();
    _incrementTimer?.cancel();
    if (!(_completer?.isCompleted ?? true)) {
      _completer?.complete(true);
    }
    _opacity = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_dimScreen)
        GestureDetector(
          onTap: () {
            _cancelTimedOverlay();
            _showTimedOverlay();
            setState(() => _dimScreen = false);
          },
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: _animationDuration,
            child: Container(color: Colors.black),
          ),
        ),
    ]);
  }
}
