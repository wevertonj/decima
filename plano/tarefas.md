# Tarefas — Decima

Checklist detalhado de cada etapa. Marque `[x]` conforme concluir.

---

## Etapa 1 — Fundação e Infraestrutura ✅

### Dependências

- [x] Atualizar `pubspec.yaml` com: `get_it`, `sqflite`, `path`, `shared_preferences`, `flutter_localizations`, `intl`
- [x] Adicionar dev_dependencies: `mocktail`, `sqflite_common_ffi` (para testes)
- [x] Rodar `flutter pub get`

### Estrutura de Pastas

- [x] Criar `lib/config/`
- [x] Criar `lib/config/theme/`
- [x] Criar `lib/data/database/`
- [x] Criar `lib/data/repositories/`
- [x] Criar `lib/data/models/`
- [x] Criar `lib/domain/entities/`
- [x] Criar `lib/domain/enums/`
- [x] Criar `lib/ui/calculator/widgets/`
- [x] Criar `lib/ui/history/widgets/`
- [x] Criar `lib/ui/settings/widgets/`
- [x] Criar `lib/ui/core/widgets/`
- [x] Criar `lib/utils/extensions/`
- [x] Criar `lib/utils/formatters/`
- [x] Criar `lib/utils/l10n/`

### Tema e Layout

- [x] Implementar `AppLayout` (spacing, padding, radius) — `lib/config/theme/app_layout.dart`
- [x] Implementar `AppColors` (9 seed colors) — `lib/config/theme/app_colors.dart`
- [x] Implementar `AppTheme` (ThemeData claro/escuro) — `lib/config/theme/app_theme.dart`

### Configuração

- [x] Criar `lib/config/dependencies.dart` (GetIt setup inicial)
- [x] Criar `lib/config/routes.dart` (rotas nomeadas: /, /history, /settings)

### Internacionalização

- [x] Criar `l10n.yaml` na raiz
- [x] Criar `lib/utils/l10n/app_pt.arb` (português base) + `app_pt_BR.arb` (brasileiro)
- [x] Criar `lib/utils/l10n/app_es.arb` (espanhol)
- [x] Criar `lib/utils/l10n/app_en.arb` (inglês)
- [x] Criar extension `context.l10n` em `lib/utils/extensions/l10n_extension.dart`
- [x] Configurar `flutter generate: true` no pubspec.yaml

### App Shell

- [x] Reescrever `lib/main.dart` com MaterialApp usando AppTheme, rotas e l10n

### Testes — Etapa 1

