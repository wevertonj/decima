import 'package:decima/domain/entities/history_line.dart';

/// Entrada do histórico representando uma sessão inteira da calculadora.
///
/// Cada sessão contém uma ou mais [lines] — cálculos (expressão +
/// resultado) feitos em sequência. [result] guarda o resultado final da
/// última linha, para prévia rápida.
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

  /// Expressão de prévia: a expressão da primeira linha.
  String get previewExpression {
    if (lines.isEmpty) return '';
    return lines.first.expression;
  }

  /// Total de linhas de cálculo desta sessão.
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
