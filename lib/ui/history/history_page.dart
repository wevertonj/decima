import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/domain/entities/history_selection.dart';
import 'package:decima/ui/history/history_view_model.dart';
import 'package:decima/ui/history/widgets/animated_list_item.dart';
import 'package:decima/ui/history/widgets/history_list_item.dart';
import 'package:decima/ui/widgets/flat_segmented_control.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Tela do histórico com a lista paginada de cálculos salvos.
///
/// Filtro por favoritos, renomear por toque longo e limpar tudo. A entrada
/// tocada é devolvida via [Navigator.pop] para quem chamou carregar a
/// sessão — a página não conhece o `CalculatorViewModel`.
class HistoryPage extends StatefulWidget {
  final HistoryViewModel viewModel;

  const HistoryPage({super.key, required this.viewModel});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
    widget.viewModel.loadEntries();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (vm.entries.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: () => _confirmClear(context),
              tooltip: l10n.clearHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.padding.medium,
              vertical: AppLayout.padding.small,
            ),
            child: FlatSegmentedControl<bool>(
              value: vm.showFavoritesOnly,
              items: const [false, true],
              onChanged: (value) => vm.setShowFavoritesOnly(value),
              itemBuilder: (isFavorites) {
                if (isFavorites) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded),
                      const SizedBox(width: 4),
                      Text(l10n.favorites),
                    ],
                  );
                }
                return Text(l10n.allEntries);
              },
            ),
          ),
          Expanded(child: _buildList(context, vm)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, HistoryViewModel vm) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    if (vm.isLoading && vm.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vm.showFavoritesOnly
                  ? Icons.star_outline_rounded
                  : Icons.history_rounded,
              size: 64,
              color: colors.onSurface.withValues(alpha: 0.2),
            ),
            SizedBox(height: AppLayout.spacing.medium),
            Text(
              vm.showFavoritesOnly ? l10n.noFavorites : l10n.noHistory,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: AppLayout.padding.small,
        bottom: AppLayout.padding.xl,
      ),
      itemCount: vm.entries.length + (vm.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == vm.entries.length) {
          return _buildLoadMore(context, vm);
        }

        final entry = vm.entries[index];

        return AnimatedListItem(
          index: index,
          child: HistoryListItem(
            entry: entry,
            onLineTap: (lineIndex) {
              Navigator.of(
                context,
              ).pop(HistorySelection(entry: entry, lineIndex: lineIndex));
            },
            onToggleFavorite: () {
              if (entry.id != null) {
                vm.toggleFavorite(entry.id!);
              }
            },
            onRename: (name) {
              if (entry.id != null) {
                vm.updateName(entry.id!, name);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadMore(BuildContext context, HistoryViewModel vm) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppLayout.padding.medium),
      child: Center(
        child: vm.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: vm.loadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(l10n.loadMore),
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    final l10n = context.l10n;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        widget.viewModel.clearAll();
      }
    });
  }
}