- [x] Criar `test/unit/config/theme/app_layout_test.dart`
- [x] Criar `test/unit/config/theme/app_colors_test.dart`
- [x] Criar `test/unit/config/theme/app_theme_test.dart`
- [x] `flutter test` — 100% verde (27 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 2 — Domínio e Camada de Dados (base) ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/fixtures/` com dados de teste reutilizáveis
- [x] Criar `test/mocks/` com mocks centralizados
- [x] Criar `test/unit/domain/entities/calculation_test.dart`
- [x] Criar `test/unit/domain/entities/history_entry_test.dart`
- [x] Criar `test/unit/domain/enums/operation_type_test.dart`
- [x] Criar `test/unit/data/models/history_model_test.dart`
- [x] Criar `test/unit/data/repositories/history_repository_test.dart`

### Implementação (TDD Green)

- [x] Implementar `Calculation` — `lib/domain/entities/calculation.dart`
- [x] Implementar `HistoryEntry` — `lib/domain/entities/history_entry.dart`
- [x] Implementar `OperationType` — `lib/domain/enums/operation_type.dart`
- [x] Implementar `ThemeModeOption` — `lib/domain/enums/theme_mode_option.dart`
- [x] Implementar `DecimalSeparator` — `lib/domain/enums/decimal_separator.dart`
- [x] Implementar `HistoryModel` — `lib/data/models/history_model.dart`
- [x] Implementar `AppDatabase` — `lib/data/database/app_database.dart`
- [x] Implementar `HistoryRepository` (interface) — `lib/data/repositories/history_repository.dart`
- [x] Implementar `HistoryRepositoryImpl` — `lib/data/repositories/history_repository_impl.dart`
- [x] Registrar database e repository no GetIt

### Validação

- [x] `flutter test` — 100% verde (66 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação) ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/domain/entities/history_entry_test.dart`
  - Cenários: criação com name e isFavorite, copyWith com novos campos, equality com novos campos
- [x] Atualizar `test/unit/data/models/history_model_test.dart`
  - Cenários: toMap/fromMap/toEntity/fromEntity com name e isFavorite
- [x] Atualizar `test/unit/data/repositories/history_repository_test.dart`
  - Cenários: getPaginated, getFavorites, updateName, toggleFavorite, getById
- [x] Atualizar `test/fixtures/history_fixtures.dart` com novos campos

### Implementação (TDD Green)

- [x] Adicionar `name` (String?) e `isFavorite` (bool) em `HistoryEntry`
- [x] Atualizar `HistoryEntry.copyWith` com novos campos
- [x] Atualizar `HistoryModel` com novos campos (toMap, fromMap, toEntity, fromEntity)
- [x] Atualizar schema SQLite: adicionar colunas `name TEXT` e `is_favorite INTEGER NOT NULL DEFAULT 0`
- [x] Adicionar novos métodos à interface `HistoryRepository`:
  - `getPaginated(limit, offset)`
  - `getFavorites(limit, offset)`
  - `updateName(id, name)`
  - `toggleFavorite(id)`
  - `getById(id)`
- [x] Implementar novos métodos em `HistoryRepositoryImpl`

### Validação

- [x] `flutter test` — 100% verde (98 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 3 — Motor da Calculadora ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/domain/add2_engine_test.dart`
  - Cenários: dígitos simples, sequência de dígitos, backspace, 00, 000, reset, valores limite
- [x] Criar `test/unit/domain/expression_evaluator_test.dart`
  - Cenários: soma, subtração, multiplicação, divisão, precedência, %, divisão por zero, expressão inválida
- [x] Criar `test/unit/utils/formatters/number_formatter_test.dart`
  - Cenários: ponto, vírgula, milhar, sem decimais, negativos
- [x] Criar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: estado inicial, inputDigit, operação, =, C, ⌫, timeline, load more na timeline, prévia resultado, persistência no histórico, carregamento de sessão

### Implementação (TDD Green)

- [x] Implementar `Add2Engine` — `lib/domain/add2_engine.dart`
- [x] Implementar `ExpressionEvaluator` — `lib/domain/expression_evaluator.dart`
- [x] Implementar `NumberFormatter` — `lib/utils/formatters/number_formatter.dart`
- [x] Implementar `CalculatorViewModel` — `lib/ui/calculator/calculator_view_model.dart`
  - Timeline com limite visível e load more
- [x] Registrar CalculatorViewModel no GetIt

### Validação

- [x] `flutter test` — 100% verde (224 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 4 — Lógica do Histórico e Configurações ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/ui/history/history_view_model_test.dart`
  - Cenários: carregamento paginado, loadMore, hasMore, deleção individual, limpar tudo, rename, toggleFavorite, filtro favoritos, notificações
- [x] Criar `test/unit/data/repositories/settings_repository_test.dart`
  - Cenários: salvar/carregar ThemeMode, seedColor, decimalSeparator, locale
- [x] Criar `test/unit/ui/settings/settings_view_model_test.dart`
  - Cenários: estado inicial, alteração de cada preferência, persistência via repository

### Implementação (TDD Green)

- [x] Implementar `HistoryViewModel` — `lib/ui/history/history_view_model.dart`
  - Carregamento paginado (loadMore, hasMore)
  - Deleta, limpa, rename, toggleFavorite
  - Filtro: todos / favoritos
  - Notifica listeners
- [x] Implementar `SettingsRepository` (interface) — `lib/data/repositories/settings_repository.dart`
- [x] Implementar `SettingsRepositoryImpl` — `lib/data/repositories/settings_repository_impl.dart`
  - SharedPreferences para ThemeMode, seedColor, decimalSeparator, locale
- [x] Implementar `SettingsViewModel` — `lib/ui/settings/settings_view_model.dart`
  - Gerencia preferências, persiste via repository, notifica listeners
- [x] Registrar SettingsRepository, HistoryViewModel e SettingsViewModel no GetIt

### Validação

- [x] `flutter test` — 100% verde (277 testes)
- [x] `flutter analyze` — zero warnings
- [x] Verificar: nenhum ViewModel importa Flutter (exceto foundation.dart)

---

## Etapa 5 — UI da Calculadora ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/widget/calculator/calculator_button_test.dart`
- [x] Criar `test/widget/calculator/calculator_keypad_test.dart`
- [x] Criar `test/widget/calculator/timeline_display_test.dart`
- [x] Criar `test/widget/calculator/calculator_page_test.dart`

### Implementação (TDD Green)

- [x] Implementar `CalculatorButton` — `lib/ui/calculator/widgets/calculator_button.dart`
  - AnimatedContainer com feedback de toque, variantes (numérico, operador, ação)
  - Efeito reactive typing (glow LED 500ms) e flash de fundo (80ms)
- [x] Implementar `CalculatorKeypad` — `lib/ui/calculator/widgets/calculator_keypad.dart`
  - Grid 5×4 com layout documentado
- [x] Implementar `TimelineDisplay` — `lib/ui/calculator/widgets/timeline_display.dart`
  - ListView scrollável, linhas com cores diferenciadas, auto-scroll
  - Botão "load more" no topo para carregar cálculos anteriores da sessão
  - AnimatedSwitcher para prévia de resultado
- [x] Implementar `CalculatorPage` — `lib/ui/calculator/calculator_page.dart`
  - Scaffold com timeline + barra de ícones + keypad
- [x] Barra de ícones: ⏱ (histórico) e ⚙ (configurações) — navegação sem destino por enquanto
- [x] Atualizar strings nos arquivos ARB (botões, labels, "load more")
- [x] Atualizar `AppColors` com novas seed colors e cores de superfície
- [x] Atualizar `AppTheme` com cores de fundo customizadas
- [x] Conectar rota `/` ao `CalculatorPage` com ViewModel do GetIt
- [x] Criar `test/helpers/pump_app.dart` — helper de teste para widget tests

### Validação

- [x] `flutter test` — 100% verde (318 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 6 — Exibição literal da porcentagem ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: `expression` mantém `%` literal após `applyPercentage`, `previewResult` calcula corretamente, `=` produz o mesmo resultado de antes, encadeamento após `%`
- [x] Atualizar `test/unit/domain/expression_evaluator_test.dart`
  - Cenários: parsing de expressões com `%` literal em `+`, `−`, `×`, `÷`
- [x] Timeline display recebe texto pronto do ViewModel — sem alterações necessárias no widget test

### Implementação (TDD Green)

- [x] Ajustar `CalculatorViewModel.applyPercentage` para inserir token `%` literal na expressão (sem alterar o número)
- [x] Garantir que `previewResult` continua resolvendo o `%` corretamente
- [x] Garantir que `=` persiste a expressão literal com `%` no histórico
- [x] `ExpressionEvaluator` já consome `%` literal sem espaço (tokenizer separa o `%` automaticamente)
- [x] `loadSession` resetando o flag `_currentIsPercentage` ao carregar sessão

### Validação

- [x] `flutter test` — 100% verde (349 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: nenhum teste das Etapas 3/5 quebrado

---

## Etapa 7 — Fila de processamento de toques (anti-perda em digitação rápida) ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenário: enfileirar 50 ações em rajada e validar a ordem e o estado final
  - Cenário: ações despachadas durante processamento são preservadas
- [x] Atualizar `test/widget/calculator/calculator_keypad_test.dart`
  - Cenário: `tester.tap` em rajada (sem `pumpAndSettle` entre toques) reflete todos os dígitos
- [x] Atualizar `test/widget/calculator/calculator_button_test.dart`
  - Cenário: botão permanece responsivo durante animação de feedback
  - Cenário: `onPressed` dispara no `onTapDown` (não aguarda `tapUp`)

### Implementação (TDD Green)

- [x] Auditar pipeline `CalculatorButton` → `CalculatorKeypad` → `CalculatorViewModel`
- [x] Implementar fila (`Queue<VoidCallback>`) no `CalculatorViewModel` com proteção de reentrância
- [x] Despachar toques imediatamente; ações reentrantes (via listener) entram na fila e são processadas após a atual
- [x] Garantir que animações (flash, glow LED) permanecem independentes do despacho
- [x] Ajustar `CalculatorButton` para disparar `onPressed` no `onTapDown` (latência mínima)
- [x] `GestureDetector` mantém `behavior: HitTestBehavior.opaque`
- [x] Sem `debounce`/`throttle` descartando eventos

### Validação

- [x] `flutter test` — 100% verde (357 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: testes das Etapas 5 e 6 continuam verdes

---

## Etapa 8 — Reorganização do keypad: delete contextual e parênteses ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/domain/expression_evaluator_test.dart`
  - Cenários: parênteses simples, aninhados, com `%`, parênteses desbalanceados, parênteses vazios
- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: `inputParenthesis` em diferentes estados, contador `openParenCount`, `hasContent` reativo, `clearAll`
- [x] Atualizar `test/widget/calculator/calculator_keypad_test.dart`
  - Cenários: novo layout (sem ⚙ no keypad, `C` no lugar, `( )` no lugar do `⌫`)
- [x] Atualizar `test/widget/calculator/calculator_button_test.dart`
  - Cenários: botão `C` muda de cor conforme `hasContent` (com animação)
- [x] Atualizar `test/widget/calculator/calculator_page_test.dart`
  - Cenários: barra de ícones contém ⏱ e ⚙ lado a lado

### Implementação (TDD Green)

- [x] Mover ⚙ (configurações) para a barra de ícones, ao lado do ⏱
- [x] Implementar botão `C` (apagar tudo) no slot antigo do ⚙
  - Cor padrão quando vazio, `primary` quando há conteúdo
  - Transição animada de cor (sem mudança "seca")
- [x] Implementar botão `( )` no slot antigo do `⌫` com toggle inteligente
  - Insere `(` quando não há parêntese aberto pendente
  - Insere `)` quando há parêntese aberto e último token permite fechamento (número, `%`, `)`)
  - Insere novo `(` após operador
- [x] Adicionar `inputParenthesis()`, `openParenCount` e `hasContent` no `CalculatorViewModel`
- [x] Adicionar `clearAll()` no `CalculatorViewModel` (ou renomear/ajustar a ação de clear existente)
- [x] Estender `ExpressionEvaluator` com suporte completo a parênteses aninhados
- [x] Tratar parênteses não fechados ao pressionar `=` (auto-fechar ou bloquear com feedback)
- [x] Atualizar ARBs com strings `clearAll`, `parenthesis`
- [x] Garantir renderização correta dos parênteses no `TimelineDisplay` e histórico

### Validação

- [x] `flutter test` — 100% verde (394 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: testes anteriores continuam verdes
- [x] Teste manual: expressões com parênteses aninhados funcionam (ex: `(10.00 × 50.00) + 30.00 + (48.00 ÷ (18.00 × 1.50%))`)

---

## Etapa 9 — UI do Histórico e Configurações ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/widget/history/history_page_test.dart`
- [x] Criar `test/widget/settings/settings_page_test.dart`

### Implementação (TDD Green)

- [x] Implementar `HistoryPage` — `lib/ui/history/history_page.dart`
  - Lista paginada em ordem cronológica inversa (mais recente primeiro)
  - Botão "load more" no final da lista
  - Cada item mostra: nome (se houver), expressão (truncada se longa), resultado e data/hora
  - Ícone de favorito (★) em cada item — toque para alternar
  - Filtro: Todos / Favoritos (tabs ou toggle)
  - Toque longo ou menu: renomear entrada
  - Expressões longas truncadas com "..." (expandível)
  - Animação de entrada para cada item da lista
  - Ação limpar com diálogo de confirmação
- [x] Implementar widgets auxiliares em `lib/ui/history/widgets/`
  - `HistoryListItem` — card individual com nome, expressão truncável, resultado, data/hora, favorito, renomear via long press
- [x] Implementar `SettingsPage` — `lib/ui/settings/settings_page.dart`
  - Seção tema (modo + seed color com círculos coloridos)
  - Seção formato de número (toggle ponto/vírgula)
  - Seção idioma (seletor)
  - Toda mudança reflete imediatamente com animação suave
- [x] Implementar widgets auxiliares em `lib/ui/settings/widgets/`
  - `ThemeModeSelector` — segmented button para modo do tema
  - `ColorPicker` — row de círculos coloridos com check animado
  - `DecimalSeparatorSelector` — toggle para formato de número
  - `LanguageSelector` — seletor de idioma com ChoiceChips
- [x] Integrar navegação completa: ⏱ → HistoryPage, ⚙ → SettingsPage
- [x] Integrar Timeline ↔ Histórico: tocar item → retorna entry via Navigator.pop → CalculatorPage chama loadSession
- [x] Integrar com `main.dart`: carregar preferências no startup, propagar tema/cor/locale reativamente
- [x] Atualizar ARBs com strings do histórico e configurações (favoritos, renomear, load more, etc.)

### Validação

- [x] `flutter test` — 100% verde (430 testes)
- [x] `flutter analyze` — zero warnings
- [x] Teste manual: navegação e fluxos funcionam corretamente

---

## Etapa 10 — Copiar e Colar ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/ui/calculator/clipboard_service_test.dart`
  - Cenários: copiar texto, ler texto, área de transferência vazia
- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: colar número inteiro (conversão Add2), colar decimal com ponto, colar decimal com vírgula, colar expressão válida, colar texto inválido (retorna erro), colar quando display está vazio
- [x] Criar `test/widget/calculator/context_menu_test.dart`
  - Cenários: toque longo no display abre o menu, opções condicionais conforme estado, copiar fecha menu, colar fecha menu, dado inválido exibe snackbar

### Implementação (TDD Green)

- [x] Criar `lib/data/services/clipboard_service.dart` — interface `ClipboardService`
  - `Future<void> copyText(String text)` — copia para área de transferência
  - `Future<String?> readText()` — lê da área de transferência (null se vazia)
- [x] Criar `lib/data/services/clipboard_service_impl.dart` — implementação com `Clipboard` do Flutter
- [x] Criar `test/mocks/mock_clipboard_service.dart` — mock com mocktail
- [x] Registrar `ClipboardService` no GetIt (`dependencies.dart`)
- [x] Adicionar lógica de validação e normalização de entrada colada (extraída para `lib/utils/paste_input_parser.dart`):
  - Normalização: separadores de milhar ignorados, vírgula decimal convertida para ponto
  - Números inteiros isolados: convertidos via Add2 (ex: `1250` → `12.50`); inteiros dentro de expressão preservam valor
  - Números com casas decimais: preservar as casas decimais existentes
  - Expressões (`10 + 5`, `100 × 3`, `(10 + 5) × 2`, `100 + 10%`): parse e insert no estado da calculadora
  - Entrada inválida: retorna sinalização de erro sem alterar estado
- [x] Implementar `pasteFromClipboard()` no `CalculatorViewModel`
- [x] Implementar `copyExpression()`, `copyResult()`, `copyHistory()` no `CalculatorViewModel`
- [x] Adicionar estado `hasExpression`, `hasResult`, `hasHistory` derivados para controlar visibilidade dos itens do menu
- [x] Implementar o widget de menu de contexto em `lib/ui/calculator/widgets/calculator_context_menu.dart`
  - Abrir com `GestureDetector.onLongPressStart` no display
  - Animação nativa do `showMenu` (Material) com `RoundedRectangleBorder` no raio do tema
  - Opções: "Copiar cálculo", "Copiar resultado", "Copiar histórico", "Colar"
  - Cada opção visível/invisível conforme estado; "Colar" desabilitada se área de transferência vazia
- [x] Integrar o menu de contexto ao `TimelineDisplay` na `CalculatorPage`
- [x] Implementar snackbar de erro para dado colado inválido (texto via `context.l10n.*`)
- [x] Adicionar strings ARB para todas as novas labels:
  - `copyExpression`, `copyResult`, `copyHistory`, `paste`, `pasteInvalid`, `copied`

### Validação

- [x] `flutter test` — 100% verde (482 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: testes anteriores continuam verdes
- [x] Teste manual: colar número, decimal, expressão e dado inválido

---

## Etapa 11 — Cursor Editável no Display ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: `cursorPosition`, inserção no meio, backspace no meio, `moveCursorLeft/Right`, bounds checking
- [x] Criar `test/widget/calculator/animated_input_display_cursor_test.dart`
  - Cenários: cursor visível na posição correta, toque em caractere posiciona o cursor

### Implementação (TDD Green)

- [x] Adicionar `cursorPosition` (int) no `CalculatorViewModel`
- [x] Implementar `moveCursorLeft()` / `moveCursorRight()` com bounds checking
- [x] Ajustar `inputDigit`, `deleteLastDigit`, `selectOperator` para respeitar a posição do cursor
- [x] Adicionar props `cursorPosition` e `cursorColor` ao `AnimatedInputDisplay`
- [x] Renderizar cursor (barra vertical piscante via `Timer`, não `AnimationController`) com altura proporcional ao fontSize
- [x] `GestureDetector` em cada caractere com callback `onCharTap(int index)`
- [x] Gesto de swipe horizontal no display para mover cursor (esquerda/direita)

### Validação

- [x] `flutter test` — 100% verde (499 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: testes anteriores continuam verdes

---

## Etapa 12 — Logo customizado e identidade visual ✅

### Preparação

- [x] Importar logo em `assets/branding/logo.png`
- [x] Adicionar variantes de densidade em `assets/branding/2.0x/logo.png` e `assets/branding/3.0x/logo.png`
- [x] Criar versão adaptativa Android (fundo `#181818` + foreground via `flutter_launcher_icons`)

### Geração de ícones e splash

- [x] Adicionar `flutter_launcher_icons` em `dev_dependencies`
- [x] Configurar `flutter_launcher_icons.yaml` para Android, iOS, web, Windows, Linux, macOS
- [x] Rodar `dart run flutter_launcher_icons` e versionar artefatos
- [x] Adicionar `flutter_native_splash` em `dev_dependencies`
- [x] Configurar `flutter_native_splash.yaml` (cores do tema, logo central, Android 12+)
- [x] Rodar `dart run flutter_native_splash:create`

### Implementação no app

- [x] Criar widget `AppLogo` em `lib/ui/core/widgets/app_logo.dart` (usa `Image.asset`)
- [x] Declarar assets de branding no `pubspec.yaml`

### Testes

- [x] Criar `test/widget/core/widgets/app_logo_test.dart`
  - Cenários: widget renderiza, asset correto, tamanho aplicado, tamanho padrão
- [x] Verificação manual: ícone do app aparece em cada plataforma
- [x] Verificação manual: splash aparece com a arte correta

### Validação

- [x] `flutter test` — 100% verde (513 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 13 — Suporte a teclado físico ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/ui/calculator/keyboard_shortcuts_test.dart`
  - Cenários: cada `LogicalKeyboardKey` mapeia para o método correto do ViewModel
- [x] Criar `test/widget/calculator/keyboard_shortcuts_handler_test.dart`
  - Cenários: dígitos, operadores, Enter, Backspace, Esc/Delete, %, parênteses, Ctrl/Cmd+C/V
  - Cenário: feedback visual (glow) é disparado pela tecla física
  - Cenário: Backspace em estado vazio não quebra o app

### Implementação (TDD Green)

- [x] Criar `lib/ui/calculator/widgets/keyboard_shortcuts_handler.dart`
  - Mapeamento em `lib/ui/calculator/keyboard_shortcuts.dart` (função pura `KeyboardShortcuts.resolve`) + `Focus.onKeyEvent` no handler
  - Cada ação chama método do `CalculatorViewModel`, passando pela fila de toques
- [x] Envolver `CalculatorPage` com `Focus(autofocus: true)` + handler
- [x] Expor feedback visual reutilizável em `CalculatorButton` via `KeyFlashController` (`ValueNotifier<KeyFlash?>`)
- [x] Garantir que campos de texto (rename do histórico) não interceptam atalhos globais
- [x] Documentar atalhos em `docs/features/calculadora.md`
- [x] Entradas ARB — não necessárias (reaproveitadas `copied` e `pasteInvalid` para o feedback de `Ctrl/Cmd+C/V`)

### Validação

- [x] `flutter test` — 100% verde (583 testes)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: toques no teclado virtual continuam funcionando
- [x] Teste manual: operação completa apenas via teclado físico — validado no Windows desktop (Etapa 14), incluindo colar com os dados de `plano/fixtures-colar.md`

---

## Etapa 14 — Suporte a Windows (com infra de desktop e title bar customizada) ✅

### Habilitação da plataforma

- [x] Rodar `flutter create --platforms=windows .` — runner já existia desde a criação do projeto; `flutter pub get` regenerou os plugin registrants com `window_manager`
- [x] Adicionar `window_manager` em `dependencies`
- [x] Conferir que `flutter build windows` compila — via bridge WSL→Windows: Flutter 3.44.2 do host (FVM no Windows) sobre cópia de build no filesystem do Windows (detalhes da máquina em `plano/local/ambiente.md`, não versionado)

### Infra de desktop compartilhada

- [x] Criar `lib/ui/core/desktop/desktop_window_config.dart`
  - Constantes de tamanho fixo (360 × 720), título do app e altura da title bar
- [x] Criar `lib/ui/core/desktop/desktop_window_initializer.dart`
  - `Future<void> initDesktopWindow()` com `windowManager.ensureInitialized`, `WindowOptions` (size, min/max iguais, center, `TitleBarStyle.hidden`), `setResizable(false)`, `setMaximizable(false)`
- [x] Criar `lib/ui/core/widgets/app_title_bar.dart`
  - `DragToMoveArea`, logo + nome à esquerda, botões minimizar/fechar à direita
  - Cores integradas ao `ColorScheme` atual
  - Animações suaves no hover/press dos botões
- [x] Criar `lib/ui/core/widgets/desktop_shell.dart`
  - Wrapper que adiciona `AppTitleBar` apenas em desktop (via `defaultTargetPlatform` para testabilidade)
- [x] Atualizar `main.dart` para chamar `initDesktopWindow()` em desktop e envolver com `DesktopShell` (via `MaterialApp.builder`)

### Específico do Windows

- [x] Validar build `flutter build windows --release` — sucesso (`decima.exe` gerado em ~68s no host)
- [x] Conferir ícone do app integrado ao `.exe` — confirmado visualmente no Windows
- [x] Ajustar `windows/runner/Runner.rc` (ProductName/FileDescription "Decima", CompanyName "Wevasoft") e `main.cpp` (janela inicial 360×720, título "Decima")

### Testes

- [x] Criar `test/widget/core/widgets/app_title_bar_test.dart`
  - Cenários: renderiza logo, nome e botões; altura configurada; drag area; callbacks de fechar/minimizar; hover anima (close e minimize); hover out volta ao idle
- [x] Criar `test/widget/core/widgets/desktop_shell_test.dart`
  - Cenários: `isDesktop` por plataforma; em desktop (Windows/Linux/macOS) envolve com title bar; em mobile (Android/iOS) não adiciona title bar (`debugDefaultTargetPlatformOverride`)
- [x] Verificação manual: app abre em janela fixa 360×720, sem barra do sistema, draggable pela title bar, minimizar/fechar funcionais — **validado pelo usuário**, incluindo teclado físico e colar (`plano/fixtures-colar.md`). Primeira tentativa revelou tela branca e dígitos desalinhados → corrigidos, ver `[Fix] Etapa 14` no changelog

### Validação

- [x] `flutter test` — 100% verde (636 testes)
- [x] `flutter analyze` — zero warnings
- [x] `flutter build windows` — sucesso (release, via Flutter do host Windows)

---

## Etapa 14.1 — Instalador Windows (.exe) ✅

### Script do instalador

- [x] Criar `tool/installer/decima.iss` (Inno Setup 6.3+)
  - `AppId` GUID fixo, versão injetada via `/DAppVersion`
  - Instalação por usuário (`PrivilegesRequired=lowest`), sem UAC
  - Wizard mínimo (sem Welcome/Ready/Group), pt-BR + inglês
  - Menu Iniciar sempre; atalho de desktop como tarefa opcional
  - `CloseApplications=yes` para upgrade in-place
- [x] Preservar dados do usuário (`%APPDATA%\Wevasoft\Decima`) na desinstalação

### Automação

- [x] Criar `tool/installer/build_installer.sh` — sync → clean → build → runtime C++ → ISCC → `dist/`
- [x] Flags `--no-clean` e `--skip-build`
- [x] Criar `tool/installer/local.env.example` e ignorar `local.env` + `/dist/` no `.gitignore`
- [x] Copiar DLLs do redist MSVC para o bundle (app-local, sem pré-requisito)

### Documentação

- [x] Criar `docs/fundacao/empacotamento-windows.md` (decisões, gotchas, segurança)
- [x] Adicionar seção "Instalação (Windows)" no `README.md` com o aviso de SmartScreen
- [x] Registrar no índice `docs/README.md`

### Validação

- [x] `dist/decima-<versão>-windows-x64-setup.exe` gerado — `decima-0.5.0-windows-x64-setup.exe`, 12 MB, compilado em 2,6 s, `.sha256` ao lado
- [x] Smoke test automatizado: instalação silenciosa (`/VERYSILENT`) → bundle em `%LOCALAPPDATA%\Programs\Decima` + atalho no Menu Iniciar → `decima.exe` abre com janela "Decima" → desinstalação silenciosa remove programa e atalho e **preserva** `%APPDATA%\Wevasoft\Decima` (a máquina ficou limpa: app desinstalado ao final)
- [x] Verificação manual: instalar → abrir pelo Menu Iniciar → operar → desinstalar
- [x] Verificação manual: reinstalar por cima preserva o histórico

### Ajustes — tempo de compilação do instalador ✅ (causa raiz encontrada)

O diagnóstico anterior ("LZMA single-thread a 52 KB/s") estava **errado**: o processo nunca esteve comprimindo.

**Causa raiz**: o Inno Setup **6.2.2** instalado no host crashava em **toda** compilação — access violation (`0xc0000005`) no **`ISPP.dll`**, sempre no offset `0x244a4` ("Runtime error 216"), antes de ler qualquer arquivo do `[Files]` (I/O do processo: **0 bytes** lidos/escritos, `dist/` nunca criado). O runtime Delphi exibe o erro num **diálogo modal invisível** para quem chama via interop do WSL (`MainWindowTitle: "Error"`, thread em `WaitReason: UserRequest`); preso no pipe do console interop, o mesmo estado degenerava em spin de 100% de CPU — lido nas sessões anteriores como "compressão CPU-bound lenta". Reproduzido até com um `.iss` mínimo usando `Compression=zip` e em console nativo (`Start-Process`), e confirmado pelo log de eventos do Windows (`Application Error`, 3 crashes em `ISPP.dll`).

**Correção**: `winget upgrade JRSoftware.InnoSetup` → **6.7.3**. A mesma compilação passou a levar **2,6 s** (era "infinito").

Do checklist original:

- [x] `LZMANumBlockThreads=4` + `LZMAUseSeparateProcess=yes` no `[Setup]` — mantidos como boa prática (paralelismo real por blocos, compressão fora do processo 32-bit do compilador)
- [x] `/Q` removido do `build_installer.sh` — o `Compressing: <arquivo>` é o que denuncia travamento; sem ele o silêncio pós-banner é indistinguível de compressão longa
- [x] Volume do `[Files]` confirmado: 33 MB / 27 arquivos, apenas o Release
- [x] Baseline da máquina: `xz -6 -T1` no WSL (mesmo CPU) = 33 MB em 13,9 s ≈ **2,4 MB/s** — a máquina nunca foi o gargalo
- [x] ~~`LZMABlockSize`, `LZMAMatchFinder=HC`, `lzma2/fast`~~ — obsoletos com a causa raiz corrigida
- [x] Extra: `ArchitecturesAllowed`/`ArchitecturesInstallIn64BitMode` migrados de `x64` (deprecado no Inno 6.3+) para `x64compatible` — cobre também Windows ARM64 com emulação x64

---

## Etapa 14.2 — Persistência ao fechar e memória da janela

> Origem: uso diário do Decima instalado no Windows. (1) Fechar pelo `X` descarta o cálculo em andamento — só `=` e `C` persistem hoje. (2) A janela sempre reabre centralizada.

### A — Flush da sessão ao fechar (multiplataforma)

#### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenário: `flushSession()` com expressão pendente avaliável (`10 + 5` sem `=`) grava a linha no histórico
  - Cenário: `flushSession()` com parênteses abertos auto-fecha antes de avaliar
  - Cenário: `flushSession()` com número solto sem operador **não** grava nada
  - Cenário: `flushSession()` com sessão vazia é no-op
  - Cenário: `flushSession()` após `=` (nada novo) é no-op — não duplica linha nem cria sessão nova
  - Cenário: `flushSession()` chamado duas vezes seguidas é idempotente
  - Cenário: `flushSession()` aguarda o `add` em voo (`_addInFlight`) — o `Future` só completa depois da escrita
  - Cenário: `flushSession()` em modo de edição (`_editText`) usa o mesmo caminho do `equals()`
- [x] Criar `test/widget/core/desktop/window_close_handler_test.dart`
  - Cenário: pedido de fechamento chama `flushSession()` **antes** de destruir a janela
  - Cenário: flush que lança exceção ainda destrói a janela (app nunca fica impossível de fechar)
  - Cenário: timeout no flush não bloqueia o fechamento
  - Cenário: em mobile o handler não registra `WindowListener`

#### Implementação (TDD Green)

- [x] Extrair de `equals()` um helper compartilhado que avalia + formata + adiciona a linha à sessão
- [x] Tornar `_saveOrUpdateSession()` `Future<void>` e aguardar o `add` em voo (resolve a corrida do `_addInFlight`)
- [x] Implementar `Future<void> flushSession()` no `CalculatorViewModel`
  - Avalia a expressão pendente quando há ao menos um operador; auto-fecha parênteses
  - Número digitado sem operador não vira entrada (regra documentada)
  - Aguarda a escrita concluir; idempotente
- [x] Criar `lib/ui/core/desktop/window_close_handler.dart`
  - `windowManager.setPreventClose(true)` + `WindowListener.onWindowClose` → `flushSession()` → `windowManager.destroy()`
  - `destroy()` em `finally` + timeout no flush — garantia de que a janela sempre fecha
  - Registrar/desregistrar o listener no ciclo de vida do widget
- [x] Integrar o handler ao `_DecimaAppState` (`MaterialApp.builder`, acima do `DesktopShell`), ativo apenas quando `DesktopShell.isDesktop`
- [x] Adicionar `AppLifecycleListener` no `_DecimaAppState` para mobile
  - Flush em `onHide`/`onPause` (o Android encerra o processo sem garantir `detached`) e em `onExitRequested`
- [x] Verificar que o flush cobre `X` da `AppTitleBar`, `Alt+F4` e "Fechar janela" pela barra de tarefas — os três chegam como `onWindowClose` com `setPreventClose(true)`; validação manual pendente no Windows

### B — Memória da posição da janela (desktop)

#### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/data/repositories/settings_repository_test.dart`
  - Cenários: salvar e ler a posição, ausência devolve `null`, valor parcial (só `x`) devolve `null`
- [x] Criar `test/unit/ui/core/desktop/window_position_test.dart`
  - Cenários: posição dentro de um display, fora de todos, parcialmente visível (title bar alcançável ou não), lista de displays vazia
- [x] Extra: cenários novos em `window_close_handler_test.dart` (posição gravada antes do `destroy`, erro em cada gravação, ausência de callback)

#### Implementação (TDD Green)

- [x] Adicionar `getWindowPosition()` / `setWindowPosition(double x, double y)` à interface `SettingsRepository`
- [x] Implementar em `SettingsRepositoryImpl` com chaves `window_x` / `window_y` — trafegar `double`, **sem** `Offset` (repositórios não importam Flutter) — via entidade `WindowPosition`
- [x] Criar `lib/ui/core/desktop/window_position.dart` com a função pura de validação da posição contra a lista de displays
  - Critério: área da title bar visível somada entre os displays ≥ `minGrabWidth × titleBarHeight` (80 × 40 px)
- [x] Ajustar `initDesktopWindow()`
  - Ler a posição salva; `center: true` apenas quando não houver posição válida
  - `setPosition` **antes** do `show()` — sem piscar no centro
  - Descartar posição inválida (monitor desconectado, mudança de resolução/DPI) → centro
  - `setupDependencies()` subiu no `main()`: o `SettingsRepository` é injetado por parâmetro
- [x] Consultar os displays via `screen_retriever` (declarar em `dependencies` se importado direto — hoje é transitivo do `window_manager`)
- [x] Gravar a posição no fechamento, junto do flush da sessão (`getPosition()` antes do `destroy()`)
  - As duas gravações em `Future.wait` sem `eagerError`, sob o mesmo `flushTimeout`
- [x] Documentar `onWindowMoved` com debounce como alternativa (cobre encerramento anormal) — sem implementar

### Documentação

- [x] Documentar a persistência ao fechar em `docs/features/calculadora.md` (incluindo a regra do número solto)
- [x] Documentar o close handler em `docs/fundacao/arquitetura.md` (nova seção "Infra de Desktop")
- [x] Documentar a memória de posição em `docs/fundacao/arquitetura.md` (infra de desktop)
  - Extra: `arquitetura.md` ganhou as seções `## Segurança e Cibersegurança` e `## Desenvolvimento & Gotchas` que faltavam
- [x] Atualizar `plano/changelog.md` — partes A e B registradas

### Validação

- [x] `flutter test` — 100% verde (683 testes, após a parte B)
- [x] `flutter analyze` — zero warnings
- [x] Regressão: testes das Etapas 13 e 14 continuam verdes
- [x] `flutter build windows --release` — sucesso (cópia de build do host, 49,8 s)
- [x] Teste manual: digitar `10 + 5` sem `=` → fechar pelo `X` → reabrir → cálculo no histórico
  - Dirigido por script via interop (`SendKeys` + `WM_CLOSE`); linha `0.10 + 0.05 = 0.15` gravada no `decima.db`
- [x] Teste manual: `=` e fechar imediatamente → a última linha está gravada
- [x] Teste manual: mover a janela → fechar → reabrir na mesma posição
  - Movida para `200,150` → `window_x`/`window_y` gravados → reabriu em `200,150`
- [x] Teste manual: fechar em um monitor secundário → desconectá-lo → reabrir volta ao centro
  - Sem monitor extra disponível: simulado adulterando as chaves para `9999,9999` (fora de qualquer display) → abriu no centro e regravou a posição válida
- [x] Teste manual (Android): sair do app pelo gesto/botão → reabrir → cálculo preservado

---

## Etapa 14.3 — CI/CD, fluxo de branches e distribuição

### Fluxo de branches e governança

- [x] Criar branch `dev` (contendo os commits ainda não pushados da `main`) e torná-la a branch padrão
- [x] Ruleset `main-protegida`: PR obrigatório + checks `commitlint`/`analyze`/`test`/`build-android`/`build-windows`, sem force-push/deleção, bypass para deploy keys
- [x] Ruleset `dev-integracao`: sem force-push/deleção (commits diretos permitidos)
- [x] Resetar a `main` local para `origin/main` (os 3 commits não pushados entram via PR)

### Tooling no repositório

- [x] `.fvmrc` pinando Flutter `3.44.2` (fonte da versão do SDK no CI)
- [x] Remover `/.github/` do `.gitignore` (bloqueava o versionamento dos workflows)
- [x] `commitlint.yaml` + `commitlint_cli ^0.8.1` em dev_dependencies (padrão runway/verbum/dosia)
- [x] Copiar `tool/bump_version.dart` (motor D5/D6 do runway) + `test/tool/bump_version_test.dart` — 7 testes verdes
- [x] `dart format` aplicado ao repo inteiro (gate de formatação no CI)
- [x] `signingConfigs.release` no `build.gradle.kts` lendo `android/key.properties` (fallback: debug)
- [x] Keystore de upload gerado em `~/.keystores/decima/decima-release.jks` + `key.properties` local

### Workflows

- [x] `.github/actions/setup-flutter/action.yml` — ação composta (Flutter do `.fvmrc` + cache + pub get)
- [x] `.github/workflows/ci.yml` — commitlint, format+analyze, test+coverage (gate 85%), build-android (+ Firebase grupo `dev` em push), build-windows (zip com runtime MSVC)
- [x] `.github/workflows/release.yml` — bump SemVer + `CHANGELOG.md` + tag via deploy key, APK assinado → Firebase grupo `stable`, instalador Inno Setup + `.sha256`, GitHub Release

### Firebase e secrets

- [x] Grupos de testers `dev` e `stable` criados no projeto `decima-wevasoft` (tester inicial adicionado)
- [x] Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`; variável `FIREBASE_ANDROID_APP_ID`
- [x] Secret `FIREBASE_SERVICE_ACCOUNT` (chave de service account gerada no console — ação manual)
- [x] Deploy key de escrita `release-bot` + secret `RELEASE_DEPLOY_KEY` (ação manual — bloqueada no ambiente da IA)

### Documentação

- [x] Criar `docs/fundacao/ci-cd.md` (fluxo, jobs, secrets, segurança, gotchas)
- [x] Atualizar `docs/README.md` (índice) e `README.md` (badges + seção "Contribuição e Release")
- [x] Registrar a etapa em `plano/plano.md`, `plano/tarefas.md` e `plano/changelog.md`

### Validação

- [x] `flutter test` — 100% verde (690 testes, incluindo os 7 do motor)
- [x] `flutter analyze` — zero warnings
- [x] `dart run commitlint_cli --from=origin/main --to=HEAD` — todos os commits válidos
- [x] Primeiro PR `dev` → `main` com pipeline 100% verde (PR #1 — 5 checks, merge limpo)
- [x] Primeiro release automático publicado — v0.6.0 (tag, CHANGELOG, APK no Firebase `stable`, instalador + `.sha256` no GitHub Release); run anti-loop confirmado em NOOP

---

## Etapa 15 — Suporte a Linux ✅

### Habilitação da plataforma

- [x] Rodar `flutter create --platforms=linux .` — runner GTK já existia e não mudou; reverter o efeito colateral em `.metadata` (derrubava as outras plataformas) e `pubspec.lock`
- [x] Conferir compatibilidade do `window_manager` no compositor alvo (X11/Wayland)

### Runner GTK (`linux/runner/my_application.cc`)

- [x] Remover o `GtkHeaderBar` — mantinha decoração do lado do cliente e desalinhava `getPosition`/`setPosition`
- [x] Tamanho inicial `360x720` (era `1280x720`) — `setResizable(false)` sobrescrevia o `setSize` das `WindowOptions` com o default do runner
- [x] Título `Decima` (era `decima`) + remoção do `#include <gdk/gdkx.h>` órfão
- [x] `set_application_icon()` — o template não define ícone; sem `_NET_WM_ICON` a janela ficava com o ícone genérico. Tema primeiro, fallback no `logo.png` do bundle

### Ajustes específicos (TDD Red → Green)

- [x] Teste: `PlatformInfo.isLinux` (novo `test/unit/utils/platform_info_test.dart`, cobre também `isDesktop`)
- [x] Implementar `PlatformInfo.isLinux`
- [x] Teste: `isWindowPositionStorable` — origem rejeitada só em Linux, `NaN`/infinito rejeitados sempre
- [x] Implementar `isWindowPositionStorable` e ligá-la ao `_saveWindowPosition` do `main.dart`
- [x] Pular `setMaximizable(false)` no Linux — vira `GDK_WINDOW_TYPE_HINT_DIALOG` (sem barra de tarefas, alt-tab nem minimizar)
- [x] Validar `TitleBarStyle.hidden` no GTK (X11 **e** Wayland) — `_MOTIF_WM_HINTS` com decoração zerada
- [x] Conferir cursor de drag e botões da title bar customizada

### Integração com o desktop (`linux/packaging/`)

- [x] `com.wevasoft.decima.desktop` — `Icon`, `Categories`, `StartupWMClass` casando o `WM_CLASS` da janela
- [x] Ícones do tema `hicolor` (16/24/32/48/64/128/256/512) derivados do master no `tool/icon/render.mjs`
- [x] Remover a chave `linux:` do `flutter_launcher_icons.yaml` — sem suporte no pacote, era ignorada em silêncio
- [x] `install-desktop-entry.sh` — publica/remove no menu do usuário sem `sudo`
- [x] Documentar opções de empacotamento (AppImage/Flatpak/Snap/`.deb`) — sem implementar

### Documentação

- [x] Criar `docs/fundacao/empacotamento-linux.md` (runner, ajustes de janela, `.desktop`, empacotamento, segurança, gotchas)
- [x] Atualizar `docs/fundacao/arquitetura.md` (infra de desktop, regra de gravação da posição, gotchas)
- [x] Atualizar `docs/README.md` (índice) e `README.md` (seção "Instalação (Linux)")
- [x] Registrar a etapa em `plano/plano.md`, `plano/tarefas.md` e `plano/changelog.md`

### Validação

- [x] `flutter build linux --release` — sucesso
- [x] `flutter test` — 100% verde (700 testes, 10 novos)
- [x] `flutter analyze` — zero warnings
- [x] `dart format --set-exit-if-changed .` — sem alterações
- [x] Verificação manual (X11 e Wayland): janela fixa 360×720, title bar customizada, drag, minimizar, fechar
- [x] Verificação manual: fechar pelo `X` grava a sessão (`decima.db`) e a posição (`shared_preferences.json`)
- [x] Verificação manual: ícone resolvido pelo tema e entrada `.desktop` encontrada pelo GIO
- [x] Verificação manual: `_NET_WM_ICON` publicado em X11, pelos dois caminhos (tema instalado e fallback do bundle com o tema removido)

---

## Etapa 15.1 — Pacote `.deb` e distribuição Linux no CD

### Empacotamento

- [x] Criar `tool/deb/build_deb.sh` — build (opcional) → staging FHS → `DEBIAN/control` → `dpkg-deb --root-owner-group` → `dist/` + `.sha256`
  - Layout: bundle em `/usr/lib/decima/`, symlink `/usr/bin/decima`, `.desktop` + ícones de `linux/packaging/`, metainfo AppStream
  - Flags: `--skip-build` (reusa o bundle existente) e `--version X.Y.Z[~sufixo]`
  - `Depends` mínimo (GTK3 + base; sem SQLite — embutido no bundle via native assets)
  - Sem scripts de mantenedor (dpkg triggers cuidam dos caches)
  - Extra: remoção do `kernel_blob.bin` deixado no staging compartilhado por builds debug (ver changelog)
- [x] Criar `linux/packaging/com.wevasoft.decima.metainfo.xml` (AppStream, `@VERSION@`/`@DATE@` substituídos no empacotamento) — `appstreamcli validate` ✔

### CI/CD

- [x] `ci.yml`: job `build-linux` (needs `analyze`+`test`; push na `dev` e PR para `main`; `.deb` `~dev.N`/`~pr.N` como artefato de 14 dias)
- [x] `release.yml`: job `release-linux` + artefato incluído no `publish`
- [x] Ruleset `main-protegida`: adicionar `build-linux` como 6º check obrigatório (via `gh api`, aprovado pelo usuário)

### Documentação

- [x] `docs/fundacao/empacotamento-linux.md` — seção do `.deb` (layout, control, gotchas), tabela de opções atualizada
- [x] `docs/fundacao/ci-cd.md` — novos jobs, 6 checks no ruleset
- [x] `README.md` — Instalação (Linux) com o `.deb` do GitHub Release
- [x] Registrar a etapa em `plano/plano.md`, `plano/tarefas.md` e `plano/changelog.md`

### Validação

- [x] `tool/deb/build_deb.sh` gera `dist/decima-<versão>-linux-amd64.deb` + `.sha256` — 8,3 MB (27 MB instalado)
- [x] `dpkg-deb --info`/`--contents` — control, layout, permissões e symlink corretos
- [x] Smoke test sem root: `dpkg-deb -x` + execução via symlink `usr/bin/decima` sob WSLg — janela abre, libs e assets resolvidos
- [x] Instalação local: `dpkg -i` → app instalado, aberto e operando (**validado pelo usuário**, lado a lado com o build Windows)
  - dpkg trigger regenerou o `icon-theme.cache` na instalação; `_NET_WM_ICON` publicado sob X11 (`xprop`) e `WM_CLASS` correto
  - Tux na barra de tarefas e janela menor que o build Windows = quirks documentados do WSLg (sem lookup `app_id`→`.desktop` no Wayland; DPI a 100%) — não ocorrem em desktop Linux real
  - Achado: `hicolor-icon-theme` adicionado ao `Depends` (fornece o `index.theme` que o lookup de ícones exige)
  - `dpkg -r` preservando `~/.local/share/com.wevasoft.decima` — não exercitado (app mantido instalado)
- [x] `flutter test` / `flutter analyze` / `dart format` — regressão intacta (sem código Dart novo)
- [x] CI `build-linux` verde no push da `dev` e no PR #3 (~1m20s cada)
- [x] Primeiro release com o `.deb` publicado — v0.8.0 (`decima-0.8.0-linux-amd64.deb` + `.sha256` no GitHub Release)

---

## Etapa 16 — Suporte a macOS

### Habilitação da plataforma

- [x] Rodar `flutter create --platforms=macos .` — o runner já existia desde a fundação; o primeiro build integrou os plugins via Swift Package Manager (CocoaPods deintegrado — ver changelog)
- [x] Conferir entitlements em `macos/Runner/*.entitlements` — Release só com `app-sandbox`; `allow-jit`/`network.server` restritos ao DebugProfile. Nada a adicionar

### Ajustes específicos

- [x] Esconder o botão verde de maximizar — `setResizable(false)` (já chamado) o deixa cinza (sem `.resizable` no `styleMask`); `setMaximizable(false)` no macOS só veta o zoom no delegate, não muda o visual
- [x] Decisão UX: semáforo nativo mantido; `AppTitleBar` em macOS exibe apenas logo + nome, centralizados (convenção de título da plataforma, longe do semáforo)
- [x] Adicionar branch `PlatformInfo.isMacOS` em `AppTitleBar` ocultando os botões customizados
- [x] Conferir ícone `.icns` — `AppIcon.icns` no bundle, compilado do appiconset regenerado na Etapa 12
- [x] Documentar assinatura/notarização — `docs/fundacao/empacotamento-macos.md` (referência, sem implementar)
- [x] Extra: `hiddenWindowAtLaunch()` no `MainFlutterWindow.swift` — setup do `window_manager` que evita a janela piscar no tamanho do template antes do `waitUntilReadyToShow`
- [x] Extra (pós-validação): ícone do Dock arredondado — `decima_icon_macos.png` (master squircle 824 px em canvas 1024) no `render.mjs` + `macos.image_path`; o full-bleed saía quadrado (macOS não aplica máscara)
- [x] Extra (pós-validação): `PRODUCT_NAME = Decima` (bundle/launcher com nome capitalizado) e instalação local em `/Applications` via `ditto` + `lsregister`

### Testes

- [x] Atualizar `app_title_bar_test.dart` com cenário macOS (botões ocultos, logo+nome centralizados, drag area e altura preservadas)
- [x] Extra: grupo `PlatformInfo.isMacOS` em `platform_info_test.dart`

### Validação

- [x] `fvm flutter build macos --release` — sucesso (`decima.app` 49,1 MB, universal x86_64+arm64, assinatura ad-hoc)
- [x] `flutter test` — 100% verde (709 testes)
- [x] `flutter analyze` — zero warnings
- [x] Verificação manual: janela fixa com semáforo nativo, botão verde inativo — **validada pelo usuário**

---

## Etapa 16.1 — Distribuição macOS no CD e enxugamento do canal dev

### Empacotamento

- [x] Criar `tool/macos/build_zip.sh` — guard de `Darwin` → build (opcional) → `codesign --verify --strict` → `ditto -c -k --keepParent` → `dist/` + `.sha256`
  - Nome do bundle lido de `PRODUCT_NAME` no `AppInfo.xcconfig` (sem constante duplicada)
  - Flags: `--skip-build` (reusa o bundle existente) e `--version X.Y.Z[-sufixo]`
  - `zip` comum está proibido: perde symlinks/permissões e invalida a assinatura ad-hoc

### CI/CD

- [x] `ci.yml`: job `build-macos` em `macos-latest` (needs `analyze`+`test`; push na `dev` e PR para `main`; zip `-dev.N`/`-pr.N` como artefato de 14 dias)
- [x] `ci.yml`: remover a distribuição Firebase do grupo `dev` (steps + env `HAS_FIREBASE`) — o CI deixa de distribuir qualquer coisa
- [x] `release.yml`: job `release-macos` + artefato incluído no `publish`
- [ ] Ruleset `main-protegida`: adicionar `build-macos` como 7º check obrigatório (via `gh api`, aprovado pelo usuário)

### Documentação

- [x] `docs/fundacao/empacotamento-macos.md` — script de empacotamento, seção CI/CD, gotchas do `ditto`/`upload-artifact`
- [x] `docs/fundacao/ci-cd.md` — novos jobs, 7 checks, Firebase restrito ao `release.yml`, grupo `dev` aposentado
- [x] `README.md` — Instalação (macOS) a partir do GitHub Release
- [x] Registrar a etapa em `plano/plano.md`, `plano/tarefas.md` e `plano/changelog.md`

### Validação

- [ ] CI `build-macos` verde no push da `dev` e no PR para `main`
- [ ] Primeiro release com o zip publicado (`decima-<semver>-macos.zip` + `.sha256`)
- [ ] Extrair o zip do release em outro Mac, liberar no Gatekeeper e abrir o app
- [x] `flutter test` / `flutter analyze` / `dart format` — regressão intacta (sem código Dart novo)

---

## Etapa 17 — Suporte a iOS *(removida do escopo)*

Sem Apple Developer Program pago não há caminho de distribuição para iOS. Etapa cancelada — justificativa completa em `plano.md`.

- [x] Remover `ios/` do repositório
- [x] Desabilitar iOS em `flutter_launcher_icons.yaml` e `flutter_native_splash.yaml`
- [x] Manter os `case TargetPlatform.iOS:` do `PlatformInfo` e seus testes (enum do Flutter, `switch` exaustivo)

---

## Etapa 18 — Polimento, Integração e Revisão Final

### Animações e Transições

- [ ] Revisar animações de todos os botões (curvas, durações)
- [ ] Implementar transição de página animada (Calculator ↔ History ↔ Settings)
- [ ] Animação de troca de tema global suave (AnimatedTheme ou wrap)
- [ ] Verificar AnimatedSwitcher no display da timeline
- [ ] Refinar animação de abertura/fechamento do menu de contexto (Etapa 10)
- [ ] Refinar animação de slide horizontal e blink do cursor editável (Etapa 11)
- [ ] Refinar hover/press dos botões da `AppTitleBar` em desktop (Etapas 14–16)

### Fluxos de Integração

- [ ] Testar fluxo: calculadora → = → resultado aparece na timeline
- [ ] Testar fluxo: calculadora → ⏱ → histórico → tocar item → timeline carregada
- [ ] Testar fluxo: calculadora → ⚙ → mudar tema → reflexo imediato
- [ ] Testar fluxo: calculadora → ⚙ → mudar separador → reflexo no display
- [ ] Testar fluxo: fechar app → reabrir → preferências mantidas
- [ ] Testar fluxo: sessão longa → load more na timeline carrega anteriores
- [ ] Testar fluxo: histórico → load more → favoritar → filtrar → renomear
- [ ] Testar fluxo: copiar cálculo/resultado/histórico → colar em outro app e de volta na calculadora
- [ ] Testar fluxo: colar valor inválido → snackbar de erro com texto via `context.l10n.*`
- [ ] Testar fluxo: navegar com cursor editável → inserir/apagar no meio da expressão → confirmar com `=`
- [ ] Verificar interação entre cursor editável, parênteses inteligentes e porcentagem literal
- [ ] Testar fluxo: operação completa via teclado físico em desktop e mobile com teclado externo
- [ ] Verificar que o logo e o splash aparecem corretamente em todas as plataformas
- [ ] Verificar paridade visual entre Android, Windows, Linux e macOS

### Qualidade

- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — 100% verde
- [ ] Verificar: nenhuma string hardcoded na UI
- [ ] Verificar: nenhum valor de layout hardcoded
- [ ] Verificar: nenhum `print()` no código
- [ ] Verificar: ViewModels não importam Flutter (exceto `foundation.dart`)
- [ ] Revisar cobertura de testes (incluindo `ClipboardService`, cursor, teclado físico, title bar)
- [ ] Builds de release passam em todas as plataformas suportadas

### Documentação

- [ ] Atualizar docs se houve desvios da arquitetura
- [ ] Documentar comportamento de copiar/colar e cursor editável em `docs/features/calculadora.md`
- [ ] Documentar atalhos de teclado em `docs/features/calculadora.md`
- [ ] Documentar infra de desktop (`AppTitleBar`, `DesktopShell`, `DesktopWindowConfig`) em `docs/fundacao/arquitetura.md`
- [ ] Atualizar changelog
