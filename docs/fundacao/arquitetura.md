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
│       ├── desktop/           # Infra de janela (config, init, close handler, posição)
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

## Infra de Desktop

Compartilhada entre Windows, Linux e macOS. Fica em `lib/ui/core/desktop/` (lógica de janela) e `lib/ui/core/widgets/` (widgets do shell).

| Artefato | Responsabilidade |
|----------|------------------|
| `DesktopWindowConfig` | Constantes da janela: tamanho fixo (`360 × 720`), título nativo, altura da title bar |
| `initDesktopWindow()` | Chamado antes de `runApp` em desktop: `WindowOptions` com `TitleBarStyle.hidden`, `setResizable(false)`, `setMaximizable(false)` (exceto Linux), restauração da última posição |
| `AppTitleBar` | Title bar customizada: `DragToMoveArea` + logo/nome à esquerda, minimizar/fechar à direita |
| `DesktopShell` | Envolve o app com a `AppTitleBar` **apenas** em desktop; em mobile devolve o `child` intacto |
| `WindowCloseHandler` | Intercepta o fechamento da janela para gravar a sessão e a posição antes de o processo terminar |
| `isWindowPositionReachable()` | Função pura: valida a posição salva contra os monitores atuais (`window_position.dart`) |
| `isWindowPositionStorable()` | Função pura: decide se a posição lida do plugin merece ser gravada (`window_position.dart`) |
| `PlatformInfo.isDesktop` / `.isLinux` / `.isWindows` / `.isMacOS` | Detecção de plataforma via `defaultTargetPlatform` (e não `Platform`), sobrescritível nos testes |

### Fechamento da janela

`WindowCloseHandler` liga `setPreventClose(true)` e escuta `WindowListener.onWindowClose`. O pedido de fechamento — `X` da title bar, `Alt+F4` ou "Fechar janela" da barra de tarefas — vira: `onFlush()` (hoje `CalculatorViewModel.flushSession()`) → `windowManager.destroy()`.

| Garantia | Como |
|----------|------|
| A janela sempre fecha | `destroy()` fica no `finally`; exceção da gravação é engolida |
| Gravação travada não prende o app | `onFlush().timeout(flushTimeout)` — 3 s por padrão |
| A janela some da tela na hora | `WindowManagerCloseBridge.destroy()` desvia do `PostQuitMessage` no Windows — ver abaixo |
| Um pedido de fechamento por vez | Trava `_closing`, ligada no primeiro `onWindowClose` e solta só se o `destroy()` falhar |
| Testável sem method channel | Toda chamada ao plugin passa por `WindowCloseBridge`; os testes injetam uma ponte falsa |
| Inerte em mobile | `initState` retorna antes de registrar qualquer coisa quando `!PlatformInfo.isDesktop` |

#### `destroy()` por plataforma

`windowManager.destroy()` não tem a mesma semântica nos três desktops:

| Plataforma | O que o plugin faz | Efeito na janela |
|------------|--------------------|------------------|
| Linux | `_is_prevent_close = false` + `gtk_window_close()` | Some na hora |
| macOS | `NSApp.terminate(nil)` | Some na hora |
| Windows | `PostQuitMessage(0)` | **Continua na tela** durante todo o desligamento do engine |

No Windows o `PostQuitMessage` só enfileira `WM_QUIT`: nenhuma janela é destruída, e o `X` fica sem resposta pelos segundos que o engine leva para encerrar. `WindowManagerCloseBridge.destroy()` troca esse caminho por `setPreventClose(false)` + `close()` — o novo `WM_CLOSE` chega ao `DefWindowProc`, que chama `DestroyWindow` e devolve o fechamento instantâneo do runner padrão.

O preço é um eco: o plugin emite o evento `close` **antes** de consultar o `preventClose`, então esse `close()` reentra no handler como um novo `onWindowClose`. A trava `_closing` absorve o eco — e, de quebra, cliques repetidos no `X` enquanto as gravações rodam.

O handler é montado no `MaterialApp.builder` do `_DecimaAppState`, acima do `DesktopShell`. Em mobile o papel equivalente é do `AppLifecycleListener` (`onHide` / `onPause` / `onExitRequested`) registrado no mesmo state.

As duas gravações do fechamento — sessão e posição — rodam em `Future.wait` (sem `eagerError`) sob o mesmo `flushTimeout`: uma travada ou com erro não impede a outra, e nenhuma impede o `destroy()`.

### Memória da posição da janela

A janela reabre onde o usuário a deixou. O caminho completo:

| Etapa | Onde | O quê |
|-------|------|-------|
| Gravar | `WindowCloseHandler` → `onSavePosition` | `windowManager.getPosition()` → `isWindowPositionStorable()` → `SettingsRepository.setWindowPosition(x, y)` |
| Ler | `initDesktopWindow()` | `getWindowPosition()` antes de montar as `WindowOptions` |
| Validar | `isWindowPositionReachable()` | Posição salva × `screenRetriever.getAllDisplays()` |
| Aplicar | `waitUntilReadyToShow` | `center: position == null`; `setPosition` **antes** do `show()` |

| Chave em `SharedPreferences` | Tipo | Conteúdo |
|------------------------------|------|----------|
| `window_x` | `double` | Coordenada X do canto superior esquerdo, em pixels lógicos |
| `window_y` | `double` | Coordenada Y do canto superior esquerdo, em pixels lógicos |

