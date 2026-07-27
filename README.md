# Decima

Calculadora elegante e minimalista com entrada **Add2** — 2 casas decimais automáticas sem pressionar ponto.

## Funcionalidades

- **Add2** — Digitar `1250` exibe `12.50`. Suporte completo a +, −, ×, ÷, % e parênteses
- **Timeline** — Display scrollável: linha atual em branco, prévia do resultado em cinza, cálculos anteriores acima
- **Histórico** — Operações persistidas em SQLite. Carregue uma sessão e continue o cálculo de onde parou
- **Temas** — Claro/escuro com 9 opções de seed color
- **Formato de número** — Separador decimal como ponto ou vírgula
- **Internacionalização** — Suporte multi-idioma via arquivos ARB

## Design

Inspirado na **One UI (Samsung)** — fundo escuro, botões circulares, acentos em amarelo/dourado e animações suaves.

## Stack

| Tecnologia | Uso |
|------------|-----|
| Flutter / Dart 3 | Framework |
| ChangeNotifier / ValueNotifier | Gerenciamento de estado |
| SQLite (sqflite) | Persistência local |
| GetIt | Injeção de dependência |
| mocktail | Testes |

## Arquitetura

```
lib/
├── config/        # DI, rotas, tema
├── data/          # Repositories, database, models
├── domain/        # Entities, enums
├── ui/            # Pages, widgets, view models
└── utils/         # Extensions, formatters, l10n
```

## Desenvolvimento

```bash
# Rodar o app
flutter run

# Testes
flutter test

# Análise estática
flutter analyze
```

O projeto segue **TDD** rigorosamente. Consulte `/docs` para documentação completa.
