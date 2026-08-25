// Verificador do limite de linhas por arquivo (Etapa 19).
//
// Percorre `lib/` e `test/` (relativos ao CWD) contando as linhas de cada
// arquivo Dart e falha quando algum fora da allowlist ultrapassa o limite
// ideal de 600 linhas documentado em `docs/fundacao/padroes-codigo.md`.
//
// Dart puro (apenas dart:io). Invocado pelo job `analyze` do `ci.yml`.
//
// Uso:
//   dart run tool/check_file_length.dart
//
// Saída: relatório em stdout. Exit 0 quando todos os arquivos estão dentro
// do limite (ou tolerados pela allowlist); exit 1 quando há violação ou
// quando uma entrada da allowlist ficou obsoleta (o arquivo existe e já
// voltou ao limite — remova a entrada para a lista encolher junto com a
// refatoração).

import 'dart:io';

/// Limite ideal de linhas por arquivo Dart (`docs/fundacao/padroes-codigo.md`).
const _limit = 600;

/// Raízes verificadas, relativas à raiz do repositório.
const _roots = ['lib', 'test'];

/// Prefixos de caminho excluídos (código gerado).
const _excludedPrefixes = ['lib/utils/l10n/'];

/// Exceções temporárias ao limite. Zerada na Etapa 21 (fim do ciclo de
/// refatoração 19–21); qualquer entrada nova precisa apontar a etapa que a
/// remove — a lista só encolhe.
const _allowlist = <String>{};

void main() {
  final lineCounts = <String, int>{};

  for (final root in _roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;

    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final path = _normalize(file.path);
      if (_excludedPrefixes.any(path.startsWith)) continue;

      lineCounts[path] = file.readAsLinesSync().length;
    }
  }

  final overLimit = lineCounts.entries.where((e) => e.value > _limit).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final violations = overLimit.where((e) => !_allowlist.contains(e.key));
  final tolerated = overLimit.where((e) => _allowlist.contains(e.key));
  // Obsoleta = o arquivo existe e já está dentro do limite. Entradas de
  // arquivos inexistentes (renomeados/removidos) não falham: são inertes.
  final stale = _allowlist.where(
    (path) => lineCounts.containsKey(path) && lineCounts[path]! <= _limit,
  );

  for (final e in tolerated) {
    stdout.writeln('⚠️  ${e.key}: ${e.value} linhas (tolerado pela allowlist)');
  }
  for (final e in violations) {
    stdout.writeln('❌ ${e.key}: ${e.value} linhas (limite: $_limit)');
  }
  for (final path in stale) {
    stdout.writeln(
      '❌ Entrada obsoleta na allowlist: $path já está dentro do limite — '
      'remova-a de tool/check_file_length.dart',
    );
  }

  if (violations.isNotEmpty || stale.isNotEmpty) {
    if (violations.isNotEmpty) {
      stdout.writeln(
        'Decomponha conforme a tabela de `docs/fundacao/padroes-codigo.md` '
        '(seção "Limite de Linhas por Arquivo").',
      );
    }
    exit(1);
  }

  stdout.writeln(
    '✅ Nenhuma violação: arquivos de ${_roots.join('/ e ')}/ dentro do '
    'limite de $_limit linhas.',
  );
}

String _normalize(String path) => path.replaceAll(r'\', '/');
