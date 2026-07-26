# Changelog — WevaCalc

Registro de todas as alterações realizadas no projeto, organizado por etapa.

---

## [Concluída] Etapa 1 — Fundação e Infraestrutura

### Dependências

- Atualizado `pubspec.yaml` com: `get_it`, `sqflite`, `path`, `shared_preferences`, `flutter_localizations`, `intl`
- Adicionadas dev_dependencies: `mocktail`, `sqflite_common_ffi`
- Removido `cupertino_icons` (não utilizado)

### Estrutura de Pastas

- Criados todos os diretórios: `config/`, `data/`, `domain/`, `ui/`, `utils/` com sub-pastas

### Tema e Layout

- `AppLayout` — constantes de spacing (`xs`→`xl`), padding (`xs`→`xl`), radius (`small`→`circular`)
- `AppColors` — 9 seed colors (Amber padrão, Blue, Green, Red, Purple, Orange, Cyan, Pink, Blue Grey)
- `AppTheme` — ThemeData claro e escuro via `ColorScheme.fromSeed()` com Material 3

### Configuração

- `dependencies.dart` — GetIt setup inicial (vazio, pronto para Etapa 2+)
- `routes.dart` — rotas nomeadas (`/`, `/history`, `/settings`) com placeholders

### Internacionalização

- `l10n.yaml` configurado com output em `lib/utils/l10n/`
- ARBs criados: `app_en.arb`, `app_pt_BR.arb`, `app_es.arb`
- Extension `context.l10n` em `lib/utils/extensions/l10n_extension.dart`
- Strings iniciais: `appTitle`, `calculator`, `history`, `settings`

### App Shell

- `main.dart` reescrito com `WevaCalcApp`: tema dark padrão, l10n, rotas, GetIt

### Testes

- `app_layout_test.dart` — 14 testes (spacing, padding, radius)
- `app_colors_test.dart` — 4 testes (seed colors, default)
- `app_theme_test.dart` — 9 testes (light/dark, brightness, Material 3, seed variation)
- **Total: 27 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 2 — Domínio e Camada de Dados (base)

### Entities

- `Calculation` — expression, result, timestamp com value equality
- `HistoryEntry` — id (nullable), expression, result, createdAt com value equality e copyWith

### Enums

- `OperationType` — add (+), subtract (−), multiply (×), divide (÷) com propriedade `symbol`
- `ThemeModeOption` — light, dark, system
- `DecimalSeparator` — dot (.), comma (,) com propriedade `character`

### Models

- `HistoryModel` — toMap, fromMap, toEntity, fromEntity (converte entre Map/Entity)
  - toMap omite `id` quando null (para INSERT sem id)

### Database

- `AppDatabase` — SQLite helper com migrations versionadas
  - Aceita `DatabaseFactory` injetável (para testes com FFI)
  - `initialize(inMemory: true)` para testes
  - Schema v1: tabela `history` (id, expression, result, created_at)

### Repository

- `HistoryRepository` (interface) — getAll, add, delete, clear
- `HistoryRepositoryImpl` — implementação com SQLite
  - `getAll()` retorna ordenado por created_at DESC
  - `add()` retorna entry com id atribuído

### Injeção de Dependência

- `AppDatabase` registrado como lazy singleton no GetIt
- `HistoryRepository` registrado como lazy singleton no GetIt

### Fixtures e Mocks

- `test/fixtures/history_fixtures.dart` — dados de teste reutilizáveis
- `test/mocks/mock_history_repository.dart` — mock com mocktail

### Testes

- `calculation_test.dart` — 6 testes (criação, equality, hashCode)
- `history_entry_test.dart` — 7 testes (criação, nullable id, equality, copyWith)
- `operation_type_test.dart` — 6 testes (valores, symbols)
- `theme_mode_option_test.dart` — 2 testes (valores)
- `decimal_separator_test.dart` — 4 testes (valores, characters)
- `history_model_test.dart` — 7 testes (toMap, fromMap, toEntity, fromEntity)
- `history_repository_test.dart` — 7 testes (add, getAll, delete, clear com SQLite em memória)
- **Total novos: 39 testes — Total geral: 66 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação)

### HistoryEntry

- Adicionado campo `name` (String?, opcional, default null)
- Adicionado campo `isFavorite` (bool, default false)
- Atualizado `copyWith` com suporte aos novos campos
- Atualizado `==` e `hashCode` incluindo `name` e `isFavorite`

### HistoryModel

- Adicionado campo `name` (String?, opcional)
- Adicionado campo `isFavorite` (bool, default false)
- `toMap()` serializa `name` e `is_favorite` (int 0/1)
- `fromMap()` deserializa `name` e `is_favorite`
- `toEntity()` e `fromEntity()` mapeiam os novos campos

### Schema SQLite

- Adicionada coluna `name TEXT` na tabela `history`
- Adicionada coluna `is_favorite INTEGER NOT NULL DEFAULT 0` na tabela `history`

### HistoryRepository (interface)

- Novo método `getById(id)` — buscar entrada individual
- Novo método `getPaginated(limit, offset)` — paginação com LIMIT/OFFSET
- Novo método `getFavorites(limit, offset)` — apenas favoritos, paginado
- Novo método `updateName(id, name)` — renomear entrada
- Novo método `toggleFavorite(id)` — alternar favorito

### HistoryRepositoryImpl

- Implementação de `getById` — query por id, retorna null se não existe
- Implementação de `getPaginated` — query com LIMIT/OFFSET ordenada por created_at DESC
- Implementação de `getFavorites` — filtra is_favorite = 1, paginado
- Implementação de `updateName` — UPDATE do campo name
- Implementação de `toggleFavorite` — toggle via CASE WHEN no SQL

### Fixtures e Mocks

- Adicionadas fixtures: `entryWithName`, `entryFavorite`, `entryWithNameAndFavorite`
- Adicionados models: `modelWithName`, `modelFavorite`
- Adicionados maps: `mapWithName`, `mapFavorite`
- Maps existentes (`map1`, `mapWithoutId`) atualizados com campos `name` e `is_favorite`

### Testes

- `history_entry_test.dart` — 15 testes (criação com novos campos, equality, copyWith com name/isFavorite)
- `history_model_test.dart` — 14 testes (toMap/fromMap/toEntity/fromEntity com novos campos)
- `history_repository_test.dart` — 17 testes (add com novos campos, getById, getPaginated, getFavorites, updateName, toggleFavorite)
- **Total novos: 32 testes — Total geral: 98 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 3 — Motor da Calculadora

### Add2Engine (`lib/domain/add2_engine.dart`)

