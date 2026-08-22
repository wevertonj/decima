// Motor de versionamento automático semântico (SemVer + changelog).
//
// Lê os commits de um range (Conventional Commits), decide o bump SemVer,
// reescreve `version:` no pubspec.yaml e gera a entrada do CHANGELOG.md com
// apenas o que interessa ao usuário final do app.
//
// Dart puro (apenas dart:io). Invocado pelo workflow `release.yml` a cada
// push (merge de PR) na branch `main`.
//
// Uso:
//   dart run tool/bump_version.dart [--since-sha=<sha>]
//
// Saída (stdout, leitura pela máquina):
//   RESULT <versaoAntiga> <versaoNova>  -> houve bump SemVer (sempre implica tag)
//   NOOP                                -> nada a versionar
// Logs amigáveis vão para stderr.
//
// Contrato (decisão D6): o motor só versiona quando o range contém ao menos um
// commit que provoca bump (`feat`/`fix`/`perf`/breaking). Tipos internos
// (`chore`/`docs`/`refactor`/`style`/`test`/`ci`/`build`) sozinhos — e o próprio
// commit de release (`chore(release)`, portanto sem bump) — resultam em `NOOP`:
// pubspec e CHANGELOG ficam intactos, o build number **não** sobe e o push segue
// sem commit de release. O build `+B` só sobe junto com um bump SemVer, logo
// todo `RESULT` implica uma nova tag (o protocolo dispensa o antigo flag `0|1`).

import 'dart:io';

/// Mapeamento de tipo Conventional Commit -> categoria visível no CHANGELOG.
/// Tipos ausentes aqui (chore, docs, style, refactor, test, ci, build) não
/// aparecem no changelog por não interessarem ao usuário final.
const _userFacingTypes = <String, _Category>{
  'feat': _Category.novidades,
  'fix': _Category.correcoes,
  'perf': _Category.melhorias,
};

/// Palavras que indicam remoção na descrição do commit -> seção "Removido".
final _removalKeyword = RegExp(
  r'^(remov|remove|delet|exclu)',
  caseSensitive: false,
);

/// Estrutura `tipo(escopo)!: descrição` da primeira linha do commit.
final _conventional = RegExp(
  r'^(?<type>\w+)(?:\((?<scope>[^)]*)\))?(?<bang>!)?:\s+(?<desc>.+)$',
);

enum _Category { breaking, novidades, correcoes, melhorias, removido }

enum _Bump { none, patch, minor, major }

