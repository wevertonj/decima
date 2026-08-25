import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/ui/calculator/widgets/animated_input_display.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

class TimelineDisplay extends StatefulWidget {
  final List<Calculation> entries;
  final String displayText;
  final String? previewResult;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final TextEditingController displayController;
  final int? cursorPosition;
  final void Function(int index)? onCharTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTapOutside;

  const TimelineDisplay({
    super.key,
    required this.entries,
    required this.displayText,
    required this.previewResult,
    required this.hasMore,
    required this.onLoadMore,
    required this.displayController,
    this.cursorPosition,
    this.onCharTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTapOutside,
  });

  @override
  State<TimelineDisplay> createState() => _TimelineDisplayState();
}

class _TimelineDisplayState extends State<TimelineDisplay>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _entryAnimController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  int _previousEntryCount = 0;

  @override
  void initState() {
    super.initState();
    _previousEntryCount = widget.entries.length;

    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fadeAnimation = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant TimelineDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.displayText != oldWidget.displayText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    if (widget.entries.length > _previousEntryCount) {
      _entryAnimController.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _previousEntryCount = widget.entries.length;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // ListView reverso ancora o conteúdo embaixo: entrada atual primeiro,
    // depois as entradas passadas (recente → antiga) e o load more no fim.
    final reversedEntries = widget.entries.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.padding.large,
        vertical: AppLayout.padding.medium,
      ),
      itemCount: reversedEntries.length + 1 + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Índice 0 = entrada atual (embaixo, por causa do reverse).
        if (index == 0) {
          return _buildCurrentInput(colors);
        }

        final entryIndex = index - 1;
        if (entryIndex < reversedEntries.length) {
          final child = _buildPastEntry(reversedEntries[entryIndex], colors);

          // Só a entrada mais recente anima.
          if (entryIndex == 0) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(opacity: _fadeAnimation, child: child),
            );
          }

          return child;
        }

        return _buildLoadMoreButton(colors);
      },
    );
  }

  Widget _buildLoadMoreButton(ColorScheme colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.spacing.medium),
      child: Center(
        child: GestureDetector(
          onTap: widget.onLoadMore,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.padding.medium,
              vertical: AppLayout.padding.small,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppLayout.radius.large),
            ),
            child: Text(
              context.l10n.loadMore,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastEntry(Calculation entry, ColorScheme colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.spacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            entry.expression,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.4),
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
          Text(
            entry.result,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  static const double _baseFontSize = 48;
  static const double _midFontSize = 36;
  static const double _smallFontSize = 28;

  Widget _buildCurrentInput(ColorScheme colors) {
    final hasPreview = widget.previewResult != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // O GestureDetector envolve SÓ a área da expressão: toque no vazio
        // ao redor dela move o cursor para o fim; toque na linha de prévia
        // abaixo é ignorado.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTapOutside,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -200) {
              widget.onSwipeLeft?.call();
            } else if (v > 200) {
              widget.onSwipeRight?.call();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final (:fontSize, :multiline) = _calculateFontLayout(
                widget.displayText,
                constraints.maxWidth,
                FontWeight.w300,
              );

              return SizedBox(
                width: double.infinity,
                child: AnimatedInputDisplay(
                  text: widget.displayText,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  textColor: colors.onSurface,

                  operatorColor: colors.primary,
                  multiline: multiline,
                  cursorPosition: widget.cursorPosition,
                  cursorColor: colors.primary,
                  onCharTap: widget.onCharTap,
                ),
              );
            },
          ),
        ),
        // Linha de prévia — espaço sempre reservado, nunca ocupado pelo
        // cálculo.
        Padding(
          padding: EdgeInsets.only(
            top: AppLayout.spacing.xs,
            bottom: AppLayout.spacing.small,
          ),
          child: AnimatedOpacity(
            opacity: hasPreview ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuart,
            child: Text(
              hasPreview ? widget.previewResult! : '',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.35),
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  /// Limiar que reduz a fonte antes de o texto alcançar a borda.
  static const double _shrinkThreshold = 0.88;

  ({double fontSize, bool multiline}) _calculateFontLayout(
    String text,
    double maxWidth,
    FontWeight fontWeight,
  ) {
    final threshold = maxWidth * _shrinkThreshold;

    for (final size in [_baseFontSize, _midFontSize]) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: fontWeight),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      if (painter.width <= threshold) {
        return (fontSize: size, multiline: false);
      }
    }

    // Na menor fonte, verifica se ainda cabe em uma linha.
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: _smallFontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    if (painter.width <= maxWidth) {
      return (fontSize: _smallFontSize, multiline: false);
    }

    // Multilinha só na menor fonte.
    return (fontSize: _smallFontSize, multiline: true);
  }
}
