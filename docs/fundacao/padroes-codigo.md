# Padrões de Código

> Convenções do código Dart do Decima: estilo, naming, limite de linhas por arquivo, lints, política de comentários e padrões por camada (dados, domínio, UI).

## Estilo Geral

### Imports

Ordem imposta pelo lint `directives_ordering`:

1. Dart SDK (`dart:*`)
2. Packages (`package:*`) em **ordem alfabética** num bloco único — `package:decima/*` fica, portanto, antes de `package:flutter/*`

Blocos separados por linha em branco; sem imports relativos (`always_use_package_imports`).

### Naming

- **Código**: Inglês (variáveis, classes, métodos, arquivos)
- **Comentários**: Português brasileiro
- **Testes**: Descrições em inglês, começando com "should"

### Return Statement

Sempre deixe uma linha em branco antes do `return`, exceto quando for a única instrução do bloco:

```dart
// ✅ Com linha em branco antes
String formatResult(double value) {
  final formatted = value.toStringAsFixed(2);

  return formatted;
}

// ✅ Retorno como única linha — sem linha em branco
int get length => _items.length;
```

## Limite de Linhas por Arquivo

Ideal de **≤ 600 linhas** por arquivo Dart em `lib/` e `test/`, excluindo gerados (`lib/utils/l10n/`). O limite serve para **identificar cedo** onde a atenção de refatoração deve ir — não é meta de compressão.

| Camada | Sinal | Decomposição |
|--------|-------|--------------|
| ViewModel | Aproximando-se de 600 | Sub-controllers em `ui/<feature>/controllers/`, com responsabilidade única e dependências via construtor |
| Page/Widget | > ~500 | Widgets extraídos para `widgets/`; lógica pura extraída para helpers testáveis fora da árvore |
| Domain/Service | > ~400 | Classes colaboradoras com responsabilidade única |

| Verificação | Detalhe |
|-------------|---------|
| Comando | `dart run tool/check_file_length.dart` |
| CI | Step "Limite de linhas por arquivo (600)" do job `analyze` (`ci.yml`) |
| Allowlist | Tolera (mas reporta) os arquivos que aguardam as Etapas 20–21: `calculator_view_model.dart` e `calculator_view_model_test.dart`; **zera ao fim da Etapa 21** |
| Entrada obsoleta | Arquivo da allowlist que voltou ao limite falha o check até a entrada ser removida |

## Lints

`analysis_options.yaml` parte de `package:flutter_lints/flutter.yaml` e ativa as regras extras abaixo (Etapa 19). Nenhuma das candidatas avaliadas foi descartada. `flutter analyze` deve retornar **zero warnings** (gate do CI).

