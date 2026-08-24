import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/expression_evaluator.dart';
import 'package:decima/domain/paste_input_parser.dart';

/// Conteúdo colado já validado e reavaliado, pronto para ser aplicado ao
/// estado da calculadora.
class PastedSession {
  const PastedSession({required this.lines, this.inputTokens});

  /// Linhas resolvidas (`<expressão> = <resultado>`) com o resultado
  /// **recalculado** da expressão — um valor obsoleto ou errado na área de
  /// transferência nunca chega ao histórico.
  final List<HistoryLine> lines;

  /// Tokens da entrada em aberto (linha final sem `=`). `null` quando o
  /// texto termina em uma linha resolvida.
  final List<String>? inputTokens;
}

/// Copiar/colar da calculadora: I/O com o [ClipboardService], parse via
/// [PasteInputParser] e reavaliação das linhas coladas.
class ClipboardController {
  ClipboardController({
    required ClipboardService clipboardService,
    ExpressionEvaluator? evaluator,
  }) : _clipboardService = clipboardService,
       _evaluator = evaluator ?? ExpressionEvaluator();

  final ClipboardService _clipboardService;
  final ExpressionEvaluator _evaluator;

  /// Copia [text] para a área de transferência.
  Future<void> copyText(String text) => _clipboardService.copyText(text);

  /// Copies all session timeline entries to the clipboard, one per line in
  /// the format `<expression> = <result>`. No-op when [entries] is empty.
  Future<void> copyHistory(List<Calculation> entries) async {
    if (entries.isEmpty) return;

    final buffer = StringBuffer();
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) buffer.writeln();
      final entry = entries[i];
      buffer.write('${entry.expression} = ${entry.result}');
    }

    await _clipboardService.copyText(buffer.toString());
  }

  /// True when the clipboard currently contains text. Used by the context
  /// menu to enable/disable the paste entry without committing to a paste.
  Future<bool> hasText() async {
    final raw = await _clipboardService.readText();

    return raw != null && raw.isNotEmpty;
  }

  /// Lê a área de transferência e interpreta o texto como uma sessão da
  /// calculadora. Devolve `null` quando ela está vazia, quando o conteúdo
  /// não parseia ou quando alguma linha resolvida é inavaliável (ex.:
  /// divisão por zero) — nesse caso nada deve ser aplicado, para a
  /// calculadora nunca ficar pela metade.
  Future<PastedSession?> readPastedSession() async {
    final raw = await _clipboardService.readText();
    if (raw == null) return null;

    final content = PasteInputParser.parseContent(raw);
    if (content == null) return null;

    final lines = <HistoryLine>[];
    for (final tokens in content.resolvedLines) {
      final expression = tokens.join(' ');
      final result = _evaluator.evaluate(expression);
      if (result == null || result == ExpressionEvaluator.errorResult) {
        return null;
      }
      lines.add(HistoryLine(expression: expression, result: result));
    }

    return PastedSession(lines: lines, inputTokens: content.input);
  }
}
