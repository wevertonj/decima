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
///   - gerados (`lib/utils/l10n/`) e não-Dart ficam fora da contagem.
///
/// Os ramos de tolerância e de entrada obsoleta da allowlist deixaram de ser
/// exercitáveis com a lista zerada na Etapa 21 (ela é `const` no tool); os
/// cenários voltam se a lista voltar a ter entradas.
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

    test('should stay green for the former allowlisted paths now that the '
        'list is empty', () {
      // Arrange: os dois arquivos que saíram da allowlist, dentro do limite.
      _writeDart(
        root,
        'lib/ui/calculator/calculator_view_model.dart',
        lines: 561,
      );
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
