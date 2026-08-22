# Decima

[![CI](https://github.com/wevertonj/decima/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/wevertonj/decima/actions/workflows/ci.yml)
[![Release](https://github.com/wevertonj/decima/actions/workflows/release.yml/badge.svg)](https://github.com/wevertonj/decima/actions/workflows/release.yml)

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

## Instalação (Windows)

Baixe `decima-<versão>-windows-x64-setup.exe` em [Releases](https://github.com/wevertonj/decima/releases) e execute.

- Instalação **por usuário** — sem prompt de administrador
- O runtime C++ vai junto: **nenhum pré-requisito** para instalar
- Requer Windows 10 ou superior (x64)

> Por não ser assinado com certificado pago, o Windows exibe *"O Windows protegeu o seu PC"*. Clique em **Mais informações → Executar assim mesmo**. Confira o SHA-256 publicado no release antes de instalar.

Para gerar o instalador localmente, veja [`docs/fundacao/empacotamento-windows.md`](docs/fundacao/empacotamento-windows.md).

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

## Contribuição e Release

- Branch de trabalho: `dev` (padrão). A `main` só recebe código via **pull request** com CI verde
- Mensagens de commit seguem **Conventional Commits** (validadas por `commitlint` no CI)
- Merge na `main` dispara o release automático: bump SemVer + `CHANGELOG.md` + tag + APK no Firebase App Distribution + instalador Windows no GitHub Release

Detalhes em [`docs/fundacao/ci-cd.md`](docs/fundacao/ci-cd.md).