void main(List<String> args) {
  final sinceSha = _argValue(args, '--since-sha');

  final from = _resolveRangeStart(sinceSha);
  final commits = _readCommits(from);

  if (commits.isEmpty) {
    stdout.writeln('NOOP');

    return;
  }

  // --- Decide o bump e agrupa as entradas do changelog ---
  var bump = _Bump.none;
  final grouped = <_Category, List<_Entry>>{};

  for (final c in commits) {
    final match = _conventional.firstMatch(c.subject);
    if (match == null) continue;

    final type = match.namedGroup('type')!.toLowerCase();
    var scope = match.namedGroup('scope')?.trim();
    if (scope != null && scope.isEmpty) scope = null;
    final desc = match.namedGroup('desc')!.trim();
    final isBreaking =
        match.namedGroup('bang') == '!' ||
        c.body.contains('BREAKING CHANGE') ||
        c.body.contains('BREAKING-CHANGE');

    // Nível do bump (Padrão SemVer): breaking > feat > fix/perf.
    if (isBreaking) {
      bump = _max(bump, _Bump.major);
    } else if (type == 'feat') {
      bump = _max(bump, _Bump.minor);
    } else if (type == 'fix' || type == 'perf') {
      bump = _max(bump, _Bump.patch);
    }

    // Categoria visível: breaking e reverts têm prioridade sobre o tipo. A
    // heurística de "descrição de remoção" só reclassifica tipos user-facing;
    // tipos internos (chore/docs/refactor/…) nunca entram, mesmo descrevendo
    // uma remoção (ex.: `chore(release): remove ...`).
    final _Category? category;
    if (isBreaking) {
      category = _Category.breaking;
    } else if (type == 'revert') {
      category = _Category.removido;
    } else if (_userFacingTypes.containsKey(type)) {
      category = _removalKeyword.hasMatch(desc)
          ? _Category.removido
          : _userFacingTypes[type];
    } else {
      category = null; // tipo interno: fora do changelog
    }
    if (category == null) continue;

    grouped
        .putIfAbsent(category, () => [])
        .add(_Entry(scope, _humanizeDesc(desc)));
  }

  // --- D6: sem bump SemVer no range → NOOP (não toca pubspec/CHANGELOG) ---
  // Só há versionamento quando o range provoca bump (feat/fix/perf/breaking).
  // Tipos internos sozinhos e o commit de release (`chore(release)`) caem aqui,
  // garantindo o anti-loop do segundo push e um build number que só sobe com
  // SemVer.
  if (bump == _Bump.none) {
    stdout.writeln('NOOP');

    return;
  }

  // --- Calcula a nova versão a partir do pubspec.yaml ---
  final pubspec = File('pubspec.yaml');
  final pubspecText = pubspec.readAsStringSync();
  final versionLine = RegExp(
    r'^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$',
    multiLine: true,
  );
  final vm = versionLine.firstMatch(pubspecText);
  if (vm == null) {
    stderr.writeln(
      '❌ Linha `version:` não encontrada/parseável no pubspec.yaml.',
    );
    exit(1);
  }

  var major = int.parse(vm.group(1)!);
  var minor = int.parse(vm.group(2)!);
  var patch = int.parse(vm.group(3)!);
  final build = int.parse(vm.group(4) ?? '0');

  switch (bump) {
    case _Bump.major:
      major += 1;
      minor = 0;
      patch = 0;
    case _Bump.minor:
      minor += 1;
      patch = 0;
    case _Bump.patch:
      patch += 1;
    case _Bump.none:
      break; // inalcançável: o gate acima já retornou em NOOP
  }
  final newBuild = build + 1; // o build só sobe junto com um bump SemVer

  final oldVersion = '${vm.group(1)}.${vm.group(2)}.${vm.group(3)}+$build';
  final newSemver = '$major.$minor.$patch';
  final newVersion = '$newSemver+$newBuild';

  // --- Reescreve o pubspec ---
  final newPubspec = pubspecText.replaceFirst(
    versionLine,
    'version: $newVersion',
  );
  pubspec.writeAsStringSync(newPubspec);

  // --- Atualiza o CHANGELOG ---
  // Um bump SemVer sempre traz ao menos um item visível ao usuário (breaking,
  // feat, fix ou perf sempre alimentam `grouped`), então a seção é gerada
  // incondicionalmente.
  _writeChangelog(newSemver, grouped);

  // --- Logs amigáveis (stderr) ---
  stderr.writeln('📦 Versão: $oldVersion → $newVersion  (${_label(bump)})');
  final resumo = grouped.entries
      .map((e) => '${e.value.length} ${_title(e.key)}')
      .join(', ');
  stderr.writeln('📝 CHANGELOG.md: $resumo');

  // --- Resultado para o hook (stdout) ---
  stdout.writeln('RESULT $oldVersion $newVersion');
}

/// Determina o início do range a analisar, em ordem de confiança:
/// 1. `--since-sha` (ponta remota do branch, vinda do protocolo do pre-push);
/// 2. última tag `v*`; 3. último commit de release (`chore(release)`);
/// 4. histórico inteiro.
String? _resolveRangeStart(String? sinceSha) {
  if (sinceSha != null && sinceSha.isNotEmpty && _commitExists(sinceSha)) {
    return sinceSha;
  }

  final tag = _git(['describe', '--tags', '--abbrev=0', '--match', 'v*']);
  if (tag.exitCode == 0 && tag.stdout.toString().trim().isNotEmpty) {
    return tag.stdout.toString().trim();
  }

  final releaseCommit = _git([
    'log',
    '--grep',
    'chore(release)',
    '--fixed-strings',
    '-n',
    '1',
    '--format=%H',
  ]);
  final sha = releaseCommit.stdout.toString().trim();
  if (sha.isNotEmpty) return sha;

  return null; // sem referência: analisa todo o histórico
}

