import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Diálogo de renomear uma entrada do histórico.
///
/// Devolve o texto digitado ao salvar (string vazia limpa o nome) e null
/// quando cancelado — o chamador decide como mapear os dois casos.
class RenameEntryDialog extends StatefulWidget {
  final String? initialName;

  const RenameEntryDialog({super.key, this.initialName});

  /// Abre o diálogo sobre [context] e devolve o nome digitado.
  static Future<String?> show(BuildContext context, {String? initialName}) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameEntryDialog(initialName: initialName),
    );
  }

  @override
  State<RenameEntryDialog> createState() => _RenameEntryDialogState();
}

class _RenameEntryDialogState extends State<RenameEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.rename),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: l10n.renameHint,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.renameSave),
        ),
      ],
    );
  }
}
