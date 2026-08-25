import 'package:decima/domain/entities/history_entry.dart';

/// Seleção do usuário ao tocar uma linha específica de uma sessão do
/// histórico.
class HistorySelection {
  final HistoryEntry entry;

  /// Índice (base 0) da linha tocada. Todas as linhas até este índice,
  /// inclusive, são carregadas na timeline da calculadora.
  final int lineIndex;

  const HistorySelection({required this.entry, required this.lineIndex});
}
