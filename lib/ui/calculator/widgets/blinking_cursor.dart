import 'dart:async';

import 'package:flutter/material.dart';

/// Barra vertical piscante que marca o ponto de inserção no display.
///
/// O blink usa um [Timer] (não um [AnimationController]) para que widget
/// tests com `pumpAndSettle` não fiquem bloqueados pelo piscar contínuo.
class BlinkingCursor extends StatefulWidget {
  final double height;
  final Color color;

  const BlinkingCursor({super.key, required this.height, required this.color});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: SizedBox(
        width: 2,
        height: widget.height,
        child: _visible
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
