import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// A display that renders each character individually with animations:
/// - New characters pop-in (width 0 → target, pushing others left)
/// - Changed characters roll (old slides up, new slides up from below)
/// - Includes a blinking cursor at the end
class AnimatedInputDisplay extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color operatorColor;
  final bool multiline;
  final int? cursorPosition;
  final Color? cursorColor;
  final void Function(int index)? onCharTap;

  const AnimatedInputDisplay({
    super.key,
    required this.text,
    this.fontSize = 48,
    this.fontWeight = FontWeight.w300,
    required this.textColor,
    required this.operatorColor,
    this.multiline = false,
    this.cursorPosition,
    this.cursorColor,
    this.onCharTap,
  });

  @override
  State<AnimatedInputDisplay> createState() => _AnimatedInputDisplayState();
}

class _AnimatedInputDisplayState extends State<AnimatedInputDisplay> {
  final ScrollController _scrollController = ScrollController();
  List<_CharSlot> _slots = [];
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _slots = _buildSlots(widget.text, animate: false);
    _previousText = widget.text;
  }

  @override
  void didUpdateWidget(covariant AnimatedInputDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() {
        _slots = _diffAndBuildSlots(_previousText, widget.text);
        _previousText = widget.text;
      });
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // -- Diff logic --

  List<_CharSlot> _buildSlots(String text, {required bool animate}) {
    return [
      for (int i = 0; i < text.length; i++)
        _CharSlot(
          char: text[i],
          type: animate ? _AnimType.popIn : _AnimType.none,
        ),
    ];
  }

  List<_CharSlot> _diffAndBuildSlots(String oldText, String newText) {
    if (oldText.isEmpty) {
      return _buildSlots(newText, animate: true);
    }

    // Find common prefix
    int prefixLen = 0;
    final minLen = min(oldText.length, newText.length);
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Find common suffix (from remaining after prefix)
    int suffixLen = 0;
    final maxSuffix = minLen - prefixLen;
    while (suffixLen < maxSuffix &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final oldMiddleStart = prefixLen;
    final oldMiddleLen = oldText.length - suffixLen - prefixLen;

    final slots = <_CharSlot>[];

    for (int i = 0; i < newText.length; i++) {
      if (i < prefixLen || i >= newText.length - suffixLen) {
        // Common prefix or suffix — no animation
        slots.add(_CharSlot(char: newText[i], type: _AnimType.none));
      } else {
        final middleOffset = i - prefixLen;
        if (middleOffset < oldMiddleLen) {
          final oldChar = oldText[oldMiddleStart + middleOffset];
          if (oldChar != newText[i]) {
            slots.add(
              _CharSlot(
                char: newText[i],
                oldChar: oldChar,
                type: _AnimType.roll,
              ),
            );
          } else {
            slots.add(_CharSlot(char: newText[i], type: _AnimType.none));
          }
        } else {
          // Extra character — pop in
          slots.add(_CharSlot(char: newText[i], type: _AnimType.popIn));
        }
      }
    }

    return slots;
  }

  /// Decai um slot animado para texto puro quando sua animação termina.
  ///
  /// Estado de repouso 100% [RichText] plano: wrappers de animação têm
  /// geometria própria (caixa do roll, ClipRect, Transform) que, em fontes
  /// com métricas diferentes das assumidas (ex: Segoe UI no Windows),
  /// deslocavam o glifo verticalmente em relação aos chars estáticos.
  void _markSettled(UniqueKey key) {
    if (!mounted) return;
    final index = _slots.indexWhere((slot) => slot.key == key);
    if (index < 0 || _slots[index].type == _AnimType.none) return;

    setState(() {
      _slots[index] = _CharSlot(char: _slots[index].char, type: _AnimType.none);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.fontSize),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedSize, _) {
        return _buildContent(animatedSize);
      },
    );
  }

  Widget _buildContent(double fontSize) {
    final charWidgets = <Widget>[
      for (int i = 0; i < _slots.length; i++)
        _wrapTappable(i, _buildChar(_slots[i], fontSize)),
    ];

    final cursorPos = widget.cursorPosition;

    if (widget.multiline) {
      final tokenWidgets = _groupIntoTokens(
        charWidgets,
        cursorPos: cursorPos,
        cursor: cursorPos != null ? _buildCursor(fontSize) : null,
      );

      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tokenWidgets,
      );
    }

    final children = <Widget>[];
    for (int i = 0; i < charWidgets.length; i++) {
      if (cursorPos != null && cursorPos == i) {
        children.add(_buildCursor(fontSize));
      }
      children.add(charWidgets[i]);
    }
    if (cursorPos != null && cursorPos >= charWidgets.length) {
      children.add(_buildCursor(fontSize));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _wrapTappable(int index, Widget child) {
    if (widget.onCharTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // onTapDown fires immediately for fast cursor placement.
      onTapDown: (_) => widget.onCharTap!(index),
      // Empty onTap claims the gesture arena so the surrounding
      // GestureDetector's onTap (e.g., "move cursor to end") does not
      // fire when a character is tapped.
      onTap: () {},
      child: child,
    );
  }

  Widget _buildCursor(double fontSize) {
    final color = widget.cursorColor ?? widget.textColor;

    return _BlinkingCursor(
      key: const ValueKey('display-cursor'),
      height: fontSize,
      color: color,
    );
  }

  Widget _buildChar(_CharSlot slot, double fontSize) {
    final isOperator = _isOperator(slot.char);
    final color = isOperator ? widget.operatorColor : widget.textColor;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: widget.fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    switch (slot.type) {
      case _AnimType.popIn:
        return _PopInChar(
          key: slot.key,
          char: slot.char,
          style: style,
          onSettled: () => _markSettled(slot.key),
        );
      case _AnimType.roll:
        return _RollingChar(
          key: slot.key,
          newChar: slot.char,
          oldChar: slot.oldChar!,
          style: style,
          onSettled: () => _markSettled(slot.key),
        );
      case _AnimType.none:
        return _charText(slot.char, style);
    }
  }

  static bool _isOperator(String char) {
    return char == '+' || char == '−' || char == '×' || char == '÷';
  }

  /// Groups individual character widgets into token rows so that Wrap
  /// only breaks between tokens (operators/spaces), never mid-number.
  ///
  /// When [cursor] is non-null, it is inserted at [cursorPos] — kept inside
  /// the current number group when possible (so the line never breaks
  /// between a digit and the cursor), or as its own token at boundaries.
  List<Widget> _groupIntoTokens(
    List<Widget> charWidgets, {
    int? cursorPos,
    Widget? cursor,
  }) {
    final tokens = <Widget>[];
    var currentGroup = <Widget>[];

    void flushGroup() {
      if (currentGroup.isNotEmpty) {
        tokens.add(Row(mainAxisSize: MainAxisSize.min, children: currentGroup));
        currentGroup = [];
      }
    }

    for (int i = 0; i < _slots.length; i++) {
      if (cursor != null && cursorPos == i) {
        // Cursor at this index: keep it attached to the next char if we're
        // inside (or about to start) a number group; otherwise emit as its
        // own token. Look-ahead: next char is part of a number → group it.
        final nextChar = _slots[i].char;
        final nextIsNumberLike = nextChar != ' ' && !_isOperator(nextChar);
        if (nextIsNumberLike || currentGroup.isNotEmpty) {
          currentGroup.add(cursor);
        } else {
          flushGroup();
          tokens.add(cursor);
        }
      }
      final char = _slots[i].char;
      if (char == ' ' || _isOperator(char)) {
        flushGroup();
        tokens.add(charWidgets[i]);
      } else {
        currentGroup.add(charWidgets[i]);
      }
    }

    // Cursor at end of text.
    if (cursor != null && cursorPos == _slots.length) {
      if (currentGroup.isNotEmpty) {
        currentGroup.add(cursor);
      } else {
        tokens.add(cursor);
      }
    }

    flushGroup();

    return tokens;
  }
}

