# Padrões de Código

## Estilo Geral

### Imports

Organize na seguinte ordem, separados por linha em branco:

1. Dart SDK (`dart:*`)
2. Flutter (`package:flutter/*`)
3. Packages externos (`package:get_it/*`, `package:sqflite/*`, etc.)
4. Projeto (`package:decima/*`)

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
