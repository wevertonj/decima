@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Teste de integração leve do verificador `tool/check_file_length.dart`
/// (Etapa 19). Cada cenário monta uma árvore `lib/`/`test/` temporária com
/// arquivos fixture, roda o tool via `dart run` com o CWD apontado à árvore e
/// valida o relatório e o código de saída.
///
/// Invariantes exercitadas:
///   - exit 0 quando todos os arquivos estão dentro do limite de 600 linhas;
///   - exit 1 listando cada arquivo fora da allowlist que estoura o limite;
///   - allowlist tolera (mas reporta) os arquivos das Etapas 20–21;
///   - gerados (`lib/utils/l10n/`) e não-Dart ficam fora da contagem;
///   - entrada da allowlist com arquivo já dentro do limite falha (obsoleta);
///   - entrada da allowlist sem arquivo correspondente é inerte.
void main() {
  final toolPath = File('tool/check_file_length.dart').absolute.path;

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('check_file_length_test_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('check_file_length.dart', () {
    test('should exit 0 when every file is within the limit', () {
      // Arrange
      _writeDart(root, 'lib/main.dart', lines: 100);
      _writeDart(root, 'test/main_test.dart', lines: 600);

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 0, reason: _output(result));
      expect(_output(result), contains('✅'));
    });

    test('should exit 1 and list every file over the limit outside the '
        'allowlist', () {
      // Arrange
      _writeDart(root, 'lib/big_widget.dart', lines: 601);
      _writeDart(root, 'test/big_widget_test.dart', lines: 700);
      _writeDart(root, 'lib/small.dart', lines: 10);

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 1, reason: _output(result));
      final out = _output(result);
      expect(out, contains('lib/big_widget.dart: 601 linhas'));
      expect(out, contains('test/big_widget_test.dart: 700 linhas'));
      expect(out, isNot(contains('lib/small.dart')));
      expect(out, contains('padroes-codigo.md'));
    });

    test('should tolerate allowlisted files over the limit but still report '
        'them', () {
      // Arrange
      _writeDart(
        root,
        'lib/ui/calculator/calculator_view_model.dart',
        lines: 1526,
      );
      _writeDart(
        root,
        'test/unit/ui/calculator/calculator_view_model_test.dart',
        lines: 2583,
      );

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 0, reason: _output(result));
      final out = _output(result);
      expect(out, contains('calculator_view_model.dart: 1526 linhas'));
      expect(out, contains('calculator_view_model_test.dart: 2583 linhas'));
      expect(out, contains('allowlist'));
    });

    test('should ignore generated l10n files and non-Dart files', () {
      // Arrange
      _writeDart(root, 'lib/utils/l10n/app_localizations.dart', lines: 5000);
      final big = List.filled(999, 'linha de texto').join('\n');
      File('${root.path}/lib/notes.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(big);

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 0, reason: _output(result));
      expect(_output(result), contains('✅'));
    });

    test('should exit 1 when an allowlisted file is back within the limit '
        '(stale entry)', () {
      // Arrange
      _writeDart(
        root,
        'lib/ui/calculator/calculator_view_model.dart',
        lines: 400,
      );

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 1, reason: _output(result));
      expect(_output(result), contains('obsoleta'));
      expect(_output(result), contains('calculator_view_model.dart'));
    });

    test('should treat allowlist entries without a matching file as inert', () {
      // Arrange: nenhum arquivo da allowlist existe na árvore.
      _writeDart(root, 'lib/main.dart', lines: 50);

      // Act
      final result = _runCheck(root, toolPath);

      // Assert
      expect(result.exitCode, 0, reason: _output(result));
      expect(_output(result), contains('✅'));
    });
  });
}

// ------------------------------ helpers ------------------------------------

void _writeDart(Directory root, String relativePath, {required int lines}) {
  final content = List.generate(lines, (i) => '// linha ${i + 1}').join('\n');
  File('${root.path}/$relativePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

ProcessResult _runCheck(Directory root, String toolPath) => Process.runSync(
  'dart',
  ['run', toolPath],
  workingDirectory: root.path,
  stdoutEncoding: const SystemEncoding(),
  stderrEncoding: const SystemEncoding(),
);

String _output(ProcessResult result) =>
    '${result.stdout}\n${result.stderr}'.trim();