/// Renders a single character using RichText to avoid being found by
/// `find.text()` in widget tests (prevents ambiguity with keypad buttons).
Widget _charText(String char, TextStyle style) {
  return RichText(
    text: TextSpan(text: char, style: style),
    textDirection: TextDirection.ltr,
  );
}

// -- Data classes --

enum _AnimType { none, popIn, roll }

class _CharSlot {
  final String char;
  final String? oldChar;
  final _AnimType type;
  final UniqueKey key;

  _CharSlot({required this.char, this.oldChar, required this.type})
    : key = UniqueKey();
}

// -- Animated character widgets --

double _measureCharWidth(String char, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: char, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  return painter.width;
}

class _PopInChar extends StatelessWidget {
  final String char;
  final TextStyle style;
  final VoidCallback? onSettled;

  const _PopInChar({
    super.key,
    required this.char,
    required this.style,
    this.onSettled,
  });

  @override
  Widget build(BuildContext context) {
    final targetWidth = _measureCharWidth(char, style);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      onEnd: onSettled,
      builder: (context, value, child) {
        return SizedBox(
          width: targetWidth * value,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 1.0,
              // heightFactor 1.0: sem ele, Align expande até o limite
              // vertical disponível e o glifo sai do centro da Row.
              heightFactor: 1.0,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + 0.5 * value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _charText(char, style),
    );
  }
}

class _RollingChar extends StatelessWidget {
  final String newChar;
  final String oldChar;
  final TextStyle style;
  final VoidCallback? onSettled;

  const _RollingChar({
    super.key,
    required this.newChar,
    required this.oldChar,
    required this.style,
    this.onSettled,
  });

  @override
  Widget build(BuildContext context) {
    final rollDistance = (style.fontSize ?? 48) * 0.5;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      onEnd: onSettled,
      builder: (context, value, _) {
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fantasma invisível: dá ao slot exatamente o mesmo box de
              // um char estático (qualquer fonte/métrica), eliminando
              // deslocamento vertical em relação aos vizinhos.
              Opacity(opacity: 0.0, child: _charText(newChar, style)),
              // Old char slides up and fades out
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, -value * rollDistance),
                  child: Opacity(
                    opacity: 1.0 - value,
                    child: Center(child: _charText(oldChar, style)),
                  ),
                ),
              ),
              // New char slides up from below
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, (1.0 - value) * rollDistance),
                  child: Opacity(
                    opacity: value,
                    child: Center(child: _charText(newChar, style)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Blinking vertical cursor used to indicate the current insertion point.
/// Uses a [Timer] (not an [AnimationController]) so widget tests using
/// `pumpAndSettle` are not blocked by the steady-state blink.
class _BlinkingCursor extends StatefulWidget {
  final double height;
  final Color color;

  const _BlinkingCursor({super.key, required this.height, required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> {
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
