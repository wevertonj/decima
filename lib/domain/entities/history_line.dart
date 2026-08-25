/// Uma linha de cálculo dentro de uma sessão do histórico.
class HistoryLine {
  final String expression;
  final String result;

  const HistoryLine({required this.expression, required this.result});

  Map<String, dynamic> toJson() => {'expression': expression, 'result': result};

  factory HistoryLine.fromJson(Map<String, dynamic> json) {
    return HistoryLine(
      expression: json['expression'] as String,
      result: json['result'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryLine &&
          runtimeType == other.runtimeType &&
          expression == other.expression &&
          result == other.result;

  @override
  int get hashCode => Object.hash(expression, result);
}
