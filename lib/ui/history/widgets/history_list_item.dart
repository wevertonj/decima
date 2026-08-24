import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// A single item in the history list showing a session preview.
///
/// Collapsed state: shows a preview of the full expression, final result,
/// line count badge, date, and favorite star.
///
/// Expanded state: shows all individual calculation lines. Tapping a
/// specific line triggers [onLineTap] with the line index.
class HistoryListItem extends StatefulWidget {
  final HistoryEntry entry;
  final ValueChanged<int> onLineTap;
  final VoidCallback onToggleFavorite;
  final ValueChanged<String?> onRename;

  const HistoryListItem({
    super.key,
    required this.entry,
    required this.onLineTap,
    required this.onToggleFavorite,
    required this.onRename,
  });

  @override
  State<HistoryListItem> createState() => _HistoryListItemState();
}

class _HistoryListItemState extends State<HistoryListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entry = widget.entry;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppLayout.padding.medium,
        vertical: AppLayout.padding.xs,
      ),
      color: colors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radius.medium),
      ),
      // O toque longo atende o mobile; o clique com o botão direito é o
      // equivalente esperado no desktop. `InkWell` só reconhece o botão
      // primário, então o botão secundário vem deste `GestureDetector`.
      child: GestureDetector(
        onSecondaryTap: () => _showRenameDialog(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppLayout.radius.medium),
          onTap: () {
            if (entry.lineCount == 1) {
              // Single-line session: tap goes straight to calculator.
              widget.onLineTap(0);
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
          onLongPress: () => _showRenameDialog(context),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(AppLayout.padding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: name, preview, favorite star
                  _buildHeader(colors, textTheme, entry),
                  // Collapsed: final result
                  if (!_expanded) ...[
                    SizedBox(height: AppLayout.spacing.small),
                    _buildFinalResult(colors, textTheme, entry),
                    SizedBox(height: AppLayout.spacing.xs),
                    _buildFooter(colors, textTheme, entry),
                  ],
                  // Expanded: all lines
                  if (_expanded) ...[
                    SizedBox(height: AppLayout.spacing.small),
                    _buildExpandedLines(colors, textTheme, entry),
                    SizedBox(height: AppLayout.spacing.xs),
                    _buildFooter(colors, textTheme, entry),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ColorScheme colors,
    TextTheme textTheme,
    HistoryEntry entry,
  ) {
    final previewExpr = entry.previewExpression;
    final truncated = previewExpr.length > 30
        ? '${previewExpr.substring(0, 27)}...'
        : previewExpr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.name != null && entry.name!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: AppLayout.spacing.xs),
                  child: Text(
                    entry.name!,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(
                truncated,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: AppLayout.spacing.small),
        // Line count badge (only for multi-line sessions)
        if (entry.lineCount > 1)
          Padding(
            padding: EdgeInsets.only(right: AppLayout.spacing.xs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.padding.small,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _expanded
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppLayout.radius.circular),
              ),
              child: Text(
                '${entry.lineCount}',
                style: textTheme.labelSmall?.copyWith(
                  color: _expanded
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Favorite toggle
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInBack,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              entry.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              key: ValueKey(entry.isFavorite),
              color: entry.isFavorite
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
          onPressed: widget.onToggleFavorite,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildFinalResult(
    ColorScheme colors,
    TextTheme textTheme,
    HistoryEntry entry,
  ) {
    return Text(
      '= ${entry.result}',
      style: textTheme.headlineSmall?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildExpandedLines(
    ColorScheme colors,
    TextTheme textTheme,
    HistoryEntry entry,
  ) {
    return Column(
      children: List.generate(entry.lines.length, (index) {
        final line = entry.lines[index];
        return _ExpandedLineItem(
          line: line,
          index: index,
          totalLines: entry.lines.length,
          onTap: () => widget.onLineTap(index),
        );
      }),
    );
  }

  Widget _buildFooter(
    ColorScheme colors,
    TextTheme textTheme,
    HistoryEntry entry,
  ) {
    return Text(
      _formatDateTime(entry.createdAt),
      style: textTheme.bodySmall?.copyWith(
        color: colors.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: widget.entry.name ?? '');

    showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.renameHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text);
            },
            child: Text(l10n.renameSave),
          ),
        ],
      ),
    ).then((newName) {
      if (newName != null) {
        widget.onRename(newName.isEmpty ? null : newName);
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(entryDate).inDays;

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return time;
    if (diff == 1) return 'Yesterday, $time';

    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';

    return '$date, $time';
  }
}

/// An individual expanded calculation line within a session.
/// Tapping it navigates back to the calculator with that specific state.
class _ExpandedLineItem extends StatelessWidget {
  final HistoryLine line;
  final int index;
  final int totalLines;
  final VoidCallback onTap;

  const _ExpandedLineItem({
    required this.line,
    required this.index,
    required this.totalLines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppLayout.radius.small),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppLayout.padding.small,
            horizontal: AppLayout.padding.small,
          ),
          child: Row(
            children: [
              // Line number indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(width: AppLayout.spacing.small),
              // Expression and result
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.expression,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '= ${line.result}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon to indicate it's tappable
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
