# Testes

## Filosofia

O projeto segue rigorosamente **TDD (Test-Driven Development)**. Todo código novo nasce a partir de um teste.

> **Regra crítica**: Se a implementação quebrar testes existentes de outros módulos, **corrigir a implementação, nunca os testes**. Não é permitido reescrever, deletar ou alterar testes/features que já funcionam para acomodar código novo.

## Fluxo TDD

1. **Red**: Escreva o teste. Ele deve falhar.
2. **Green**: Implemente o mínimo necessário para o teste passar.
3. **Refactor**: Refatore mantendo os testes verdes.
4. **Validate**: Rode `flutter test` e confirme 100% verde.

## Estrutura de Pastas

```
test/
├── fixtures/              # Dados de teste reutilizáveis
├── mocks/                 # Mocks centralizados (mocktail)
├── unit/                  # Testes unitários
│   ├── domain/            # Entities, enums
│   ├── data/              # Repositories, models
│   └── ui/                # ViewModels
└── widget/                # Testes de widget
    ├── calculator/
    ├── history/
    └── settings/
```

## Padrões

### Nomenclatura

- Descrições em **inglês**
- Sempre começando com **"should"**

```dart
test('should return zero when display is cleared', () { ... });
test('should add entry to history after calculation', () { ... });
```

### AAA (Arrange, Act, Assert)

```dart
test('should multiply two numbers correctly', () {
  // Arrange
  final calculator = Calculator();

  // Act
  final result = calculator.evaluate('5 * 3');

  // Assert
  expect(result, '15');
});
```

### Mocking com mocktail

Centralize todos os mocks em `test/mocks/`:

```dart
// test/mocks/mock_repositories.dart
import 'package:mocktail/mocktail.dart';
import 'package:decima/data/repositories/history_repository.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}
```

Registre fallback values no `setUpAll` para tipos usados com `any()`:

```dart
setUpAll(() {
  registerFallbackValue(FakeHistoryEntry());
});
```

### Fixtures

Centralize dados de teste reutilizáveis em `test/fixtures/`:

```dart
// test/fixtures/calculation_fixtures.dart
class CalculationFixtures {
  static Calculation simpleAddition() => Calculation(
    expression: '2 + 3',
    result: '5',
    timestamp: DateTime(2024, 1, 1),
  );
}
```

### GetIt em Testes

```dart
setUp(() {
  GetIt.I.reset();
});

tearDown(() {
  GetIt.I.reset();
});

// Use tipos explícitos ao registrar
GetIt.I.registerSingleton<HistoryRepository>(mockRepository);
```

## O que Testar

| Camada | O que testar |
|--------|-------------|
| **Entities** | Criação, igualdade, propriedades |
| **Enums** | Valores, conversões |
| **ViewModels** | Estado inicial, reações a ações, interação com repository |
| **Repositories** | Operações CRUD, mapeamento de dados |
| **Widgets** | Renderização, interação do usuário, estados visuais |

## Comandos

```bash
# Rodar todos os testes
flutter test

# Rodar com coverage
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html

# Rodar um arquivo específico
flutter test test/unit/domain/calculator_test.dart
```

## Regras Finais

- **Nunca** finalize uma tarefa sem rodar `flutter test`
- **Nunca** delete ou altere testes existentes para acomodar código novo
- **Sempre** escreva testes antes da implementação
- **Sempre** corrija testes quebrados ajustando a implementação
