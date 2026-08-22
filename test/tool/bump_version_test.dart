@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Teste de integração leve do motor de versionamento `tool/bump_version.dart`
/// (decisão D6). Cada cenário monta um repositório git temporário com commits
/// fixture, roda o tool via `dart run` com o CWD apontado ao repo e valida a
/// saída de máquina (`RESULT`/`NOOP`), o `pubspec.yaml` e o `CHANGELOG.md`.
///
/// As invariantes de D6 exercitadas (e que divergem do roume de origem):
///   - `NOOP` quando o range não provoca bump SemVer (só `chore`/`docs`/…);
///   - `NOOP` num range só de release (`chore(release)`) — anti-loop do 2º push;
///   - o build `+B` só sobe junto com um bump SemVer;
///   - protocolo `RESULT <antiga> <nova>` (sem o antigo 3º campo `0|1`);
///   - âncora de fallback do range = último commit `chore(release)`.
void main() {
  final toolPath = File('tool/bump_version.dart').absolute.path;

  late Directory repo;

  setUp(() {
    repo = Directory.systemTemp.createTempSync('bump_version_test_');
    _git(repo, ['init', '--quiet']);
    _git(repo, ['config', 'user.email', 'test@decima.dev']);
    _git(repo, ['config', 'user.name', 'Decima Test']);
    _git(repo, ['config', 'commit.gpgsign', 'false']);
  });

  tearDown(() {
    if (repo.existsSync()) repo.deleteSync(recursive: true);
  });

  group('bump_version.dart', () {
    test('should emit RESULT, bump minor and write the CHANGELOG for a feat '
        'range', () {
      // Arrange
      _writePubspec(repo, '1.2.3+4');
      final base = _commit(repo, 'chore: baseline');
      _commit(repo, 'feat(search): add advanced filters');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      final out = _stdout(result);
      expect(result.exitCode, 0, reason: _stderr(result));
      expect(out, 'RESULT 1.2.3+4 1.3.0+5');
      expect(out.split(' '), hasLength(3)); // protocolo sem 3º campo `0|1`
      expect(_read(repo, 'pubspec.yaml'), contains('version: 1.3.0+5'));

      final changelog = _read(repo, 'CHANGELOG.md');
      expect(changelog, contains('# Changelog'));
      expect(changelog, contains('## [1.3.0]'));
      expect(changelog, contains('### ✨ Novidades'));
      expect(changelog, contains('- **search:** Add advanced filters'));
    });

    test('should bump patch for a fix range', () {
      // Arrange
      _writePubspec(repo, '2.0.0+10');
      final base = _commit(repo, 'chore: baseline');
      _commit(repo, 'fix: correct null pointer on login');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      expect(_stdout(result), 'RESULT 2.0.0+10 2.0.1+11');
      expect(_read(repo, 'pubspec.yaml'), contains('version: 2.0.1+11'));
      expect(_read(repo, 'CHANGELOG.md'), contains('### ⚙️ Correções'));
    });

    test('should bump major for a breaking change', () {
      // Arrange
      _writePubspec(repo, '1.5.2+7');
      final base = _commit(repo, 'chore: baseline');
      _commit(repo, 'feat!: redesign public API');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      expect(_stdout(result), 'RESULT 1.5.2+7 2.0.0+8');
      expect(_read(repo, 'pubspec.yaml'), contains('version: 2.0.0+8'));
      expect(
        _read(repo, 'CHANGELOG.md'),
        contains('### ⚠️ Mudanças importantes'),
      );
    });

    test('should NOOP for a range with only chore/docs/refactor commits', () {
      // Arrange
      _writePubspec(repo, '3.1.4+9');
      final base = _commit(repo, 'chore: baseline');
      _commit(repo, 'chore: tidy imports');
      _commit(repo, 'docs: expand readme');
      _commit(repo, 'refactor: rename helper');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      expect(_stdout(result), 'NOOP');
      // O build number NÃO sobe sem bump SemVer (diverge do roume).
      expect(_read(repo, 'pubspec.yaml'), contains('version: 3.1.4+9'));
      expect(File('${repo.path}/CHANGELOG.md').existsSync(), isFalse);
    });

    test('should NOOP for a range with only a release commit (anti-loop)', () {
      // Arrange
      _writePubspec(repo, '1.3.0+5');
      final base = _commit(repo, 'chore: baseline');
      _commit(repo, 'chore(release): v1.3.0+5');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      expect(_stdout(result), 'NOOP');
      expect(_read(repo, 'pubspec.yaml'), contains('version: 1.3.0+5'));
      expect(File('${repo.path}/CHANGELOG.md').existsSync(), isFalse);
    });

    test('should NOOP for an empty range', () {
      // Arrange
      _writePubspec(repo, '1.0.0+1');
      final base = _commit(repo, 'chore: baseline');

      // Act
      final result = _runBump(repo, toolPath, sinceSha: base);

      // Assert
      expect(_stdout(result), 'NOOP');
    });

    test('should anchor the fallback range to the last chore(release) commit '
        'when no --since-sha is given', () {
      // Arrange: um breaking ANTES do release provaria um range mal-ancorado
      // (major sobre todo o histórico) caso a âncora não fosse o release.
      _writePubspec(repo, '2.2.0+3');
      _commit(repo, 'feat!: initial breaking baseline');
      _commit(repo, 'chore(release): v2.2.0+3');
      _commit(repo, 'feat: add export');

      // Act
      final result = _runBump(repo, toolPath);

      // Assert: range = commits após o release → só o `feat` (minor), não major.
      expect(_stdout(result), 'RESULT 2.2.0+3 2.3.0+4');
    });
  });
}

// ------------------------------ helpers ------------------------------------

void _writePubspec(Directory repo, String version) {
  File('${repo.path}/pubspec.yaml').writeAsStringSync(
    'name: temp_app\n'
    'description: fixture\n'
    'version: $version\n'
    'environment:\n'
    "  sdk: '>=3.0.0 <4.0.0'\n",
  );
}

String _commit(Directory repo, String message) {
  _git(repo, ['commit', '--allow-empty', '--quiet', '-m', message]);

  return _git(repo, ['rev-parse', 'HEAD']).stdout.toString().trim();
}

ProcessResult _runBump(Directory repo, String toolPath, {String? sinceSha}) {
  final args = ['run', toolPath];
  if (sinceSha != null) args.add('--since-sha=$sinceSha');

  return Process.runSync(
    'dart',
    args,
    workingDirectory: repo.path,
    stdoutEncoding: const SystemEncoding(),
    stderrEncoding: const SystemEncoding(),
  );
}

ProcessResult _git(Directory repo, List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: repo.path,
    stdoutEncoding: const SystemEncoding(),
    stderrEncoding: const SystemEncoding(),
  );
  if (result.exitCode != 0) {
    fail('git ${args.join(' ')} failed: ${result.stderr}');
  }

  return result;
}

String _read(Directory repo, String name) =>
    File('${repo.path}/$name').readAsStringSync();

String _stdout(ProcessResult result) => result.stdout.toString().trim();

String _stderr(ProcessResult result) => result.stderr.toString().trim();
