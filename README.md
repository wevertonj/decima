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

## Instalação (Linux)

Baixe `decima-<versão>-linux-amd64.deb` em [Releases](https://github.com/wevertonj/decima/releases) e instale (Debian 12+, Ubuntu 22.04+ e derivados):

```bash
sudo dpkg -i decima-<versão>-linux-amd64.deb
```

- App em `/usr/lib/decima`, comando `decima` e entrada no menu de aplicativos
- **Sem pré-requisitos** além do GTK 3 do próprio sistema (o SQLite vai embutido)
- Confira o SHA-256 publicado no release antes de instalar
- Remover com `sudo dpkg -r decima` — o histórico em `~/.local/share/com.wevasoft.decima` é preservado

Sem root (ou em outra distro), compile o bundle e publique no menu do usuário:

```bash
flutter build linux --release
linux/packaging/install-desktop-entry.sh   # remover com --uninstall
```

- Exige `clang`, `cmake`, `ninja-build`, `pkg-config` e `libgtk-3-dev`
- A entrada e os ícones vão para `~/.local/share` — **sem `sudo`**

> Em Wayland, ter a entrada `.desktop` instalada (o `.deb` já instala) é o que dá ícone à janela: o GTK3 não tem como enviar o ícone pelo protocolo, e o compositor o resolve casando o `app_id` com o `.desktop`. Em X11 o ícone funciona mesmo rodando o bundle solto.

> Ainda em Wayland, a janela não reabre na última posição usada: o protocolo não permite que o app saiba onde está. Em X11 a posição é lembrada normalmente.

Detalhes do pacote `.deb` e demais formatos (AppImage/Flatpak/Snap) em [`docs/fundacao/empacotamento-linux.md`](docs/fundacao/empacotamento-linux.md).

## Instalação (macOS)

Sem artefato nos releases por enquanto — compile a partir do código (requer Xcode):

```bash
flutter build macos --release
open build/macos/Build/Products/Release/decima.app
```

> O `.app` usa assinatura ad-hoc. Se for baixado de outra máquina, o Gatekeeper bloqueia a abertura: autorize em **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**. Detalhes (e o fluxo de notarização, como referência) em [`docs/fundacao/empacotamento-macos.md`](docs/fundacao/empacotamento-macos.md).

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
