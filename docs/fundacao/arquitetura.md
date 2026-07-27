# Arquitetura

## Visão Geral

Decima segue uma arquitetura limpa e simples, orientada pelos princípios **SOLID**, adequada para um app de escopo reduzido mas com código bem organizado e testável.

## Estrutura de Pastas

```
lib/
├── config/                    # Configuração do app
│   ├── dependencies.dart      # Registro de dependências (GetIt)
│   ├── routes.dart            # Configuração de rotas/navegação
│   └── theme/                 # Definição de temas
│       ├── app_theme.dart     # ThemeData (claro/escuro)
│       ├── app_colors.dart    # Seed colors e paleta
│       └── app_layout.dart    # Constantes de spacing, padding, radius
│
├── data/                      # Camada de dados
│   ├── database/              # SQLite: helper, migrations
│   ├── repositories/          # Interface + Implementação
│   ├── services/              # Serviços externos (clipboard, etc.)
│   └── models/                # Models para serialização do banco
│
├── domain/                    # Regras de negócio
│   ├── entities/              # Entidades puras (Calculation, HistoryEntry)
│   └── enums/                 # OperationType, CalculatorMode, etc.
│
├── ui/                        # Camada visual
│   ├── calculator/            # Feature: calculadora
│   │   ├── calculator_page.dart
│   │   ├── calculator_view_model.dart
│   │   └── widgets/           # Widgets específicos (display, keypad, buttons)
│   ├── history/               # Feature: histórico
│   │   ├── history_page.dart
│   │   ├── history_view_model.dart
│   │   └── widgets/
│   ├── settings/              # Feature: configurações
│   │   ├── settings_page.dart
│   │   ├── settings_view_model.dart
│   │   └── widgets/
│   └── core/                  # Widgets e utilitários globais da UI
│       ├── theme/
│       └── widgets/
│
├── utils/                     # Utilitários
│   ├── extensions/            # Extensões de String, num, Context
│   ├── formatters/            # Formatadores de número
│   └── l10n/                  # Arquivos ARB de internacionalização
│
└── main.dart                  # Entry point
```

## Regra de Classificação

| Pergunta | Destino |
|----------|---------|
| Acessa banco de dados? | `data/` |
| É visual? | `ui/` |
| É regra de negócio? | `domain/` |
| Todo o resto? | `utils/` |

## Princípios SOLID

- **S** — Single Responsibility: Cada classe tem uma única responsabilidade
- **O** — Open/Closed: Aberto para extensão, fechado para modificação
- **L** — Liskov Substitution: Subtipos devem ser substituíveis por seus tipos base
- **I** — Interface Segregation: Interfaces específicas são melhores que genéricas
- **D** — Dependency Inversion: Dependa de abstrações, não de implementações

## Fluxo de Dados

```
UI (Page/Widget)
    ↕ observa/chama
ViewModel (ChangeNotifier)
    ↕ usa
Repository (Interface)
    ↕ implementa
RepositoryImpl
    ↕ acessa
Database (SQLite)
```

- **Pages** observam **ViewModels** via `ListenableBuilder` ou `AnimatedBuilder`
- **ViewModels** chamam métodos de **Repositories** (via interface)
- **Repositories** encapsulam o acesso ao **banco de dados**
- **ViewModels** nunca acessam o banco diretamente
- **ViewModels** não importam Flutter — são Dart puro

## Injeção de Dependência

Todas as dependências são registradas no **GetIt** em `lib/config/dependencies.dart`:

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Database
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // Repositories
  getIt.registerSingleton<HistoryRepository>(
    HistoryRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // ViewModels
  getIt.registerFactory<CalculatorViewModel>(
    () => CalculatorViewModel(historyRepository: getIt<HistoryRepository>()),
  );
  getIt.registerFactory<HistoryViewModel>(
    () => HistoryViewModel(repository: getIt<HistoryRepository>()),
  );

  // SettingsViewModel é lazy singleton — instância compartilhada entre
  // DecimaApp (raiz) e SettingsPage para propagação reativa global de tema/cor/idioma.
  getIt.registerLazySingleton<SettingsViewModel>(
    () => SettingsViewModel(repository: getIt<SettingsRepository>()),
  );
}
```

## Navegação

Navegação simples entre 3 telas principais:

- **Calculator** — Tela principal
- **History** — Histórico de operações
- **Settings** — Configurações (tema, idioma)

A configuração de rotas fica centralizada em `lib/config/routes.dart`.