- Entrada numérica com 2 casas decimais automáticas (conceito Add2)
- `inputDigit` — insere dígito com validação (apenas 0-9)
- `inputDoubleZero` / `inputTripleZero` — atalhos para `00` e `000`
- `deleteLastDigit` — backspace com reajuste automático
- `formattedValue` — valor formatado com separador decimal (ex: `12.50`)
- `doubleValue` / `intValue` — acesso ao valor numérico
- `setValue` — define valor a partir de centavos inteiros
- `reset` — limpa estado

### ExpressionEvaluator (`lib/domain/expression_evaluator.dart`)

- Avalia expressões com +, −, ×, ÷ respeitando precedência matemática
- Suporte a porcentagem (%) com comportamento contextual:
  - `+` e `−`: porcentagem sobre o valor base (100 + 10% = 110)
  - `×` e `÷`: conversão direta para fração (200 × 10% = 20)
- Tratamento de erros: divisão por zero, expressão vazia/inválida, operador trailing
- Resultado sempre formatado com 2 casas decimais

### NumberFormatter (`lib/utils/formatters/number_formatter.dart`)

- `format(cents, separator)` — formata centavos inteiros com separador configurável (ponto/vírgula)
- `formatDouble(value, separator)` — formata double com separador configurável
- Suporte a separador de milhar (ponto para vírgula e vice-versa)
- Suporte a valores negativos

### CalculatorViewModel (`lib/ui/calculator/calculator_view_model.dart`)

- Gerencia entrada Add2 para o número atual
- Monta expressão completa (números + operadores)
- Prévia do resultado em tempo real (`previewResult`)
- Confirma cálculo (`equals`) e adiciona à timeline + persiste no histórico
- Timeline com limite de entradas visíveis e `loadMoreTimelineEntries`
- Carregamento de sessão (`loadSession`) a partir do histórico
- Encadeamento de operações (resultado anterior como próximo operando)
- Substituição de operador sem perder o operando
- Suporte a porcentagem via `applyPercentage`

### Injeção de Dependência

- `CalculatorViewModel` registrado como factory no GetIt

### Testes

- `add2_engine_test.dart` — 39 testes (dígitos, 00, 000, backspace, reset, setValue, doubleValue, isEmpty)
- `expression_evaluator_test.dart` — 26 testes (operações, precedência, %, erros, formatação)
- `number_formatter_test.dart` — 18 testes (ponto, vírgula, milhar, negativos, formatDouble)
- `calculator_view_model_test.dart` — 43 testes (estado inicial, dígitos, operadores, =, C, ⌫, %, timeline, load more, loadSession)
- **Total novos: 126 testes — Total geral: 224 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 4 — Lógica do Histórico e Configurações

### HistoryViewModel (`lib/ui/history/history_view_model.dart`)

- Carregamento paginado de entradas (20 por página)
- `loadEntries()` — carrega primeira página e reseta paginação
- `loadMore()` — carrega próxima página e acrescenta à lista
- `hasMore` — indica se há mais páginas disponíveis
- `isLoading` — estado de carregamento para feedback visual
- `deleteEntry(id)` — deleta entrada individual e remove da lista local
- `clearAll()` — limpa todo o histórico e reseta paginação
- `updateName(id, name)` — renomeia entrada localmente e no banco
- `toggleFavorite(id)` — alterna favorito localmente e no banco
- `setShowFavoritesOnly(bool)` — alterna filtro e recarrega lista
- Proteção contra chamadas concorrentes de loadMore

### SettingsRepository (`lib/data/repositories/settings_repository.dart`)

- Interface com métodos get/set para:
  - `ThemeModeOption` (light, dark, system)
  - `seedColorIndex` (índice 0-8 das seed colors)
  - `DecimalSeparator` (dot, comma)
  - `locale` (String?, nullable)

### SettingsRepositoryImpl (`lib/data/repositories/settings_repository_impl.dart`)

- Implementação com SharedPreferences
- Valores padrão: system, 0, dot, null
- `setLocale(null)` remove a chave do SharedPreferences

### SettingsViewModel (`lib/ui/settings/settings_view_model.dart`)

- Gerencia estado reativo de todas as preferências
- `loadSettings()` — carrega todas as preferências do repository
- `setThemeMode()`, `setSeedColorIndex()`, `setDecimalSeparator()`, `setLocale()` — atualizam estado e persistem
- Notifica listeners em cada alteração

### Injeção de Dependência

- `SettingsRepository` registrado como lazy singleton no GetIt
- `HistoryViewModel` registrado como factory no GetIt
- `SettingsViewModel` registrado como factory no GetIt

### Mocks

- `MockSettingsRepository` criado em `test/mocks/mock_settings_repository.dart`

### Testes

- `history_view_model_test.dart` — 24 testes (estado inicial, loadEntries, loadMore, hasMore, isLoading, delete, clearAll, updateName, toggleFavorite, setShowFavoritesOnly, paginação de favoritos, notificações)
- `settings_repository_test.dart` — 11 testes (get/set ThemeMode, seedColorIndex, decimalSeparator, locale com defaults e persistência)
- `settings_view_model_test.dart` — 18 testes (estado inicial, loadSettings, setThemeMode, setSeedColorIndex, setDecimalSeparator, setLocale, notificações)
- **Total novos: 53 testes — Total geral: 277 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 5 — UI da Calculadora

### Design System — Atualização de Cores