/// Lê os commits de `from..HEAD` (ou todo o histórico se `from` for nulo),
/// em ordem cronológica, ignorando merges.
List<_Commit> _readCommits(String? from) {
  final range = from == null ? 'HEAD' : '$from..HEAD';
  // Separadores: campos por \x1f, registros por \x1e.
  final res = _git([
    'log',
    '--no-merges',
    '--reverse',
    '--format=%s%x1f%b%x1e',
    range,
  ]);
  if (res.exitCode != 0) return [];

  final raw = res.stdout.toString();

  return raw.split('\x1e').map((r) => r.trim()).where((r) => r.isNotEmpty).map((
    r,
  ) {
    final parts = r.split('\x1f');

    return _Commit(parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
  }).toList();
}

/// Insere a nova seção no topo do CHANGELOG.md (formato Keep a Changelog).
void _writeChangelog(String semver, Map<_Category, List<_Entry>> grouped) {
  const header =
      '# Changelog\n\n'
      'Todas as mudanças notáveis deste projeto são documentadas aqui.\n'
      'O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) '
      'e o projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).';

  final date = DateTime.now().toIso8601String().substring(0, 10);
  final buf = StringBuffer('## [$semver] - $date\n');

  // Ordem fixa das seções.
  const order = [
    _Category.breaking,
    _Category.novidades,
    _Category.correcoes,
    _Category.melhorias,
    _Category.removido,
  ];
  for (final cat in order) {
    final items = grouped[cat];
    if (items == null || items.isEmpty) continue;
    buf.write('\n### ${_emoji(cat)} ${_title(cat)}\n');
    for (final line in _renderCategoryItems(items)) {
      buf.writeln(line);
    }
  }
  final section = buf.toString().trimRight();

  final file = File('CHANGELOG.md');
  final String content;
  if (file.existsSync()) {
    final existing = file.readAsStringSync();
    final idx = existing.indexOf('\n## [');
    if (idx >= 0) {
      final head = existing.substring(0, idx).trimRight();
      final tail = existing.substring(idx).trimLeft(); // começa em "## ["
      content = '$head\n\n$section\n\n$tail\n';
    } else {
      content = '${existing.trimRight()}\n\n$section\n';
    }
  } else {
    content = '$header\n\n$section\n';
  }
  file.writeAsStringSync(content);
}

// ----------------------------- helpers -------------------------------------

class _Commit {
  _Commit(this.subject, this.body);
  final String subject;
  final String body;
}

class _Entry {
  _Entry(this.scope, this.desc);
  final String? scope;
  final String desc;
}

_Bump _max(_Bump a, _Bump b) => a.index >= b.index ? a : b;

/// Renderiza as linhas de uma categoria, estruturando por módulo/feature.
///
/// Quando um mesmo escopo aparece mais de uma vez, suas entradas são colapsadas
/// em uma lista aninhada sob um único cabeçalho `- **escopo:**` (na posição da
/// primeira ocorrência). Escopos únicos e itens sem escopo seguem inline.
List<String> _renderCategoryItems(List<_Entry> entries) {
  final counts = <String, int>{};
  final byScope = <String, List<String>>{};
  for (final e in entries) {
    final scope = e.scope;
    if (scope == null) continue;
    counts[scope] = (counts[scope] ?? 0) + 1;
    byScope.putIfAbsent(scope, () => []).add(e.desc);
  }

  final emitted = <String>{};
  final lines = <String>[];
  for (final e in entries) {
    final scope = e.scope;
    if (scope != null && (counts[scope] ?? 0) > 1) {
      if (emitted.contains(scope)) continue;
      emitted.add(scope);
      lines.add('- **$scope:**');
      for (final child in byScope[scope]!) {
        lines.add('  - $child');
      }
    } else if (scope != null) {
      lines.add('- **$scope:** ${e.desc}');
    } else {
      lines.add('- ${e.desc}');
    }
  }

  return lines;
}

/// Normaliza a descrição: maiúscula inicial, sem ponto final.
String _humanizeDesc(String desc) {
  var text = desc.trim();
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);

  return text;
}

String _label(_Bump b) => switch (b) {
  _Bump.major => 'major',
  _Bump.minor => 'minor',
  _Bump.patch => 'patch',
  _Bump.none => 'sem mudança de versão',
};

String _title(_Category c) => switch (c) {
  _Category.breaking => 'Mudanças importantes',
  _Category.novidades => 'Novidades',
  _Category.correcoes => 'Correções',
  _Category.melhorias => 'Melhorias',
  _Category.removido => 'Removido',
};

String _emoji(_Category c) => switch (c) {
  _Category.breaking => '⚠️',
  _Category.novidades => '✨',
  _Category.correcoes => '⚙️',
  _Category.melhorias => '⚡',
  _Category.removido => '🗑️',
};

String? _argValue(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }

  return null;
}

bool _commitExists(String sha) =>
    _git(['cat-file', '-e', '$sha^{commit}']).exitCode == 0;

ProcessResult _git(List<String> args) =>
    Process.runSync('git', args, stdoutEncoding: SystemEncoding());
