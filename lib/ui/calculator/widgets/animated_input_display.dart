import 'package:decima/ui/calculator/char_slot_differ.dart';
import 'package:decima/ui/calculator/widgets/blinking_cursor.dart';
import 'package:flutter/material.dart';

/// A display that renders each character individually with animations:
/// - New characters pop-in (width 0 → target, pushing others left)
/// - Changed characters roll (old slides up, new slides up from below)
/// - Includes a blinking cursor at the end
///
/// O diff que decide qual caractere anima vive em [CharSlotDiffer];
/// o cursor piscante é o widget [BlinkingCursor]. Aqui ficam layout,
/// animação e scroll.
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
  List<CharSlot> _slots = [];
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _slots = CharSlotDiffer.build(widget.text, animate: false);
    _previousText = widget.text;
  }

  @override
  void didUpdateWidget(covariant AnimatedInputDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() {
        _slots = CharSlotDiffer.diff(_previousText, widget.text);
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

  /// Decai um slot animado para texto puro quando sua animação termina.
  ///
  /// Estado de repouso 100% [RichText] plano: wrappers de animação têm
  /// geometria própria (caixa do roll, ClipRect, Transform) que, em fontes
  /// com métricas diferentes das assumidas (ex: Segoe UI no Windows),
  /// deslocavam o glifo verticalmente em relação aos chars estáticos.
  void _markSettled(UniqueKey key) {
    if (!mounted) return;
    final index = _slots.indexWhere((slot) => slot.key == key);
    if (index < 0 || _slots[index].type == CharAnimType.none) return;

    setState(() {
      _slots[index] = CharSlotDiffer.settle(_slots[index]);
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

    return BlinkingCursor(
      key: const ValueKey('display-cursor'),
      height: fontSize,
      color: color,
    );
  }

  Widget _buildChar(CharSlot slot, double fontSize) {
    final isOperator = _isOperator(slot.char);
    final color = isOperator ? widget.operatorColor : widget.textColor;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: widget.fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    switch (slot.type) {
      case CharAnimType.popIn:
        return _PopInChar(
          key: slot.key,
          char: slot.char,
          style: style,
          onSettled: () => _markSettled(slot.key),
        );
      case CharAnimType.roll:
        return _RollingChar(
          key: slot.key,
          newChar: slot.char,
          oldChar: slot.oldChar!,
          style: style,
          onSettled: () => _markSettled(slot.key),
        );
      case CharAnimType.none:
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