- `AppColors` — Paleta de 9 seed colors atualizada:
  - Blue (#005CEE, padrão), Emerald (#10B981), Orange (#F97316), Cyan (#06B6D4), Pink (#EC4899), Amber (#F59E0B), Rose (#F43F5E), Slate (#94A3B8), Yellow (#F3DE2C)
- `AppColors` — Cores de superfície customizadas:
  - Dark: background (#181818), surface (#212121), surfaceContainer (#2D2D2D)
  - Light: background (#F4F4F5), surface (#FFFFFF), surfaceContainer (#E8E8EA)
- `AppTheme` — ThemeData claro/escuro com cores de superfície customizadas via `ColorScheme.fromSeed`

### CalculatorButton (`lib/ui/calculator/widgets/calculator_button.dart`)

- Botão circular com 4 variantes: `numeric`, `operator`, `action`, `equals`
- Efeito de toque: flash instantâneo na cor de fundo (tap down) com retorno suave (80ms)
- Efeito reactive typing: texto/ícone acende como LED no tap e apaga suavemente (500ms, `Curves.easeOutQuart`)
- Operadores em cor primary, numéricos em onSurface, ações em onSurface com opacidade, equals com fundo primary
- `AnimatedContainer` para feedback de fundo, `AnimationController` para glow do texto

### CalculatorKeypad (`lib/ui/calculator/widgets/calculator_keypad.dart`)

- Grid 5×4 com layout: C, %, ⌫, ÷ | 7, 8, 9, × | 4, 5, 6, − | 1, 2, 3, + | 000, 00, 0, =
- 20 botões `CalculatorButton` com variantes corretas
- Callbacks separados: `onDigit`, `onOperator`, `onEquals`, `onClear`, `onBackspace`, `onPercent`, `onDoubleZero`, `onTripleZero`

### TimelineDisplay (`lib/ui/calculator/widgets/timeline_display.dart`)

- ListView scrollável com auto-scroll para o final ao atualizar
- Entradas passadas em cor sutil (onSurface com baixa opacidade)
- Expressão atual em branco, valor atual em fonte grande (48px, w300)
- Prévia do resultado em cinza (28px, 35% opacidade)
- `AnimatedSwitcher` com `switchInCurve: Curves.easeOutQuart` para transições de valor
- Botão "load more" no topo com fundo surfaceContainerHighest

### CalculatorPage (`lib/ui/calculator/calculator_page.dart`)

- Layout vertical: Timeline (expanded) + barra de ícones + Keypad
- Barra de ícones: history (⏱) e settings (⚙) — navegação placeholder
- Integração com `CalculatorViewModel` via `addListener`/`setState`

### Rotas

- Rota `/` conectada ao `CalculatorPage` com ViewModel do GetIt

### Internacionalização

- Novas strings nos 3 ARBs: `loadMore`, `clear`, `backspace`, `equals`, `percent`

### Infraestrutura de Testes

- `test/helpers/pump_app.dart` — Extension `pumpApp` em `WidgetTester` com tema, l10n e dark mode

### Testes

- `calculator_button_test.dart` — 11 testes (renderização de variantes, ícone, interação, cores)
- `calculator_keypad_test.dart` — 13 testes (todos os botões, callbacks de dígitos/operadores/ações)
- `timeline_display_test.dart` — 9 testes (expressão, valor, preview, entradas passadas, load more)
- `calculator_page_test.dart` — 8 testes (renderização, integração teclado→display, =, C, ⌫)
- **Total novos: 41 testes — Total geral: 318 testes — 100% verde**
- `flutter analyze` — zero issues

### Extras (fora do plano original)

#### AnimatedInputDisplay (`lib/ui/calculator/widgets/animated_input_display.dart`)

Widget customizado que substituiu o `TextField` padrão no display da calculadora. Renderiza cada caractere individualmente com animações:

- **Pop-in**: Novos caracteres surgem com expansão de largura (0 → target), escala (0.5 → 1) e opacidade (0 → 1) em 250ms com `Curves.easeOutBack`
- **Rolling digit**: Caracteres que mudam de valor usam transição vertical — antigo sobe e desaparece, novo sobe por baixo — em 200ms com `Curves.easeOutCubic`
- **Diff algorithm**: `_diffAndBuildSlots()` calcula prefixo/sufixo comum para determinar tipo de animação por caractere (popIn, roll, none)
- **RichText**: Cada caractere usa `RichText` em vez de `Text` para evitar conflito com `find.text()` nos testes de widget
- **Operadores coloridos**: +, −, ×, ÷ renderizados na cor primary; dígitos na cor onSurface

#### Animação de redução de fonte

- `TweenAnimationBuilder<double>` no fontSize (200ms, `Curves.easeOutCubic`) — quando a expressão cresce e a fonte reduz (48 → 36 → 28), a transição é suave em vez de instantânea

#### Suporte multiline com token grouping

- Prop `multiline` no `AnimatedInputDisplay` — quando a expressão excede a largura mesmo com a menor fonte (28px), o display usa `Wrap` em vez de scroll horizontal
- `_groupIntoTokens()`: agrupa caracteres em tokens (números como Row inline) para que o `Wrap` só quebre entre operadores/espaços, nunca no meio de um número como "4.56"

#### Font scaling adaptativo no TimelineDisplay

- `_calculateFontLayout()`: calcula `({double fontSize, bool multiline})` com base na largura disponível
- Threshold de 88% da largura (`_shrinkThreshold = 0.88`) para disparar redução antes do texto encostar na borda
- Cascata: 48px → 36px → 28px → multiline

#### Reactive typing no CalculatorButton

- **LED glow effect**: ao pressionar um botão, texto/ícone acende na cor de destaque como um LED e apaga suavemente em 500ms (`Curves.easeOutQuart`) via `AnimationController`
- **Flash de fundo**: tap down causa flash instantâneo na cor de fundo, com retorno suave em 80ms
- Esses efeitos não estavam no plano, que previa apenas `AnimatedContainer` para feedback de toque

#### Entry animation no TimelineDisplay

- `SingleTickerProviderStateMixin` com `SlideTransition` + `FadeTransition` para animar a entrada mais recente na timeline (350ms, `Curves.easeOutCubic`)
- Novas entradas deslizam de baixo e aparecem gradualmente

#### Design System — Paleta de cores atualizada

- `AppColors` reformulado com nova paleta de 9 seed colors: Blue (#005CEE, padrão), Emerald, Orange, Cyan, Pink, Amber, Rose, Slate, Yellow
- Cores de superfície customizadas para dark (background #181818, surface #212121, surfaceContainer #2D2D2D) e light (background #F4F4F5, surface #FFFFFF, surfaceContainer #E8E8EA)
- `AppTheme` atualizado para aplicar cores de superfície customizadas no `ColorScheme.fromSeed`

#### Remoção do cursor

- Cursor piscante (`_BlinkingCursor`) removido temporariamente — será reimplementado como cursor editável com navegação por posição (planejado em "Futuro — Cursor Editável no Display" no plano)

#### Infraestrutura de testes

- `test/helpers/pump_app.dart` — Extension `pumpApp` em `WidgetTester` com setup completo (tema, l10n, dark mode) para testes de widget

---

## [Concluída] Etapa 6 — Exibição literal da porcentagem

### CalculatorViewModel

- Novo flag interno `_currentIsPercentage` indica que o operando atual está marcado como porcentagem literal
- `applyPercentage()` agora **não modifica** o valor do `Add2Engine` — apenas ativa o flag de porcentagem
  - Pré-condições: existe operador, há valor digitado, ainda não foi aplicado `%`
- `setOperator()` ao acumular o operando atual, anexa o sufixo `%` quando o flag está ativo
- `inputDigit/inputDoubleZero/inputTripleZero` (refatorados para `_prepareForDigitInput`): digitar após `%` cancela o flag e inicia novo valor para o mesmo operando
- `backspace()` remove primeiro o flag `%` (se ativo); ao restaurar partes anteriores, detecta sufixo `%` e reativa o flag
- `equals()`, `clear()` e `loadSession()` resetam o flag de porcentagem
- `_buildFullExpression()` anexa `%` ao valor atual quando flag ativo (para o evaluator)
- `_formatExpression()` e novo helper `_formatPart()` preservam o sufixo `%` literal ao formatar tokens (ex: `100.00 + 10.00%`)
- `fullDisplayText` exibe `%` literal grudado ao valor atual quando aplicável

### ExpressionEvaluator

- Sem alterações de código — o tokenizer já separava o caractere `%` automaticamente, então `10.00%` (sem espaço) é tokenizado igual a `10.00 %`
- Comportamento contextual de porcentagem mantido: `+/−` calcula percentual sobre o operando anterior; `×/÷` converte para fração

### Histórico

- A expressão persistida em `HistoryEntry` preserva o `%` literal (ex: `100.00 + 10.00%`)
- `loadSession` formata corretamente expressões persistidas com `%`

### Testes

- `calculator_view_model_test.dart` — grupo `percentage` reescrito com 8 testes (display literal em +, −, ×, ÷; sem operador; persistência no timeline; persistência no repository; encadeamento)
- `expression_evaluator_test.dart` — grupo `percentage` ampliado com 5 testes adicionais para `%` literal sem espaço (+, −, ×, ÷, encadeado)
- **Total novos: 13 testes — Total geral: 349 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 7 — Fila de processamento de toques (anti-perda em digitação rápida)

### CalculatorButton

- `onPressed` despachado no `onTapDown` (antes era no `onTap`/`tapUp`) — elimina a latência do reconhecedor de gestos e garante que o toque seja registrado **imediatamente** quando o dedo encosta no botão
- Animações (LED glow, background flash) permanecem nos handlers `tapDown`/`tapUp` e são **independentes** do despacho da ação
- `_handleTap` mantido como no-op para preservar a assinatura do `GestureDetector`
- Comportamento: tocar e arrastar para fora ainda dispara a ação (intencional — toda tecla pressionada conta)

### CalculatorViewModel

- Nova fila de ações `Queue<VoidCallback> _actionQueue` + flag `_isProcessingActions`
- Novo método privado `_runAction(action)`:
  - Se já existe ação em execução (cenário de reentrância síncrona via `notifyListeners`), enfileira e retorna
  - Caso contrário, marca como processando, executa a ação atual e drena a fila enquanto houver pendências, garantindo a ordem
- Métodos públicos do usuário envolvidos em `_runAction`: `inputDigit`, `inputDoubleZero`, `inputTripleZero`, `setOperator`, `applyPercentage`, `equals`, `clear`, `backspace`
- Nenhum `debounce`/`throttle` em qualquer ponto do pipeline

### Testes

- `calculator_view_model_test.dart` — novo grupo `action queue` com 4 testes (50 ações em rajada sem perda, ordem preservada em sequência mista, reentrância via listener síncrono, soma de 25× `1 +`)
- `calculator_keypad_test.dart` — novo grupo `rapid input` com 2 testes (rajada de dígitos sem `pumpAndSettle`, rajada mista de operadores+dígitos)
- `calculator_button_test.dart` — novo grupo `responsiveness` com 2 testes (`onPressed` no tap down via `startGesture`, 3 toques durante animação de glow são todos registrados)
- **Total novos: 8 testes — Total geral: 357 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 8 — Reorganização do keypad: delete contextual e parênteses

### Ajuste pós-implementação — Botão de apagar (`⌫`) na barra de ícones

- Botão `⌫` adicionado à barra de ícones (entre ⏱ e ⚙) — restaura a função de apagar último caractere após a remoção do `⌫` do keypad
- Cor contextual animada: `onSurface` com alpha 0.5 quando não há conteúdo; `primary` (mesma cor dos operadores) quando há conteúdo
- Transição via `TweenAnimationBuilder<Color?>` com `Curves.fastOutSlowIn` (280ms)
- `onPressed` desativado (null) quando dimmed
- Aciona `CalculatorViewModel.backspace`
- 4 novos testes em `calculator_page_test.dart` (presença, dimmed inicial, primary com conteúdo, ação de apagar)
- **Total: 398 testes — 100% verde**

### ExpressionEvaluator (`lib/domain/expression_evaluator.dart`)

- Tokenizer reconhece `(` e `)` como tokens próprios
- Novo método `_resolveParens()` resolve sub-expressões parentizadas recursivamente do interior para o exterior
  - Encontra a innermost paren (último `(` antes do primeiro `)`), avalia o miolo e substitui por seu resultado
  - Suporte a aninhamento ilimitado
  - Validação ergonômica de erros: parênteses desbalanceados (abertos ou fechados sozinhos) e parênteses vazios retornam `null`
- Resolução de porcentagem agora preserva precisão completa (não passa pelo formatador de 2 casas) — corrige cálculos como `1.5%` que antes perdiam precisão
- Resultados intermediários de parênteses também preservam precisão antes de serem reinjetados na expressão pai
- Validação inicial atualizada: primeiro token pode ser `(` (além de número)

### CalculatorViewModel (`lib/ui/calculator/calculator_view_model.dart`)

- **Modelo de estado refatorado** para suportar parênteses como tokens de primeira classe
  - Antes: `_expressionParts` em pares value/operator
  - Agora: `_committed` lista plana de tokens (números, operadores, `(`, `)`) + `_pendingOperator` + `_engineActive`
- Novo método `inputParenthesis()` com toggle inteligente:
  - Insere `(` no início, após operador, ou após outro `(`
  - Insere `)` quando há `(` pendente E o último token é um operando completo (número, `%`, `)`)
  - Após `)`, dígitos são ignorados (sem multiplicação implícita) — usuário precisa pressionar operador primeiro
- Novo getter `openParenCount` — conta `(` menos `)` no expression committed
- Novo getter `hasContent` — true quando há qualquer conteúdo cancelável (committed, operando ativo, operador pendente, timeline com entradas, ou resultado pós-`=`)
- `equals()` agora auto-fecha parênteses não balanceados antes de avaliar
- `backspace()` reescrito para o novo modelo (preservado para uso futuro, sem botão na UI)
- Comportamento existente preservado: prévia de resultado, percentage literal, fila de ações, formatação com separador de milhar

### CalculatorButton (`lib/ui/calculator/widgets/calculator_button.dart`)

- Novo parâmetro `isDimmed: bool` (default false) para variante `functional`
- Quando `isDimmed = true`: cor `onSurface` com alpha 0.5 (mesma dos ícones de ação na barra)
- Quando `isDimmed = false`: cor `primary` (operadores)
- Transição animada via `TweenAnimationBuilder<double>` com curve `Curves.fastOutSlowIn` (280ms)

### CalculatorKeypad (`lib/ui/calculator/widgets/calculator_keypad.dart`)

- Removido botão `⌫` (backspace)
- Adicionado botão `( )` no slot antigo do `⌫`
- Botão `C` agora recebe `clearIsDimmed` para colorir contextualmente
- Assinatura atualizada: `onBackspace` removido, `onParenthesis` adicionado, `clearIsDimmed` adicionado

### CalculatorPage (`lib/ui/calculator/calculator_page.dart`)

- Wiring atualizado: `onParenthesis: vm.inputParenthesis`, `clearIsDimmed: !vm.hasContent`

### Internacionalização

- Novas chaves ARB: `clearAll` e `parenthesis` (en, pt_BR, es)

### Testes

- `expression_evaluator_test.dart` — 12 testes novos (parênteses simples, aninhados, deeply nested, com %, sem espaços, paren com `%` interno, desbalanceados, vazios, sequenciais)
- `calculator_view_model_test.dart` — 19 testes novos (`hasContent` em vários estados, `openParenCount`, `inputParenthesis` em vários contextos, equals com parênteses, auto-close, nested)
- `calculator_keypad_test.dart` — reescrito com helper `buildKeypad`, novos testes para `( )`, ausência do `⌫`, propagação de `clearIsDimmed`
- `calculator_button_test.dart` — novo grupo `isDimmed` (default e animação para primary)
- `calculator_page_test.dart` — substituído teste de backspace por testes de parênteses via teclado e cor contextual do `C`
- **Total: 394 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 9 — UI do Histórico e Configurações

### Internacionalização

- Novas chaves ARB (en, pt, es): `allEntries`, `favorites`, `noHistory`, `noFavorites`, `clearHistory`, `clearHistoryConfirm`, `cancel`, `delete`, `rename`, `renameSave`, `renameHint`, `theme`, `themeLight`, `themeDark`, `themeSystem`, `color`, `numberFormat`, `language`, `languageEnglish`, `languagePortuguese`, `languageSpanish`, `languageSystem`

### HistoryPage (`lib/ui/history/history_page.dart`)

- Lista paginada com `ListView.builder` em ordem cronológica inversa
- Botão "Load more" no final da lista (quando `hasMore` é true)
- Filtro Todos/Favoritos via `SegmentedButton<bool>`
- Estado vazio: ícone + texto diferenciado para "sem histórico" e "sem favoritos"
- Botão de limpar (🗑) na AppBar com diálogo de confirmação
- Ação de limpar com `AlertDialog` (Cancel/Delete com botão de erro)
- Animação de entrada staggered: cada item anima com slide + fade (300ms, `Curves.easeOutCubic`) com delay progressivo (40ms × index, max 10)
- Retorna `HistoryEntry` via `Navigator.pop(entry)` ao tocar em um item — mantendo o SRP (HistoryPage não conhece CalculatorViewModel)

### HistoryListItem (`lib/ui/history/widgets/history_list_item.dart`)

- Card com Material Design: `Card` + `InkWell` com radius 16
- Exibe: nome (se houver, em cor primary), expressão (truncada a 30 chars com "..."), resultado ("= 75.00"), data/hora
- Expressão longa expandível: toque na expressão alterna entre truncada e completa
- Favorito: `IconButton` com `AnimatedSwitcher` + `ScaleTransition` (200ms) entre `star_outline_rounded` e `star_rounded`
- Long press: abre `AlertDialog` para renomear entrada (campo de texto com `TextCapitalization.sentences`, submit via teclado ou botão)
- Formatação de data inteligente: hora (hoje), "Yesterday, HH:mm" (ontem), "DD/MM/YYYY, HH:mm" (outros)

### SettingsPage (`lib/ui/settings/settings_page.dart`)

- Layout em `ListView` com seções separadas por `_SectionTitle` (título em cor primary, w600)
- Seções: Tema, Cor, Formato numérico, Idioma
- AppBar transparente com título centralizado
- Listener no `SettingsViewModel` para rebuild reativo

### ThemeModeSelector (`lib/ui/settings/widgets/theme_mode_selector.dart`)

- `SegmentedButton<ThemeModeOption>` com 3 opções: Light (☀), Dark (🌙), System (🔆)
- Ícones: `light_mode_rounded`, `dark_mode_rounded`, `settings_brightness_rounded`

### ColorPicker (`lib/ui/settings/widgets/color_picker.dart`)

- `Wrap` com 9 círculos coloridos (40×40) de `AppColors.seedColors`
- Seleção: borda de 2.5px (`onSurface`), sombra glow na cor, ícone ✓ com cor de contraste
- Animação: `AnimatedContainer` (200ms) para borda/sombra, `AnimatedSwitcher` (200ms) para ícone
- Cor de contraste automática via `computeLuminance()`

### DecimalSeparatorSelector (`lib/ui/settings/widgets/decimal_separator_selector.dart`)

- `SegmentedButton<DecimalSeparator>` com exemplos visuais: "1,000.00" (dot) e "1.000,00" (comma)

### LanguageSelector (`lib/ui/settings/widgets/language_selector.dart`)

- `Wrap` de `ChoiceChip` com 4 opções: System (null), English ("en"), Português ("pt"), Español ("es")
- Chip selecionado usa `primaryContainer`/`onPrimaryContainer`

### Integração — main.dart

- `WevaCalcApp` agora é `StatefulWidget` com listener no `SettingsViewModel` (singleton)
- `loadSettings()` chamado antes do `runApp` para carregar preferências ao iniciar
- `MaterialApp` recebe `theme`/`darkTheme` gerados a partir da seed color selecionada
- `themeMode` resolvido a partir de `ThemeModeOption` → `ThemeMode`
- `locale` resolvido: `null` → segue sistema, `"pt"` → `Locale('pt')`, etc.
- Mudanças de tema/cor/idioma nas Settings refletem imediatamente no app inteiro via `setState`

### Integração — dependencies.dart

- `SettingsViewModel` alterado de `registerFactory` para `registerLazySingleton` — instância compartilhada para que mudanças nas Settings propagiem globalmente

### Integração — routes.dart

- Removidos placeholders (`_PlaceholderPage`)
- `/history` → `HistoryPage(viewModel: getIt<HistoryViewModel>())`
- `/settings` → `SettingsPage(viewModel: getIt<SettingsViewModel>())`

### Integração — calculator_page.dart

- Botão ⏱ (histórico): `Navigator.pushNamed('/history')` e ao retornar com `HistoryEntry`, chama `viewModel.loadSession([entry])` para carregar a sessão
- Botão ⚙ (configurações): `Navigator.pushNamed('/settings')`

### Testes

- `history_page_test.dart` — 14 testes (renderização com título/filtro, empty state, lista com entradas, nome, expressão/resultado, load more, favoritar com star scoped, empty favorites, diálogo de confirmação, limpar confirmado, limpar cancelado, rename dialog, rename save, expressão truncada)
- `settings_page_test.dart` — 8 testes (renderização com todas as seções e sub-widgets, opções de tema, 9 cores, interações: tema, separador, idioma, system language scoped)
- **Total novos: 22 testes — Total geral: 430 testes — 100% verde**
- `flutter analyze` — zero issues

## [Concluída] Etapa 10 — Copiar e Colar

### ClipboardService

- Interface `ClipboardService` em `lib/data/services/clipboard_service.dart` com `copyText` e `readText`
- Implementação `ClipboardServiceImpl` (`clipboard_service_impl.dart`) usando `Clipboard.setData/getData` do Flutter
- Registrado como lazy singleton no GetIt
- Mock `MockClipboardService` em `test/mocks/`

### PasteInputParser

- `lib/utils/paste_input_parser.dart` — converte texto bruto em lista de tokens normalizados (`x.yy`, `+ − × ÷`, `(`, `)`, `xx.yy%`)
- Normaliza variantes de operadores (`*`/`x`/`X` → `×`, `/` → `÷`, `-` → `−`)
- Detecta separador decimal vs separador de milhar com heurística (último separador é decimal quando há ambos)
- Inteiros sempre face value, padded com `.00` (`1250` → `1250.00`, `10 + 5` → `10.00 + 5.00`)
- Decimais com ponto ou vírgula preservam casas (`12.5` → `12.50`)
- Validação de balanceamento de parênteses, posicionamento de operadores e atomicidade

### CalculatorViewModel — Copiar/Colar

- Recebe `ClipboardService` no construtor (dependência obrigatória)
- Getters derivados: `hasExpression`, `hasResult`, `hasHistory` para visibilidade dos itens do menu
- `copyExpression()` — copia `fullDisplayText` para a área de transferência
- `copyResult()` — copia `previewResult` quando disponível, ou o display pós-`=`
- `copyHistory()` — copia toda a timeline da sessão (`<expr> = <result>`, uma por linha)
- `pasteFromClipboard()` — lê, valida via `PasteInputParser`, aplica os tokens substituindo o estado atual; retorna `false` quando vazio/inválido
- `clipboardHasText()` — probe não-destrutivo usado pelo menu para habilitar/desabilitar a opção "Colar"

### CalculatorContextMenu

- `lib/ui/calculator/widgets/calculator_context_menu.dart` — menu de contexto via `showMenu`, ancorado na posição global do toque longo
- Ativado por `GestureDetector.onLongPressStart` envolvendo `TimelineDisplay` em `CalculatorPage`
- Itens visíveis condicionalmente conforme `hasExpression`/`hasResult`/`hasHistory`; "Colar" sempre presente, desabilitada quando clipboard vazio
- Snackbar de confirmação (`copied`) ou erro (`pasteInvalid`) via `ScaffoldMessenger`
- Ícones `content_copy_rounded` / `content_paste_rounded` em estilo Material rounded

### Internacionalização

- Novas strings ARB (en/pt/es): `copyExpression`, `copyResult`, `copyHistory`, `paste`, `pasteInvalid`, `copied`

### Testes

- `paste_input_parser_test.dart` — 22 testes (números isolados, expressões, operadores normalizados, parênteses, `%`, casos inválidos)
- `clipboard_service_test.dart` — 4 testes (copy/read, vazio, string vazia)
- `calculator_view_model_test.dart` — +20 testes (estado derivado `hasExpression/hasResult/hasHistory`, `copyExpression`, `copyResult`, `copyHistory`, `pasteFromClipboard` em todos os cenários)
- `calculator_context_menu_test.dart` — 5 testes (visibilidade condicional, copiar e dismiss, snackbar de erro, paste válido)
- **Total novos: 52 testes — Total geral: 482 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 11 — Cursor Editável no Display

### CalculatorViewModel — API de cursor

- `cursorPosition` (int) — offset de caractere em `fullDisplayText`; por padrão acompanha o final automaticamente
- `isEditingMidExpression` (bool) — indica modo de edição mid-expression
- `moveCursorLeft()` / `moveCursorRight()` — navegação com bounds; ao sair do final entra em modo de edição
- `setCursorPosition(int)` — posicionamento direto com clamp; voltar ao final sai do modo de edição
- Modo de edição mantém `_editText` como fonte da verdade enquanto o cursor está no meio
- `inputDigit`, `inputDoubleZero`, `inputTripleZero`, `setOperator`, `applyPercentage`, `inputParenthesis`, `backspace` operam sobre o buffer editável quando ativo
- `equals` no modo de edição avalia o texto (com normalização de separadores), persiste no histórico e sai do modo de edição
- `clear`, `loadSession` e `pasteFromClipboard` saem do modo de edição e restauram cursor ao final
- `previewResult` no modo de edição avalia `_editText` em tempo real (com normalização de milhares e separador decimal)
- `_normalizeForEvaluator` — remove separadores de milhar e converte separador decimal configurado de volta para `.`

### AnimatedInputDisplay

- Novos props: `cursorPosition` (int?), `cursorColor` (Color?), `onCharTap` (callback)
- `_BlinkingCursor` — barra vertical piscante via `Timer.periodic` (não usa `AnimationController`, mantendo `pumpAndSettle` desbloqueado)
- Cursor inserido entre os widgets de caractere na posição indicada (modo single-line)
- Cada caractere envolto em `GestureDetector` com `behavior: opaque` e `onTapDown` para tap responsivo

### TimelineDisplay & CalculatorPage

- `TimelineDisplay` propaga `cursorPosition`, `onCharTap`, `onSwipeLeft` e `onSwipeRight` para o display
- `_buildCurrentInput` envolto em `GestureDetector.onHorizontalDragEnd` com threshold de velocidade ±200 px/s
- `CalculatorPage` conecta toque em caractere → `setCursorPosition`, swipe → `moveCursorLeft/Right`

### Testes

- `calculator_view_model_test.dart` — +14 testes do grupo `cursor` (default em fim de texto, follows end, move left/right, bounds, no-op nos limites, notify, clear/equals reset, inserção/backspace/operador no meio, `previewResult` em modo edição)
- `animated_input_display_cursor_test.dart` — 3 testes (cursor ausente quando posição é null, presente quando informado, `onCharTap` recebe índice correto)
- **Total novos: 17 testes — Total geral: 499 testes — 100% verde**
- `flutter analyze` — zero issues

## [Fix] Etapa 11 — Edição Add2-aware no modo cursor

### Problema reportado

- Inserir dígitos com o cursor dentro de um valor não reaplicava Add2 (ex.: `2,37` + `1` virava `2,371` em vez de `23,71`)
- Pressionar `=` "arredondava" o resultado por consumir o texto literal sem reformatar
- Pressionar operador no meio de um número partia a expressão de forma inesperada

### Correção

- `_editInsertDigits` — extrai os dígitos brutos do bloco numérico circundante (detectado por `_findNumberBlock` sobre `[0-9.,%]`), insere o(s) novo(s) dígito(s) na posição correta dentro do bloco e re-formata via `NumberFormatter.format` (Add2 + separadores configurados)
- `_editBackspace` — reformata o bloco quando o cursor está sobre dígitos; nas bordas (entre operadores/parênteses) remove o caractere literal
- `setOperator` em modo edição — agora **salta o cursor para o fim do bloco numérico** antes de inserir ` op `, evitando partir o número ao meio
- `inputParenthesis` em modo edição — também salta para o fim do bloco antes de decidir entre `(` e `)`
- `applyPercentage` em modo edição — anexa `%` ao final do bloco (no-op se já termina em `%`)

### Testes

- 2 testes de cursor atualizados para refletir o comportamento Add2 correto:
  - `backspace in middle deletes a digit and re-applies Add2` — `12.34` → backspace digit → `1.24`
  - `setOperator in middle snaps to end of block then appends` — `12.50` cursor no meio + `+` → `12.50 + `
- 3 novos testes:
  - `inputDigit in middle re-applies Add2 to the number block` — `2.37` + `1` no meio → `23.17`
  - `inputDigit appended at end of block reformats with Add2` — bloco recebe digit no fim e reformata
  - `= evaluates the edited expression with Add2-formatted values` — fluxo completo de edição → operador → digit → `=`
- Total: **503 testes — 100% verde** | `flutter analyze` zero issues

## [Fix] Etapa 11 — Cursor ancorado pelos dígitos à direita

### Problema reportado

Em `( 1,500.00 ÷ 2.00 ) + 50.00`, com o cursor em `2.0|0`:
- Backspace produzia `0.|20` (cursor pulava uma casa para frente) em vez de `0.2|0`
- Após digitar `3`, virava `03.2|0` em vez de `02.3|0`
- Após digitar `4`, virava `32.4|0` em vez de `23.4|0`

### Causa raiz

A regra anterior de restauração do cursor preservava "número de dígitos antes do cursor" (`_positionAfterDigits`). Como Add2 padroniza com **zero à esquerda** quando o raw encurta (raw `20` → display `0.20`), esse zero "fake" deslocava a contagem e o cursor pulava.

### Correção

Trocada a política de ancoragem para preservar o número de **dígitos à direita do cursor** (`_positionWithDigitsAfter`):

- Backspace mantém digits-after constante (não muda dígitos depois do cursor)
- Inserção também mantém digits-after constante (cursor avança junto com os dígitos inseridos)
- O lado direito é a referência estável; o padding com zero à esquerda fica transparente para o usuário

Cenário do bug agora produz exatamente o que o usuário descreveu:
- `2.0|0` → backspace → `0.2|0`
- `0.2|0` → digito `3` → `2.3|0`
- `2.3|0` → digito `4` → `23.4|0` ✓

### Testes

- 1 teste de regressão exato do cenário reportado:
  - `cursor stays anchored to trailing digits across delete + insert` — reproduz o trace completo do bug
- 1 teste de cursor atualizado (`inputDigit in middle inserts at cursor`) — `12|.50` + `7` → `127.50` cursor em pos 4 (`127.|50`) com a nova regra
- Total: **504 testes — 100% verde** | `flutter analyze` zero issues

## [Fix] Etapa 11 — Operador parte/mescla blocos + crash na previewResult

### Problemas reportados

1. **Crash** ao apertar `+` em um valor editado: `RangeError (length): Invalid value: Only valid value is 0: 1` em `ExpressionEvaluator._evaluateTokens`
2. **Operador no meio do bloco**: ao digitar `+` o operador era anexado ao fim do bloco em vez de partir o bloco em duas metades
3. **Backspace no operador** deveria mesclar os blocos vizinhos, mas removia apenas um espaço

### Correções

#### `ExpressionEvaluator` defensivo (`lib/domain/expression_evaluator.dart`)

- Guard `if (i + 1 >= numbers.length) return null;` adicionado antes dos acessos `numbers[i + 1]` nos dois passes (× ÷ e + −) — expressões malformadas (operador sem RHS, parênteses com operandos faltantes) agora retornam `null` em vez de crashar

#### Operador parte o bloco (`_editSplitBlockWithOperator`)

- Quando há dígitos à esquerda E à direita do cursor dentro de um bloco, o bloco é dividido em duas metades reformatadas via Add2 (`12.50` cursor entre `2` e `.` + `+` → `0.12 + 0.50`)
- Nas bordas (cursor sem dígitos antes ou sem dígitos depois) o operador é inserido literalmente como ` op ` — comportamento atual de "anexa no limite" preservado
- Cursor pousa imediatamente após o operador inserido

#### Backspace mescla blocos (`_tryMergeBlocksAtCursor`)

- Quando o caractere antes do cursor é o espaço final de um padrão ` op ` entre dois blocos, o operador inteiro é removido e os blocos são mesclados
- **Raws são normalizados via `int.parse`** para descartar o padding de zero do Add2 antes da concatenação: `0.12` + `0.50` → `12` + `50` → `12.50` (não `120.50`)
- Cursor preserva digits-after = `rightDigits.length`, ficando no boundary visual entre as duas metades originais

#### Modo de edição persiste

- `moveCursorRight` e `setCursorPosition` **não saem mais automaticamente** do modo de edição ao chegar no fim do texto — antes, isso descartava silenciosamente as edições feitas (ex.: `2.37` editado para `23.17` voltava a `2.37` se o cursor chegasse ao fim)
- Modo de edição agora só termina em `equals()`, `clear()`, `loadSession()` ou `_applyPastedTokens()`

### Testes

- 4 testes atualizados / 1 novo:
  - `setOperator in middle splits the block into two halves` — `12.50` cursor pos 2 + `+` → `0.12 + 0.50`
  - `backspace on operator merges surrounding blocks via Add2` — após split, backspace reverte a `12.50`
  - `setOperator at start of block appends literally (no split)` — borda → ` + 12.50`
  - `backspace at start of right block merges adjacent blocks` — `0.12 + 0.34` backspace na pos 7 → `12.34`
  - `previewResult returns null for trailing operator (no crash)` — guard contra o crash
- Total: **507 testes — 100% verde** | `flutter analyze` zero issues

## [Fix] Etapa 11 — Cursor invisível em modo multiline

### Problema

Quando a expressão crescia além da largura da tela, o display entrava em modo `multiline` (Wrap) e o cursor **não era renderizado**. Sintomas:

- Após adicionar um novo bloco que estourava a linha, o cursor sumia
- Sem feedback visual, toques para reposicionar pareciam não funcionar
- Backspace continuava operando na posição lógica antiga (correta no estado), mas como o usuário não enxergava o cursor, parecia que ele "deletava do começo aleatoriamente"

### Correção

`AnimatedInputDisplay._groupIntoTokens` agora aceita `cursorPos` e `cursor`, injetando o widget do cursor no fluxo de tokens:

- Cursor dentro de um número (entre dígitos): fica preso ao mesmo grupo da `Row`, garantindo que o `Wrap` não quebre linha entre dígito e cursor
- Cursor em fronteira (espaço/operador): emitido como token próprio, podendo ser ponto natural de quebra
- Cursor no fim do texto: preso ao último grupo se houver, senão como token isolado

### Testes

- `renders cursor in multiline mode` — cursor mid-block visível em modo Wrap
- `renders cursor at end of text in multiline mode` — cursor no fim visível em modo Wrap
- Total: **509 testes — 100% verde** | `flutter analyze` zero issues

---

## [Concluída] Etapa 12 — Logo customizado e identidade visual

### Assets de Branding

- `assets/branding/logo.png` — logo principal 1024×1010 (sem padding; rounded dark corners estilo One UI)
- `assets/branding/2.0x/logo.png` e `assets/branding/3.0x/logo.png` — variantes de densidade para resolução automática pelo Flutter
- Assets declarados no `pubspec.yaml` (seção `flutter.assets`)

### Geração de Ícones (`flutter_launcher_icons`)

- Adicionado `flutter_launcher_icons: ^0.14.3` em `dev_dependencies`
- `flutter_launcher_icons.yaml` configurado para Android, iOS, Web, Windows, Linux, macOS
- Android adaptive icon: fundo `#181818` + foreground com o logo
- Gerado via `dart run flutter_launcher_icons` — artefatos versionados

### Splash Screen (`flutter_native_splash`)

- Adicionado `flutter_native_splash: ^2.4.5` em `dev_dependencies`
- `flutter_native_splash.yaml` configurado com:
  - Fundo light `#F4F4F5` / dark `#181818`
  - Logo centralizado para Android (legado + v21) e iOS
  - Android 12+ (`values-v31`): logo + fundo `#181818` (modo escuro)
- Gerado via `dart run flutter_native_splash:create`

### Widget `AppLogo`

- `lib/ui/core/widgets/app_logo.dart` — widget `AppLogo` com `Image.asset` + `SizedBox`
- Prop `size` opcional (padrão `48.0` via `AppLogo.defaultSize`)
- Flutter resolve a variante de densidade (1x/2x/3x) automaticamente

### Testes

- `test/widget/core/widgets/app_logo_test.dart` — 4 testes (widget renderiza, asset correto, tamanho aplicado, tamanho padrão)
- **Total novos: 4 testes — Total geral: 513 testes — 100% verde**
- `flutter analyze` — zero issues

## [Melhoria] Etapa 12 — Splash screen theme-aware (Android 12+)

### Problema

A splash nativa (gerada estaticamente pelo `flutter_native_splash`) só seguia o **dark mode do sistema** — se o usuário escolhesse um tema diferente do sistema dentro do app (ex: sempre escuro com o celular no modo claro), a próxima abertura mostrava um "flash" da cor errada até o primeiro frame do Flutter assumir o tema correto.

### Solução

Replicado o mecanismo do projeto irmão `verbum`: em vez de recolorir a splash já visível, a preferência de tema é espelhada no **próprio sistema operacional** (`UiModeManager.setApplicationNightMode`, Android 12+/API 31), que já decide a cor da splash **antes** do processo do app iniciar na próxima abertura.

- `NightModeService` (`lib/data/services/night_mode_service.dart`) — interface com `syncThemeMode(ThemeModeOption)`
- `NightModeServiceImpl` (`night_mode_service_impl.dart`) — resolve `ThemeModeOption.system` contra `WidgetsBinding.instance.platformDispatcher.platformBrightness` e invoca o `MethodChannel('com.wevasoft.wevacalc/night_mode')`; no-op fora do Android; engole `PlatformException`/`MissingPluginException` (sync é best-effort)
- `MainActivity.kt` — `configureFlutterEngine` registra o handler do canal; chama `UiModeManager.setApplicationNightMode` apenas em `SDK_INT >= S` (31); no-op silencioso abaixo disso (splash continua seguindo o sistema)
- `SettingsViewModel`:
  - `loadSettings()` e `setThemeMode()` sincronizam nativamente (sem `await` — não bloqueia o boot nem a troca de tema)
  - Novo `syncNativeNightMode()` — re-resolve `ThemeModeOption.system` contra o brightness atual
- `main.dart` — `_WevaCalcAppState` ganha `WidgetsBindingObserver`; `didChangePlatformBrightness()` chama `syncNativeNightMode()` para re-sincronizar se o sistema mudar de tema com o app aberto e o modo for `system`
- Registrado no GetIt como lazy singleton

### Limitações aceitas

- Sem efeito no Android < 12 (splash sempre segue o sistema nessas versões — a API `setApplicationNightMode` não existe)
- iOS ainda não implementado no projeto (Etapa 17); quando implementado, não há API pública equivalente — a splash do iOS sempre seguirá o sistema

### Testes

- `test/unit/data/services/night_mode_service_test.dart` — 7 testes (dark/light diretos, resolução de `system` via `platformBrightnessTestValue`, no-op fora do Android via `debugDefaultTargetPlatformOverride`, engolir `PlatformException`/`MissingPluginException`)
- `test/unit/ui/settings/settings_view_model_test.dart` — novo grupo `native night mode sync` com 3 testes (`loadSettings` sincroniza, `setThemeMode` sincroniza, `syncNativeNightMode` re-sincroniza)
- `test/widget/settings/settings_page_test.dart` — atualizado com `MockNightModeService`
- **Total novos: 10 testes — Total geral: 523 testes — 100% verde**
- `flutter analyze` — zero issues
- `flutter build apk --debug` — sucesso (valida compilação do Kotlin novo)
