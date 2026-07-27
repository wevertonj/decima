import 'package:decima/domain/entities/history_entry.dart';

/// Represents the user's selection when tapping a specific line
/// within a history session entry.
class HistorySelection {
  final HistoryEntry entry;

  /// The index of the line the user tapped (0-based).
  /// All lines up to and including this index will be loaded
  /// into the calculator timeline.
  final int lineIndex;

  const HistorySelection({
    required this.entry,
    required this.lineIndex,
  });
}