**Regra de alcançabilidade** — o critério é a **title bar**, que é por onde a janela se move. Somando as interseções da faixa `windowSize.width × titleBarHeight` com a área útil de cada monitor, é preciso alcançar `minGrabWidth × titleBarHeight` (80 × 40 px). Somar entre displays mantém válida a janela repartida entre dois monitores adjacentes. Caem no centro: posição ausente, `NaN`/infinito, lista de displays vazia, monitor desconectado, e mudança de resolução ou de DPI que tenha deixado a title bar fora de alcance.

**Regra de gravação** — `isWindowPositionStorable()` descarta `NaN`/infinito e, **em Linux**, a origem exata `(0,0)`: no Wayland o protocolo não expõe coordenadas globais e `getPosition()` sempre devolve a origem, então gravá-la reabriria a janela encostada no canto em vez de centralizada. O custo do falso negativo em X11 (janela realmente no canto) é abrir centralizada da próxima vez. Detalhes em [`empacotamento-linux.md`](empacotamento-linux.md).

`WindowPosition` (`domain/entities/`) trafega `double` puro em vez de `Offset` — repositórios não importam Flutter. A conversão para `Offset` acontece só na fronteira com o `window_manager`.

## Segurança e Cibersegurança

| Vetor | Risco no contexto | Regra aplicada |
|-------|-------------------|----------------|
| Entrada não confiável (OWASP A03 — Injection) | `shared_preferences.json` e `decima.db` são arquivos editáveis pelo usuário ou por outro processo do mesmo perfil | Todo valor lido é validado ou tem default: `getWindowPosition()` exige as duas chaves; `isWindowPositionReachable()` descarta `NaN`/infinito e coordenadas fora dos monitores; enums caem no `orElse` |
| Estado inutilizável (DoS local) | Uma posição corrompida abriria a janela fora da tela — o app existiria sem forma de ser usado | Fallback para `center: true`; a title bar precisa de área alcançável em algum display |
| App impossível de fechar | `setPreventClose(true)` sem `destroy()` garantido prende o processo | `destroy()` no `finally`, gravações sob `flushTimeout` |
| Armazenamento local (OWASP M9 — Insecure Data Storage) | Histórico e preferências podem conter dados financeiros | Persistência restrita ao perfil do usuário (`%APPDATA%\Wevasoft\Decima` no Windows, diretório privado do app em mobile); sem criptografia por decisão de escopo — nenhum segredo é gravado |
| Exposição em log | Expressões, resultados e caminhos de arquivo | Nenhum `print`/log de dado do usuário em runtime |
| Menor privilégio | — | App 100% offline: sem permissão de rede, sem telemetria, sem serviço externo; a única dependência de plataforma é janela/preferências/SQLite |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| `initDesktopWindow()` depende do `SettingsRepository` | Ler a posição salva antes de `setupDependencies()` explodiria no `getIt` | Em `main()`, `setupDependencies()` vem **antes** do branch de plataforma; o repositório é injetado por parâmetro |
| `setPosition` depois do `show()` | A janela aparece no centro e "pula" para a posição salva | Reposicionar dentro do `waitUntilReadyToShow`, antes do `show()` |
| `center: true` com posição salva | O `WindowOptions.center` sobrescreve o `setPosition` | `center: position == null` |
| `screen_retriever` era dependência transitiva | Importar `Display` direto de um pacote não declarado quebra em `pub upgrade` | Declarado em `dependencies` no `pubspec.yaml` |
| `Display.visiblePosition`/`visibleSize` são nulos em algumas plataformas | Validar contra `null` descartaria posições válidas | Fallback para `Offset.zero` + `display.size` |
| Posição gravada só no fechamento | Encerramento anormal (crash, corte de energia) perde a última posição | Aceito — menos I/O que salvar a cada `onWindowMoved`; a alternativa com debounce fica documentada aqui, sem implementar |
| Plugin de janela não roda em `flutter test` | Method channels indisponíveis tornam o handler intestável | `WindowCloseBridge` abstrai o plugin; a regra de posição é função pura, testada sem plugin |
| `windowManager.getPosition()` devolve pixels **lógicos** | Misturar com coordenadas físicas erra a posição em telas com DPI ≠ 100% | Gravar e restaurar sempre pelo `window_manager`, nunca por API nativa direta |
| A mesma chamada do `window_manager` tem semântica diferente por plataforma | `setMaximizable(false)` vira `_NET_WM_WINDOW_TYPE_DIALOG` no GTK; `getPosition()` devolve `(0,0)` no Wayland | Desvios concentrados em `PlatformInfo.isLinux` e em funções puras testáveis — ver [`empacotamento-linux.md`](empacotamento-linux.md) |
| `destroy()` no Windows é `PostQuitMessage(0)`, não `DestroyWindow` | Com `setPreventClose(true)` a janela fica na tela segundos após o clique no `X` — o app parece travado | `WindowManagerCloseBridge.destroy()` usa `setPreventClose(false)` + `close()` no Windows |
| O `close()` do Windows reemite o evento `close` | Sem trava, o handler reentra em `_flushAndDestroy` durante o próprio fechamento | Trava `_closing` no `onWindowClose`, liberada só quando o `destroy()` falha |