| Regra | Motivo |
|-------|--------|
| `always_use_package_imports` | Sem imports relativos — sempre `package:decima/...` |
| `directives_ordering` | Ordem de imports da seção [Imports](#imports), com ordenação alfabética dentro de cada bloco |
| `prefer_final_locals` | Variáveis locais imutáveis por padrão |
| `prefer_single_quotes` | Aspas simples em todo o projeto |
| `sort_pub_dependencies` | Dependências do `pubspec.yaml` em ordem alfabética |
| `unawaited_futures` | Todo fire-and-forget intencional fica explícito via `unawaited(...)` (ex.: persistência de sessão, `loadSettings` na volta da tela de configurações) |

## Política de Comentários

Definida na Etapa 19; aplicada em massa ao código legado na Etapa 23.

| Tipo | Regra |
|------|-------|
| Doc comment (`///`) | Apenas em API pública: **contrato em 1–3 linhas** — o *quê*, nunca o *como* |
| Inline (`//`) | Apenas para invariante local que o código não consegue expressar |
| "Porquê" de design, história, trade-offs | Não vive no código: migra para `docs/` (seções de features ou tabelas de Gotchas) |
| Narração do óbvio | **Proibido** — redundância com nome de método/variável/teste é ruído |
| Idioma | **pt-BR** (consistente com `docs/` e com a seção [Naming](#naming)); o legado em inglês é traduzido na triagem da Etapa 23 — só os comentários sobreviventes |

## Camada de Dados

### Repository Pattern

Cada repository tem uma **interface** e uma **implementação**:

```dart
// Interface
abstract class HistoryRepository {
  Future<List<HistoryEntry>> getAll();
  Future<void> add(HistoryEntry entry);
  Future<void> clear();
}

// Implementação
class HistoryRepositoryImpl implements HistoryRepository {
  final AppDatabase _database;

  HistoryRepositoryImpl({required AppDatabase database})
      : _database = database;

  @override
  Future<List<HistoryEntry>> getAll() async {
    final rows = await _database.query('history');

    return rows.map(HistoryModel.fromMap).map((m) => m.toEntity()).toList();
  }
}
```

### Models

Models fazem a ponte entre o banco de dados e as entities:

```dart
class HistoryModel {
  final int? id;
  final String expression;
  final String result;
  final int timestamp;

  Map<String, dynamic> toMap() => { ... };
  static HistoryModel fromMap(Map<String, dynamic> map) => HistoryModel(...);
  HistoryEntry toEntity() => HistoryEntry(...);
}
```

## Camada de Domínio

### Entities

Classes Dart puras, sem dependência de Flutter ou pacotes externos:

```dart
class Calculation {
  final String expression;
  final String result;
  final DateTime timestamp;

  const Calculation({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}
```

### Enums

Tipos simples para estados e operações:

```dart
enum OperationType { add, subtract, multiply, divide }

enum CalculatorMode { standard, addMode }
```

## Camada de UI

### ViewModels

- Usam `ChangeNotifier` ou `ValueNotifier`
- **Nunca** importam Flutter (`dart:ui`, `package:flutter/*`)
- Chamam apenas métodos de Repositories (via interface)
- São registrados no GetIt como `Factory`

```dart
class CalculatorViewModel extends ChangeNotifier {
  final HistoryRepository _historyRepository;

  CalculatorViewModel({required HistoryRepository historyRepository})
      : _historyRepository = historyRepository;

  String _display = '0';
  String get display => _display;

  void inputDigit(String digit) {
    _display = _display == '0' ? digit : _display + digit;
    notifyListeners();
  }
}
```

### Pages e Widgets

- Usam `context.l10n.*` para todo texto
- Usam constantes de layout do tema (nunca valores hardcoded)
- Aplicam animações suaves em qualquer mudança de estado visual

## Internacionalização

Todo texto visível ao usuário vem dos arquivos ARB:

```dart
// ✅ Correto
Text(context.l10n.calculatorTitle)

// ❌ Proibido
Text('Calculadora')
```

## Logging

Nunca use `print()`. Use uma solução de logging adequada.

## Segurança e Cibersegurança

| Vetor | Risco no contexto | Regra aplicada |
|-------|-------------------|----------------|
| Entrada não confiável (OWASP A03 — Injection) | Dados de banco/preferências/clipboard chegam às camadas superiores | Repositories validam ou aplicam default a todo valor lido; enums caem no `orElse`; parsing de clipboard passa pelo `PasteInputParser` |
| Exposição em log (OWASP A09 — Logging Failures) | Expressões e resultados podem conter dados financeiros | `print()` proibido; nenhum dado do usuário em log de runtime |
| Dependências (OWASP A06 — Vulnerable Components) | Pacote comprometido ou abandonado entra no app | Dependências mínimas e declaradas explicitamente (nada de transitiva usada direto); versões pinadas por range no `pubspec.yaml` |
| Menor privilégio | — | App 100% offline: sem rede, sem telemetria; ViewModels só enxergam Repositories via interface |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| `directives_ordering` ordena `package:` alfabeticamente | `package:decima` vem **antes** de `package:flutter` — contraintuitivo para quem espera "projeto por último" | Deixar o `dart fix`/IDE ordenar; não reordenar à mão |
| `unawaited_futures` só cobre `Future` em posição de statement | Fire-and-forget dentro de expressões passa despercebido | Revisar manualmente chamadas async em callbacks |
| Limite de 600 linhas tem allowlist temporária | Check verde não significa que todos os arquivos estão no limite | Allowlist reportada como ⚠️ na saída do verificador; zera na Etapa 21 |
| `check_file_length.dart` conta linhas físicas | Formatação (quebras do `dart format`) influencia a contagem | O limite é ideal, não métrica exata — decompor pela tabela de camadas, não caçar linhas |
| Comentários legados em inglês | Arquivos misturam pt-BR e inglês até a Etapa 23 | Não traduzir em massa antes da triagem — código novo já nasce em pt-BR |

## TDD

Fluxo obrigatório (detalhado em [`docs/qualidade/testes.md`](../qualidade/testes.md)):

1. Escrever o teste que descreve o comportamento (`should ...`)
2. Ver o teste falhar
3. Implementar o mínimo para passar
4. Refatorar mantendo a suíte verde — **nunca** alterar testes existentes para acomodar código novo

| Artefato | Cenários mínimos |
|----------|------------------|
| Script de `tool/` | Teste de integração leve em `test/tool/` rodando o script via `dart run` em diretório temporário (padrão `bump_version_test.dart` / `check_file_length_test.dart`) |
| ViewModel / domínio | Teste unitário com repositories mockados (`mocktail`) |
| Widget | Teste de widget com `pumpWidget` + ViewModel fake |

Exemplo canônico AAA:

```dart
test('should exit 0 when every file is within the limit', () {
  // Arrange
  _writeDart(root, 'lib/main.dart', lines: 100);

  // Act
  final result = _runCheck(root, toolPath);

  // Assert
  expect(result.exitCode, 0);
});
```
