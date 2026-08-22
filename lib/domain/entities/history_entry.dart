import 'package:decima/domain/entities/history_line.dart';

/// A history entry representing an entire calculator session.
///
/// Each session contains one or more [lines], where each line is a
/// calculation (expression + result) performed sequentially. The [result]
/// field holds the final result of the last line for quick preview.
class HistoryEntry {
  final int? id;
  final List<HistoryLine> lines;
  final String result;
  final DateTime createdAt;
  final String? name;
  final bool isFavorite;

  const HistoryEntry({
    this.id,
    required this.lines,
    required this.result,
    required this.createdAt,
    this.name,
    this.isFavorite = false,
  });

  /// Preview expression: the first line's expression, truncated if long.
  String get previewExpression {
    if (lines.isEmpty) return '';
    return lines.first.expression;
  }

  /// Total number of calculation lines in this session.
  int get lineCount => lines.length;

  HistoryEntry copyWith({
    int? id,
    List<HistoryLine>? lines,
    String? result,
    DateTime? createdAt,
    String? name,
    bool? isFavorite,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      lines: lines ?? this.lines,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEquals(lines, other.lines) &&
          result == other.result &&
          createdAt == other.createdAt &&
          name == other.name &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(lines),
    result,
    createdAt,
    name,
    isFavorite,
  );

  static bool _listEquals(List<HistoryLine> a, List<HistoryLine> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
