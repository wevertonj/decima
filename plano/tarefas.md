# Tarefas — WevaCalc

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

- [x] Validar build `flutter build windows --release` — sucesso (`wevacalc.exe` gerado em ~68s no host)
- [x] Conferir ícone do app integrado ao `.exe` — confirmado visualmente no Windows
- [x] Ajustar `windows/runner/Runner.rc` (ProductName/FileDescription "WevaCalc", CompanyName "Wevasoft") e `main.cpp` (janela inicial 360×720, título "WevaCalc")

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

## Etapa 15 — Suporte a Linux

### Habilitação da plataforma

- [ ] Rodar `flutter create --platforms=linux .`
- [ ] Conferir compatibilidade do `window_manager` no compositor alvo (X11/Wayland)

### Ajustes específicos

- [ ] Validar `TitleBarStyle.hidden` no GTK (X11 e, se possível, Wayland)
- [ ] Conferir cursor de drag e botões da title bar customizada
- [ ] Configurar `.desktop` em `linux/` (nome, ícone, categoria) se necessário
- [ ] Documentar opções de empacotamento (AppImage/Flatpak/Snap) — sem implementar

### Validação

- [ ] `flutter build linux` — sucesso
- [ ] `flutter test` — 100% verde (regressão)
- [ ] `flutter analyze` — zero warnings
- [ ] Verificação manual: janela fixa, title bar customizada, drag/minimizar/fechar funcionais

---

## Etapa 16 — Suporte a macOS

### Habilitação da plataforma

- [ ] Rodar `flutter create --platforms=macos .`
- [ ] Conferir entitlements em `macos/Runner/*.entitlements`

### Ajustes específicos

- [ ] Esconder o botão verde de maximizar (`windowManager.setMaximizable(false)` ou `setWindowButtonVisibility`)
- [ ] Decisão UX: manter semáforo nativo (recomendado); `AppTitleBar` em macOS exibe apenas logo + nome
- [ ] Adicionar branch `Platform.isMacOS` em `AppTitleBar` para ocultar botões customizados de minimizar/fechar
- [ ] Conferir ícone `.icns` (gerado na Etapa 12) integrado ao bundle
- [ ] Documentar processo básico de assinatura/notarização — sem implementar

### Testes

- [ ] Atualizar `app_title_bar_test.dart` com cenário macOS (botões customizados ocultos)

### Validação

- [ ] `flutter build macos` — sucesso
- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings
- [ ] Verificação manual: janela fixa com semáforo nativo, sem botão verde de maximizar

---

## Etapa 17 — Suporte a iOS

### Habilitação da plataforma

- [ ] Rodar `flutter create --platforms=ios .`
- [ ] Configurar `ios/Runner/Info.plist` (nome, orientações apenas portrait, status bar style)

### Identidade visual

- [ ] Conferir que ícones e splash da Etapa 12 cobrem iOS
- [ ] Validar `LaunchScreen.storyboard` integrado ao splash gerado

### Ajustes específicos

- [ ] Confirmar funcionamento de `sqflite` e `shared_preferences` no iOS
- [ ] Validar teclado físico (Etapa 13) em iPad com Magic/Smart Keyboard
- [ ] Conferir safe area (notch / Dynamic Island)

### Validação

- [ ] `flutter build ios --no-codesign` — sucesso
- [ ] `flutter test` — 100% verde (regressão)
- [ ] `flutter analyze` — zero warnings
- [ ] Verificação manual: app roda no simulador iOS com paridade visual ao Android

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
- [ ] Verificar paridade visual entre Android, iOS, Windows, Linux e macOS

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
