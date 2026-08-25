# Decima

[![CI](https://github.com/wevertonj/decima/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/wevertonj/decima/actions/workflows/ci.yml)
[![Release](https://github.com/wevertonj/decima/actions/workflows/release.yml/badge.svg)](https://github.com/wevertonj/decima/actions/workflows/release.yml)

Calculadora elegante e minimalista com entrada **Add2** — 2 casas decimais automáticas sem pressionar ponto.

## Funcionalidades

- **Add2** — Digitar `1250` exibe `12.50`. Suporte completo a +, −, ×, ÷, % e parênteses com aninhamento
- **Timeline** — Display scrollável: linha atual em branco, prévia do resultado em cinza, cálculos anteriores acima
- **Cursor editável** — Toque em qualquer ponto da expressão para inserir ou apagar no meio do cálculo, sem limpar tudo
- **Copiar e colar** — Toque longo (ou clique direito) no display abre o menu de contexto: copiar cálculo, resultado ou a sessão inteira. O colar aceita inteiros, decimais com ponto ou vírgula e expressões
- **Teclado físico** — Calculadora inteiramente operável por teclado, com o mesmo feedback visual do toque ([tabela de atalhos](docs/features/calculadora.md#atalhos-de-teclado))
- **Histórico** — Operações persistidas em SQLite, com paginação, favoritos, renomear entrada e filtro. Carregue uma sessão e continue o cálculo de onde parou
- **Nada se perde ao fechar** — A expressão em andamento é avaliada e gravada no encerramento, no `X` do desktop e no ciclo de vida do mobile
- **Temas** — Claro/escuro/sistema com 9 opções de seed color
- **Formato de número** — Separador decimal como ponto ou vírgula
- **Internacionalização** — Português, inglês e espanhol via arquivos ARB
- **Digitação rápida** — Toda ação passa por uma fila sequencial: nenhum toque é descartado durante animações

## Design

Inspirado na **One UI (Samsung)** — fundo escuro, botões circulares, acentos em amarelo/dourado e animações suaves.

No desktop a janela tem **tamanho fixo** (360 × 720) e **title bar própria** do app, sem a barra do sistema, e reabre na última posição usada.

## Stack

| Tecnologia | Uso |
|------------|-----|
| Flutter 3.44 / Dart 3 | Framework (versão pinada em `.fvmrc`) |
| ChangeNotifier / ValueNotifier | Gerenciamento de estado |
| SQLite (`sqflite` + `sqflite_common_ffi`) | Persistência local (mobile e desktop) |
| `shared_preferences` | Preferências (tema, separador, idioma, posição da janela) |
| `window_manager` / `screen_retriever` | Janela e title bar customizadas no desktop |
| GetIt | Injeção de dependência |
| `flutter_localizations` + ARB | Internacionalização |
| mocktail | Testes |

## Arquitetura

```
lib/
├── config/        # DI, rotas, tema
├── data/          # Repositories, database, models, services
├── domain/        # Entities, enums, motor de edição e avaliação da expressão
├── ui/
│   ├── calculator/  # Page, widgets e controllers (sessão, clipboard, timeline, cursor)
│   ├── core/        # Shell de desktop (title bar, janela) e mobile (ciclo de vida)
│   ├── history/
│   └── settings/
└── utils/         # Extensions, formatters, l10n
```

Nenhum arquivo de `lib/` ou `test/` passa de **600 linhas** — limite verificado no CI. Detalhes em [`docs/fundacao/arquitetura.md`](docs/fundacao/arquitetura.md).

## Instalação (Android)

Baixe `decima-<versão>-android.apk` em [Releases](https://github.com/wevertonj/decima/releases) e instale.

- Requer **Android 7.0 (API 24)** ou superior
- APK assinado com keystore de upload própria — o Android pede autorização para instalar de fonte desconhecida na primeira vez

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

Baixe `decima-<versão>-macos.zip` em [Releases](https://github.com/wevertonj/decima/releases) e extraia o app para `/Applications`:

```bash
ditto -x -k decima-<versão>-macos.zip /Applications
```

- Binário **universal** (Apple Silicon e Intel), macOS 10.15 ou superior
- **Sem pré-requisitos** — o Flutter e o SQLite vão dentro do bundle
- Confira o SHA-256 publicado no release antes de instalar

> O `.app` usa assinatura ad-hoc (sem certificado pago), então o Gatekeeper bloqueia a primeira abertura: feche com **Concluído** e autorize em **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**.

Para compilar localmente (requer Xcode):

```bash
flutter build macos --release            # ou tool/macos/build_zip.sh, que já gera o zip + .sha256
open build/macos/Build/Products/Release/Decima.app
```

Detalhes do empacotamento (e o fluxo de notarização, como referência) em [`docs/fundacao/empacotamento-macos.md`](docs/fundacao/empacotamento-macos.md).

## Desenvolvimento

A versão do Flutter é pinada em `.fvmrc` (**3.44.2**) e é a mesma usada pelo CI — com [FVM](https://fvm.app) instalado, prefixe os comandos com `fvm`.

```bash
# Rodar o app
flutter run

# Testes (774 no total)
flutter test

# Análise estática — o CI exige zero warnings
flutter analyze
dart format --set-exit-if-changed .

# Limite de 600 linhas por arquivo (mesmo check do CI)
dart run tool/check_file_length.dart
```

O projeto segue **TDD** rigorosamente. O CI reprova cobertura de linhas abaixo de **85%**.

## Documentação

Índice completo em [`docs/README.md`](docs/README.md).

| Documento | Conteúdo |
|-----------|----------|
| [`docs/fundacao/arquitetura.md`](docs/fundacao/arquitetura.md) | Camadas, estrutura de pastas e infra de desktop |
| [`docs/fundacao/padroes-codigo.md`](docs/fundacao/padroes-codigo.md) | Convenções, limites de tamanho e política de comentários |
| [`docs/fundacao/tema-design-system.md`](docs/fundacao/tema-design-system.md) | Cores, layout e animações |
| [`docs/fundacao/ci-cd.md`](docs/fundacao/ci-cd.md) | CI/CD, branches, release e distribuição |
| [`docs/features/calculadora.md`](docs/features/calculadora.md) | Add2, timeline, cursor, clipboard e atalhos de teclado |
| [`docs/features/historico.md`](docs/features/historico.md) | Histórico, paginação, favoritos e sessões |
| [`docs/features/configuracoes.md`](docs/features/configuracoes.md) | Tema, separador, idioma e janela |
| [`docs/qualidade/testes.md`](docs/qualidade/testes.md) | Estratégia de testes e TDD |

## Sobre o processo

Projeto pessoal, construído **inteiramente com IA** — do plano ao código, testes, empacotamento e documentação.

A pasta [`plano/`](plano/) fica versionada de propósito: o interesse aqui é registrar o **processo de desenvolvimento** para além do código final.

| Arquivo | Conteúdo |
|---------|----------|
| [`plano/plano.md`](plano/plano.md) | As 27 etapas do projeto, com escopo, testes, entregável e o status de fechamento de cada uma |
| [`plano/tarefas.md`](plano/tarefas.md) | Checklist executável, item a item, de todas as etapas |
| [`plano/changelog.md`](plano/changelog.md) | Diário de bordo do desenvolvimento — decisões, becos sem saída e correções de rota |
| [`plano/observacoes.md`](plano/observacoes.md) | Inventário de manutenibilidade que guiou o ciclo de refatoração (etapas 19–23) |

São ~4.700 linhas de planejamento para ~70 arquivos de código. Esse modelo de plano tem **consumo altíssimo de tokens** e não é mais o que uso em projetos novos — mas o Decima começou nele e foi levado até o fim assim, por consistência e para deixar o registro completo de um ciclo inteiro sob o mesmo método.

## Contribuição e Release

- Branch de trabalho: `dev` (padrão). A `main` só recebe código via **pull request** com os 7 checks verdes (`commitlint`, `analyze`, `test`, e os builds de Android, Linux, Windows e macOS)
- Mensagens de commit seguem **Conventional Commits** (validadas por `commitlint` no CI)
- Merge na `main` dispara o release automático: bump SemVer + `CHANGELOG.md` + tag + APK, instalador Windows, `.deb` Linux e zip do macOS no GitHub Release

Detalhes em [`docs/fundacao/ci-cd.md`](docs/fundacao/ci-cd.md).

## Licença

[BSD 3-Clause](LICENSE) — © 2026 Weverton J. da Silva.
