# Changelog — Decima

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

- `main.dart` reescrito com `DecimaApp`: tema dark padrão, l10n, rotas, GetIt

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

- `DecimaApp` agora é `StatefulWidget` com listener no `SettingsViewModel` (singleton)
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
- `NightModeServiceImpl` (`night_mode_service_impl.dart`) — resolve `ThemeModeOption.system` contra `WidgetsBinding.instance.platformDispatcher.platformBrightness` e invoca o `MethodChannel('com.wevasoft.decima/night_mode')`; no-op fora do Android; engole `PlatformException`/`MissingPluginException` (sync é best-effort)
- `MainActivity.kt` — `configureFlutterEngine` registra o handler do canal; chama `UiModeManager.setApplicationNightMode` apenas em `SDK_INT >= S` (31); no-op silencioso abaixo disso (splash continua seguindo o sistema)
- `SettingsViewModel`:
  - `loadSettings()` e `setThemeMode()` sincronizam nativamente (sem `await` — não bloqueia o boot nem a troca de tema)
  - Novo `syncNativeNightMode()` — re-resolve `ThemeModeOption.system` contra o brightness atual
- `main.dart` — `_DecimaAppState` ganha `WidgetsBindingObserver`; `didChangePlatformBrightness()` chama `syncNativeNightMode()` para re-sincronizar se o sistema mudar de tema com o app aberto e o modo for `system`
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

---

## [Concluída] Etapa 13 — Suporte a teclado físico

### Mapeamento de teclas

- `lib/ui/calculator/keyboard_shortcuts.dart` — novo módulo com a tradução pura de eventos de teclado em ações da calculadora:
  - `CalculatorKeyAction` (enum) — `digit`, `doubleZero`, `operator`, `equals`, `backspace`, `clearAll`, `percent`, `parenthesis`, `cursorLeft`, `cursorRight`, `copy`, `paste`
  - `CalculatorKeyCommand` — ação + payload opcional (dígito ou símbolo do operador), com value equality
  - `KeyboardShortcuts.resolve({logicalKey, character, isControlPressed, isMetaPressed})` — função pura, testável sem widgets
- Resolução em 3 camadas, nesta ordem:
  1. Combinações com `Ctrl`/`Cmd` — apenas `+C` (copiar resultado) e `+V` (colar); qualquer outra retorna `null` para não roubar atalhos do sistema (ex.: `Ctrl+X` não vira multiplicação)
  2. `LogicalKeyboardKey` nomeada — `Enter`, `Backspace`, `Esc`, `Delete`, `←`/`→` e todo o bloco numérico (teclas sem caractere confiável)
  3. Caractere impresso (`event.character`), com fallback para `LogicalKeyboardKey.keyLabel`
- O caractere é a fonte primária da camada 3 porque `%`, `*`, `(` e `)` dependem de modificadores e de layout — o `logicalKey` reportado varia entre plataformas, o caractere não
- Cobertura: `0`–`9` e numpad, `+ - * x X /` e operadores do numpad, `Enter`/`=`/numpad, `Backspace`, `Esc`/`Delete`, `%`, `(` `)`, `←` `→`, `Ctrl/Cmd+C`, `Ctrl/Cmd+V`

### Decisões documentadas

- `.` e `,` (e `Numpad .`) → atalho `00`: Add2 não tem ponto literal, e completar os centavos é o uso natural dessas teclas (`1` + `.` → `1.00`)
- `000` não tem tecla dedicada (não há tecla física convencional) — usar `00` seguido de `0`
- `Ctrl/Cmd+C` copia o **resultado**; expressão e histórico da sessão seguem no menu de contexto
- `Backspace` não acende glow — o botão `⌫` está na barra de ícones, não no keypad

### Handler

- `lib/ui/calculator/widgets/keyboard_shortcuts_handler.dart` — envolve a `CalculatorPage` em `Focus(autofocus: true)` com `onKeyEvent`
- Cada ação chama o **mesmo método** do `CalculatorViewModel` usado pelo keypad virtual — nenhum caminho paralelo de despacho, então a fila de toques da Etapa 7 continua garantindo ordem e ausência de perda
- Aceita `KeyDownEvent` e `KeyRepeatEvent` (segurar `Backspace` apaga repetidamente); ignora `KeyUpEvent`
- Teclas não mapeadas retornam `KeyEventResult.ignored`, devolvendo o evento ao framework
- `_isTextEditingFocused()` — quando o foco primário está dentro de um `EditableText`, os atalhos são ignorados para não duplicar a digitação (rename do histórico, busca futura). A checagem sobe a árvore procurando `EditableTextState`, porque o `FocusNode` do `TextField` está ancorado no `Focus` interno do `EditableText`
- Copiar/colar reportam via callbacks `onCopied` / `onPasteFailed`; a `CalculatorPage` exibe o snackbar reaproveitando as strings existentes `copied` e `pasteInvalid` (nenhuma entrada ARB nova)

### Feedback visual

- `lib/ui/calculator/widgets/key_flash_controller.dart` — `KeyFlash` (record `{label, sequence}`) + `KeyFlashController extends ValueNotifier<KeyFlash?>`
- `CalculatorButton` recebe `keyFlash` e, quando o rótulo notificado é o seu, reproduz **a mesma** animação do toque (glow LED + flash de fundo) com fade out imediato — não existe "soltar o dedo"
- `sequence` muda a cada acionamento para que a mesma tecla repetida reinicie a animação em vez de ser descartada por igualdade de valor
- `CalculatorKeypad` ganhou constantes de rótulo (`clearLabel`, `percentLabel`, `parenthesisLabel`, `equalsLabel`, `doubleZeroLabel`, `tripleZeroLabel`) compartilhadas com o handler, evitando divergência silenciosa entre botão e atalho

### Documentação

- `docs/features/calculadora.md` — nova seção **Atalhos de Teclado** (tabela tecla → ação → método, decisões de mapeamento, camadas de resolução, feedback visual e foco), além das seções **Segurança e Cibersegurança** e **Desenvolvimento & Gotchas**

### Testes

- `test/unit/ui/calculator/keyboard_shortcuts_test.dart` — 34 testes (dígitos e numpad, operadores e variantes, equals, backspace/esc/delete, `%`, parênteses, separadores decimais, setas, `Ctrl/Cmd+C/V`, combinações modificadas ignoradas, teclas não mapeadas, value equality)
- `test/widget/calculator/keyboard_shortcuts_handler_test.dart` — 26 testes (digitação, rajada sem perda, cada operador, `Enter` e `=`, backspace com e sem conteúdo, `Esc`/`Delete`, `%` literal, expressão com parênteses, `.`/`,` → `00`, navegação e edição com o cursor, `Ctrl+C` com snackbar, `Ctrl+V` válido e inválido, glow no botão correspondente, atalhos ignorados com `TextField` focado)
- **Total novos: 60 testes — Total geral: 583 testes — 100% verde**
- `flutter analyze` — zero issues

### Pendência

- Teste manual de operação completa apenas por teclado físico — requer device/desktop com teclado real (as plataformas desktop só são habilitadas nas Etapas 14–16)
- **Resolvida na Etapa 14**: validado pelo usuário no Windows desktop, incluindo copiar/colar via `Ctrl+C`/`Ctrl+V` com os dados de `plano/fixtures-colar.md`

## [Correção] Etapa 13 — Parênteses no modo de edição

### Problema

Com o cursor no meio de um valor, o botão `( )` inseria um `)` **órfão** no fim do bloco numérico: `12.50` com cursor entre `2` e `.` virava `12.50)`. A expressão ficava inavaliável (`previewResult` = `null`) e o cursor saltava para o fim sem motivo.

Duas causas:

1. `_snapCursorToBlockEnd()` movia o cursor para o fim do bloco antes de decidir; com o caractere à esquerda passando a ser um dígito, a heurística sempre escolhia fechar
2. A decisão não consultava o balanço de parênteses — `openParenCount` contava apenas `_committed`, que fica **obsoleto** quando o modo de edição é ativado (o `_editText` passa a ser a fonte de verdade). Em edição o contador reportava `0` mesmo com `(` visível na tela

### Solução

- `openParenCount` passa a contar os parênteses do `_editText` quando o modo de edição está ativo, refletindo o que o usuário vê
- `_snapCursorToBlockEnd()` substituído por `_editInsertParenthesis()`, com a regra:
  - **fecha** (`)` no fim do bloco numérico) somente quando `openParenCount > 0` **e** o caractere à esquerda do ponto de fechamento é um operando completo (dígito, `%` ou `)`)
  - **abre** (`(` imediatamente **antes** do bloco numérico) em qualquer outro caso, agrupando o número que o cursor está tocando
- Ao abrir, o cursor mantém a posição relativa ao conteúdo (a inserção acontece à sua esquerda, então ele não salta); ao fechar, vai para depois do `)`
- Parênteses são inseridos com espaço (`( ` / ` )`), alinhando com o formato do modo normal
- `equals()` em modo de edição passa a **auto-fechar** parênteses abertos antes de avaliar, igual ao caminho commitado — sem isso, abrir um parêntese em edição deixava o `=` silenciosamente inerte

### Comportamento

| Antes | Depois |
|-------|--------|
| `12.50` cursor no meio + `( )` → `12.50)` (inválido) | → `( 12.50` |
| `10.00 + 5.00` cursor no meio do `5.00` + `( )` → `10.00 + 5.00)` | → `10.00 + ( 5.00` |
| `( 12.50` cursor no meio + `( )` → `( 12.50)` | → `( 12.50 )` |
| `( 12.50 + 3.00` cursor no 1º número + `( )` → `...)` no fim | → `( 12.50 ) + 3.00` |
| `( 12.50 + 3.00` + `=` → nada acontece | → auto-fecha e avalia (`15.50`) |

### Testes

- `test/unit/ui/calculator/calculator_view_model_test.dart` — novo grupo `parentheses in edit mode` com 9 testes (abre antes do bloco, nunca insere `)` órfão, cursor ancorado ao digitar, abre no meio de expressão, fecha no fim do bloco, fecha antes da parte final da expressão, `openParenCount` reflete o texto editado, expressão continua avaliável, `=` auto-fecha)

---

## [Melhoria] Etapa 13 — Colar linhas já resolvidas (`<expressão> = <resultado>`)

### Motivação

Colar `10 + 5 = 15` falhava (o `=` não era caractere aceito). Como `copyHistory()` produz exatamente esse formato (`<expressão> = <resultado>`, uma linha por cálculo), o ciclo **copiar histórico → colar de volta** estava quebrado.

### Solução

- `PastedContent` (em `lib/utils/paste_input_parser.dart`) — `resolvedLines` (tokens das expressões à esquerda de cada `=`) + `input` (tokens da linha final sem `=`, ou `null`)
- `PasteInputParser.parseContent(String)` — quebra o texto em linhas, ignora linhas vazias e valida cada uma. `PasteInputParser.parse` permanece intacto, servindo o caso de expressão única
- `CalculatorViewModel.pasteFromClipboard` passa a usar `parseContent`; `_applyPastedTokens` foi decomposto em `_applyPastedContent` (reset + linhas + input) e `_restoreInputTokens` (distribuição dos tokens da entrada)

### Regras

| Regra | Comportamento |
|-------|---------------|
| Resultado à direita do `=` | Apenas **validado** como número isolado; a expressão é sempre recalculada — `10 + 5 = 99` produz `15.00`, para nunca gravar no histórico um resultado que não corresponde à expressão |
| Última linha sem `=` | Vira a entrada em aberto, com prévia ativa |
| Todas as linhas com `=` | O display recebe o resultado da última, no mesmo estado que um `=` deixa (`_shouldResetOnInput`) |
| Linha em aberto antes de uma resolvida | Rejeitado — evita ambiguidade de ordem entre timeline e input |
| Expressão sem operador à esquerda do `=` | Rejeitado, igual à regra do `=` na calculadora (`10 = 5` não é um cálculo; sem essa regra viraria a linha sem sentido `10.00 = 10.00`) |
| Mais de um `=` na linha, ou `=` sem resultado | Rejeitado |
| Linha inavaliável (ex.: `10 ÷ 0 = Error`) | Aborta o paste inteiro — todas as linhas são avaliadas **antes** de qualquer mutação de estado, para não deixar a calculadora pela metade |
| Persistência | As linhas coladas entram em `_sessionLines` e são gravadas no próximo `=` ou `C` |

### Testes

- `test/unit/ui/calculator/calculator_view_model_test.dart` — novo grupo `pasteFromClipboard — resolved lines` com 17 testes (linha resolvida vai para a timeline, resultado vira o input, próximo dígito começa número novo, recálculo em vez de confiar no colado, múltiplas linhas, linhas + input em aberto, **round-trip real do `copyHistory`**, separador de milhar, persistência no `=` seguinte, e as rejeições: `=` sem resultado, linha em aberto antes de resolvida, `=` duplicado, expressão inválida, expressão como resultado, expressão sem operador, divisão por zero, linhas vazias ignoradas)
- **Total novos (correção + melhoria): 26 testes — Total geral: 609 testes — 100% verde**
- `flutter analyze` — zero issues

### Fixtures de teste manual

- `plano/fixtures-colar.md` — lista verificada de strings para testar o colar: números simples, expressões, linhas resolvidas, casos de fronteira (heurística de separador) e inválidas, com o resultado esperado de cada uma

---

## [Concluída] Etapa 14 — Suporte a Windows (com infra de desktop e title bar customizada)

### Habilitação da plataforma

- O runner nativo (`windows/`) já existia desde a criação do projeto — `flutter create --platforms=windows .` não foi necessário
- Adicionado `window_manager: ^0.5.1` em `dependencies`; `flutter pub get` regenerou os plugin registrants de Windows, Linux e macOS (`window_manager` + `screen_retriever_windows`)

### DesktopWindowConfig (`lib/ui/core/desktop/desktop_window_config.dart`)

- `windowSize` — `Size(360, 720)`, proporção mobile-like (usado como size, min e max)
- `appTitle` — `'Decima'` (título nativo da janela, usado antes do l10n estar disponível)
- `titleBarHeight` — `40.0` (altura da `AppTitleBar`)

### DesktopWindowInitializer (`lib/ui/core/desktop/desktop_window_initializer.dart`)

- `initDesktopWindow()` — chamado antes de `runApp` apenas em desktop:
  - `windowManager.ensureInitialized()`
  - `WindowOptions` com size/minimumSize/maximumSize iguais, `center: true`, `titleBarStyle: TitleBarStyle.hidden`
  - `waitUntilReadyToShow` → `setResizable(false)`, `setMaximizable(false)`, `show()`, `focus()`

### AppTitleBar (`lib/ui/core/widgets/app_title_bar.dart`)

- Barra de 40px: logo (20px) + nome do app (via `context.l10n.appTitle`) à esquerda, botões minimizar/fechar à direita — sem maximizar (janela fixa)
- Área esquerda envolta em `DragToMoveArea` (janela arrastável)
- Fundo em `colorScheme.surface` — integra-se ao tema claro/escuro e à seed color atual
- `_TitleBarButton` — botão com hover/press animados:
  - Fundo via `AnimatedContainer` (150ms, `Curves.easeOutCubic`): transparente → `onSurface` 8% (hover) → 12% (press); fechar usa `colorScheme.error` no hover e error 80% no press
  - Ícone via `TweenAnimationBuilder<Color?>`: `onSurface` 70% em repouso → `onSurface` (minimizar) / `onError` (fechar) no hover
- Callbacks `onMinimize`/`onClose` opcionais — default chama `windowManager.minimize()`/`close()`; injetáveis nos testes

### DesktopShell (`lib/ui/core/widgets/desktop_shell.dart`)

- Wrapper que adiciona a `AppTitleBar` acima do conteúdo apenas em desktop; em mobile/web retorna o `child` intacto
- `isDesktop` (static) — usa `defaultTargetPlatform` (não `Platform`) para permitir override nos testes via `debugDefaultTargetPlatformOverride`; guarda `kIsWeb` primeiro (na web `defaultTargetPlatform` reporta o SO do navegador)

### Integração — main.dart

- Em desktop: `initDesktopWindow()` antes de `runApp`; o lock de orientação portrait (`SystemChrome.setPreferredOrientations`) passou a ser aplicado apenas em mobile
- `MaterialApp` ganhou `builder` que envolve o conteúdo com `DesktopShell` — a title bar fica acima do `Navigator`, persistindo em todas as rotas (calculadora, histórico, configurações), com acesso a `Theme` e `Localizations`

### Runner nativo do Windows

- `Runner.rc` — metadados do `.exe`: `ProductName`/`FileDescription` "Decima", `CompanyName` "Wevasoft" (versão já vinha do pubspec via `FLUTTER_VERSION_*`)
- `main.cpp` — janela inicial 360×720 e título "Decima", alinhados ao `DesktopWindowConfig` para evitar flash de redimensionamento antes do `window_manager` aplicar as `WindowOptions`
- Ícone `.ico` gerado na Etapa 12 já referenciado (`IDI_APP_ICON`)

### Decisões e limitações

- Tamanho fixo não-redimensionável é decisão de UX (proporção mobile-like); snap/maximizar do Windows ficam desabilitados por consequência
- Reset de `debugDefaultTargetPlatformOverride` nos testes de `DesktopShell` acontece **dentro do corpo do teste** (não em `tearDown`) — o binding do `flutter_test` verifica as debug vars antes dos tearDowns

### Testes

- `test/widget/core/widgets/app_title_bar_test.dart` — 8 testes (logo/nome/botões, altura configurada, `DragToMoveArea`, callbacks de fechar e minimizar, hover anima fundo do fechar e do minimizar, hover out volta ao idle)
- `test/widget/core/widgets/desktop_shell_test.dart` — 7 testes (`isDesktop` true em Windows/Linux/macOS e false em Android/iOS, title bar presente em cada desktop, ausente em Android/iOS)
- **Total novos: 15 testes — Total geral: 624 testes — 100% verde**
- `flutter analyze` — zero issues

### Build validado via bridge WSL → Windows

O WSL2 não compila para Windows, mas o interop com o host permitiu validar o build daqui (mesmo mecanismo dos wrappers `adb`/`emulator` já existentes em `~/Android/Sdk`, que repassam aos `.exe` do host):

- FVM 4.1.2 ativado no Dart do Windows (`dart pub global activate fvm`) — sem tocar o Flutter global do host (3.38.5, antigo demais para o projeto)
- `fvm install 3.44.2 --setup` — mesma versão pinada do WSL
- Projeto copiado via `rsync` para uma cópia de build no filesystem do Windows (excluindo `.git`, `build`, `.dart_tool`, ephemerals) — build direto em `\\wsl.localhost\...` quebraria nos plugin symlinks e contaminaria o `.dart_tool` do WSL. Paths e comandos da máquina em `plano/local/ambiente.md` (não versionado)
- `fvm use 3.44.2 --force` + `fvm flutter build windows --release` — **sucesso** (`decima.exe` em ~68s, Visual Studio 2022 Community 17.7.3)
- App lançado no desktop do Windows (janela "Decima") para verificação manual: janela fixa 360×720, sem barra do sistema, drag pela title bar, minimizar/fechar, ícone no `.exe`

## [Fix] Etapa 14 — Tela branca no Windows: sqflite via FFI + path do banco

### Problema

O primeiro build do Windows abria uma janela **totalmente branca e sem drag**: o `window_manager` aplicava as `WindowOptions` (por isso a barra do sistema sumia), mas o `main()` do Dart morria antes do `runApp` — sem UI, sem `AppTitleBar`, sem como mover a janela.

### Causa 1 — `sqflite` não tem implementação Windows/Linux

`AppDatabase()` caía no `databaseFactorySqflitePlugin` (method channel), que só existe em Android/iOS/macOS → `MissingPluginException` no `initialize()` dentro do `main()`.

- `lib/data/database/database_factory_resolver.dart` — `resolveDatabaseFactory({bool? isDesktop})`: em desktop chama `sqfliteFfiInit()` e retorna `databaseFactoryFfi` (SQLite embutido, o mesmo dos testes); em mobile retorna o plugin nativo
- `lib/utils/platform_info.dart` — `PlatformInfo.isDesktop` extraído do `DesktopShell` (camada de dados não deve importar widget); `DesktopShell.isDesktop` agora delega
- `sqflite_common_ffi` movido de `dev_dependencies` para `dependencies`
- `dependencies.dart` — `AppDatabase(databaseFactory: resolveDatabaseFactory(), directoryResolver: resolveDatabaseDirectoryResolver())`

### Causa 2 — `sqlite3.dll` ausente no bundle Release (CMake stale)

Mesmo com o FFI, a tela seguia branca: o `sqlite3` 3.x embarca a lib nativa via **native assets/build hooks** (o hook rodou — `build/native_assets/windows/sqlite3.dll` existia e o build Debug a embarcava), mas o diretório CMake do **Release** fora configurado pelo build anterior, quando o sqlite não estava no grafo do app — as regras de install ficaram stale e a DLL não era copiada.

- Correção: `fvm flutter clean` na cópia de build + rebuild — `sqlite3.dll` passou a ser embarcada no Release
- **Gotcha geral**: sempre que o grafo de dependências ganhar/perder native assets ou plugins, rodar `flutter clean` antes do build desktop
- `sqlite3_flutter_libs` **não** é necessário (0.6.0+eol é stub vazio; o mecanismo atual são os build hooks do `sqlite3` 3.x)

### Causa 3 (descoberta na validação) — banco no CWD do processo

Com o app funcional, o `decima.db` foi parar em `C:\.dart_tool\sqflite_common_ffi\databases\` — o FFI resolve path relativo contra o **CWD do processo**, que varia conforme o atalho/terminal que lançou o app (banco "trocaria" de lugar entre lançamentos; raiz do `C:\` pode nem ser gravável).

- Adicionado `path_provider: ^2.1.6`
- `resolveDatabaseDirectoryResolver({bool? isDesktop})` — em desktop retorna resolver para `getApplicationSupportDirectory()`; em mobile retorna `null` (sqflite usa o diretório de databases do app)
- `AppDatabase` ganhou `directoryResolver` opcional — quando presente, `initialize()` monta o path absoluto (`p.join(dir, 'decima.db')`); `inMemory` ignora o resolver
- Resultado no Windows: `%APPDATA%\Wevasoft\Decima\decima.db` (o `path_provider_windows` usa CompanyName/ProductName do `Runner.rc` ajustado nesta etapa)
- Efeito colateral aceito: `path_provider_android` moderno usa JNI → `dartjni.dll` embarcada no bundle Windows (inofensiva); libs FFI do sqlite passam a ser embarcadas também no Android (não usadas em runtime — sqflite mobile segue no plugin nativo)

### Validação no host

- Bundle Release contém `sqlite3.dll`; app renderiza a calculadora completa (screenshot conferido: title bar com logo/nome/botões, display `0.00`, keypad, tema escuro) em janela fixa 360×720
- Banco criado em `%APPDATA%\Wevasoft\Decima\decima.db`; lixo em `C:\.dart_tool` removido

### Testes

- `database_factory_resolver_test.dart` — 8 testes (factory FFI vs plugin por flag e por plataforma default, FFI abre banco em memória, resolver de diretório presente em desktop/nulo em mobile/por plataforma default)
- `app_database_test.dart` — 4 testes (StateError antes do initialize, inMemory ignora resolver, banco criado dentro do diretório resolvido, sem resolver mantém path relativo)
- **Total novos: 12 testes — Total geral: 636 testes — 100% verde**
- `flutter analyze` — zero issues

## [Fix] Etapa 14 — Dígitos deslocados verticalmente no display (Windows)

### Problema (reportado em teste manual)

Com 4+ dígitos digitados (ex: `10.00`), um ou mais números ficavam **deslocados ~3px verticalmente** em relação aos vizinhos. Análise de pixels do screenshot confirmou: quatro glifos com topo em y=137 e um em y=134.

### Causa raiz

No `AnimatedInputDisplay`, os wrappers de animação (`_RollingChar`/`_PopInChar`) **permaneciam na árvore para sempre** após a animação terminar. O `_RollingChar` usava uma caixa de altura fixa `fontSize * 1.2` — calibrada implicitamente para o Roboto (line-height ≈ 1.17, erro < 1px, invisível no Android). No Windows o app renderiza com **Segoe UI** (line-height ≈ 1.33): a diferença `(1.33 − 1.2) × 48 / 2 ≈ 3.2px` deslocava o glifo dos chars que passaram por roll em relação aos estáticos.

### Correção (dupla, em `animated_input_display.dart`)

1. **Decay para texto puro** — `_markSettled(key)`: quando a animação de um slot termina (`TweenAnimationBuilder.onEnd`), o slot decai para `_AnimType.none` e o char volta a ser um `RichText` plano. Estado de repouso 100% texto puro → desalinhamento estrutural impossível, em qualquer fonte/plataforma
2. **Geometria normalizada durante a animação**:
   - `_RollingChar` — caixa definida por um **fantasma invisível** do char novo (`Opacity 0`) em vez de `fontSize * 1.2`; old/new animam por cima via `Positioned.fill` + `Center` — o slot ocupa exatamente o mesmo box de um char estático
   - `_PopInChar` — `Align` ganhou `heightFactor: 1.0` (sem ele, expande até o limite vertical disponível em contexto de altura limitada)

### Validação

- Widget tests medem o **centro vertical real de cada glifo visível** (dy global via RenderBox) após sequências de digitação Add2 com rolls/popIns — todos alinhados
- Teste estrutural: após `pumpAndSettle`, nenhum `ClipRect` de wrapper abaixo da Row de caracteres e cada char aparece exatamente uma vez
- **No host Windows** (Segoe UI real): digitado `1000` via cliques nos botões, análise de pixels do screenshot — antes: tops `137/137/137/134`; depois: **todos os dígitos em top=134/bottom=167, desvio zero**

### Testes

- `animated_input_display_alignment_test.dart` — 4 testes (alinhamento após roll coalescido, digitação Add2 passo a passo, expressão com operador, decay para texto puro)
- **Total novos: 4 testes — Total geral: 640 testes — 100% verde**
- `flutter analyze` — zero issues

### Validação manual final (usuário)

- Janela fixa 360×720, title bar customizada (drag, minimizar, fechar), ícone no `.exe`, tema escuro — tudo funcional no Windows
- Teclado físico completo (fecha a pendência da Etapa 13) e colar validado com os dados de `plano/fixtures-colar.md`
- **Etapa 14 concluída**

## [Em andamento] Etapa 14.1 — Instalador Windows (.exe)

> **Estado**: infraestrutura completa e sincronizada, **artefato ainda não gerado**. A compilação do Inno foi suspensa por lentidão (ver "Pendências" ao final). Nada foi instalado na máquina ainda.

Antecipada por necessidade de dogfooding: o empacotamento estava marcado como "fora de escopo, apenas documentar" nas Etapas 14–17, mas usar o app no dia a dia exige instalá-lo de fato. Objetivo declarado: **o instalador que dê menos atrito para quem instala**, já mirando a publicação no GitHub Releases como projeto de portfólio.

### Escolha da ferramenta

| Opção | Veredito |
|-------|----------|
| **Inno Setup 6.2** | **Escolhida** — `.exe` único, já instalado no host, sem pré-requisito para o usuário final |
| MSIX | Descartada para distribuição direta: sideload exige que o usuário instale o certificado autoassinado na Trusted Root — mais atrito que o aviso do SmartScreen. Só compensaria via Microsoft Store |

### `tool/installer/decima.iss`

- `AppId` GUID fixo — novas versões atualizam in-place em vez de instalar lado a lado
- `PrivilegesRequired=lowest` → instala em `%LOCALAPPDATA%\Programs\Decima` **sem prompt de UAC**
- `PrivilegesRequiredOverridesAllowed=commandline` (e não `dialog`): mantém `/ALLUSERS` disponível sem impor a tela de escolha de modo na abertura
- Wizard mínimo — `DisableWelcomePage`, `DisableReadyPage`, `DisableProgramGroupPage`: idioma (só se o locale não casar) → tarefas → instalar → concluir
- Idiomas `BrazilianPortuguese` + `Default` (inglês), seguindo o locale do sistema
- Menu Iniciar sempre; atalho de desktop como tarefa opcional desmarcada
- `CloseApplications=yes` — fecha o Decima aberto antes de sobrescrever os binários
- Dados do usuário em `%APPDATA%\Wevasoft\Decima` **preservados** na desinstalação (reinstalar não perde histórico)
- `ArchitecturesAllowed=x64`, `MinVersion=10.0` — `x64compatible` evitado por exigir Inno 6.3+

### `tool/installer/build_installer.sh`

- Pipeline completa da bridge WSL→Windows: `rsync` → `flutter clean` → `flutter build windows --release` → runtime C++ → `ISCC.exe` → `dist/`
- Versão lida do `pubspec.yaml` e injetada via `/DAppVersion`
- Flags `--no-clean` (pula o clean) e `--skip-build` (só reempacota o Release atual)
- Gera `.sha256` junto do instalador — sem assinatura de código, o hash é a única verificação de integridade para quem baixa
- Configuração de máquina em `local.env` (ignorado pelo git), com `local.env.example` versionado — nada de caminho de máquina no repositório público

### Runtime C++ app-local

As DLLs do redist do MSVC (`msvcp140*`, `vcruntime140*`) são copiadas para junto do `decima.exe`. Sem isso o instalador exigiria o "Visual C++ Redistributable" pré-instalado — o maior pré-requisito silencioso de apps Flutter no Windows.

### Percalços na implementação

| Problema | Diagnóstico | Correção |
|----------|-------------|----------|
| `ISCC.exe` "não é reconhecido como comando" | A interop do WSL reescreve aspas duplas ao repassar para o `cmd.exe`; o caminho do Inno tem espaços | Nenhuma aspa: o diretório entra no `PATH` da própria linha e o exe é chamado pelo nome |
| Redist do MSVC não encontrado | `find` com `-maxdepth 6`; o caminho real tem 7 níveis | Glob direto em `Program Files*/Microsoft Visual Studio/*/*/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT` |
| Alteração no `.iss` não surtia efeito | `--skip-build` pulava o `rsync` junto com o build — a cópia no Windows continuava com o `.iss` antigo | `rsync` movido para fora do bloco condicional: sincroniza sempre |
| `ISCC.exe` aparentava estar travado (CPU 0,06s) | Leitura pontual enganosa — o processo estava compactando (chegou a 600s de CPU com `lzma2/max`) | `Compression=lzma2/normal`: alguns minutos em vez de mais de dez, com diferença de tamanho marginal |

### Documentação

- `docs/fundacao/empacotamento-windows.md` — artefatos, uso, configuração, decisões de instalação, conteúdo do bundle, seção de segurança (SmartScreen, DLL hijacking, menor privilégio) e gotchas
- `README.md` — seção "Instalação (Windows)" com o aviso de SmartScreen e a orientação de conferir o SHA-256
- `docs/README.md` — índice atualizado
- `.gitignore` — `tool/installer/local.env` e `/dist/`

### Fora de escopo (documentado)

- **Assinatura de código** — certificado OV exige token HSM pago; o SmartScreen seguirá avisando
- **Auto-update** — atualizar é reinstalar por cima
- **winget / Microsoft Store**

### Pendências (retomar amanhã)

A compilação do instalador foi **suspensa** — o `.exe` nunca chegou a ser gerado. Duas rodadas foram interrompidas:

| Rodada | Compressão | Resultado |
|--------|-----------|-----------|
| 1ª | `lzma2/max` | Interrompida com 606 s de CPU, sem terminar |
| 2ª | `lzma2/normal` | Interrompida com ~690 s de CPU / 13m41s de relógio, sem terminar |

**Medição do gargalo**: `ISCC.exe` com 647 s de relógio para 634 s de CPU = **1,00 núcleo, 98% CPU-bound**. Sem espera de I/O — Defender e disco descartados. Os ~8% no Gerenciador de Tarefas são uma thread saturada sobre o total de threads lógicas.

Restam dois problemas independentes, detalhados em `plano/tarefas.md` (Etapa 14.1 → "Ajustes pendentes"):

- **A — LZMA single-thread**: `LZMANumBlockThreads=4` é a única diretiva que dá paralelismo real no Inno (ganho esperado ~3×); `LZMAUseSeparateProcess=yes` e `LZMABlockSize` complementam. **GPU está descartado** — LZMA é sequencial e cheio de desvios, não existe caminho em GPU no Inno nem nas implementações de referência
- **B — taxa absoluta anômala**: 33 MB / 634 s ≈ **52 KB/s**, uma a duas ordens de grandeza abaixo do esperado para LZMA2 normal (~2–5 MB/s). Multi-thread sozinho levaria a ~150 KB/s, ainda absurdo. Diagnóstico: rodar o ISCC **sem `/Q`** (imprime `Compressing: <arquivo>` e revela se está preso em um arquivo ou comendo mais do que os 33 MB esperados) e comparar com um baseline de 7-Zip no host

**Estado dos artefatos**: `dist/` vazio nos dois lados (WSL e cópia Windows). O build Release do Windows está pronto e íntegro na cópia (`decima.exe` + 9 DLLs do runtime C++ já staged), então retomar é só rodar `tool/installer/build_installer.sh --skip-build` depois de aplicar os ajustes.

## [Concluída] Etapa 14.1 — Instalador Windows: causa raiz da "lentidão" e artefato gerado

> **Estado**: `dist/decima-0.5.0-windows-x64-setup.exe` (12 MB) gerado em **2,6 s** de compilação, smoke test de instalação/desinstalação passou. Falta só a verificação manual interativa do usuário.

### A "lentidão" era um crash: o ISCC nunca esteve comprimindo

O diagnóstico da sessão anterior — "LZMA single-thread a 52 KB/s" — estava errado. A investigação desta sessão, na ordem:

| Passo | Evidência | Conclusão |
|-------|-----------|-----------|
| Baseline da máquina (`xz -6 -T1` no WSL, mesmo CPU) | 33 MB em 13,9 s ≈ **2,4 MB/s** | Ryzen 5 3600 nunca foi o gargalo; 52 KB/s seria ~46× abaixo do próprio hardware |
| Volume do `[Files]` | 33 MB / 27 arquivos, só o Release | O glob não estava comprimindo nada além do esperado |
| I/O do processo `ISCC.exe` durante o "trabalho" | CPU 15 s em 15 s de relógio com **0 bytes lidos e 0 escritos**; `dist/` nunca criado | O processo nunca tocou o payload — não é compressão lenta, é loop |
| Saída redirecionada para arquivo (fora do pipe interop) | Banner e depois **0% de CPU**, thread em `WaitReason: UserRequest`, `MainWindowTitle: "Error"` | Há um **diálogo modal invisível** esperando clique |
| Texto do diálogo via UI Automation | `Runtime error 216 at 02CE44A4` | GPF do runtime Delphi dentro do compilador |
| Log de eventos do Windows (`Application Error`) | `0xc0000005` em **`ISPP.dll`**, offset fixo `0x244a4`, em todas as tentativas | Crash determinístico no pré-processador do Inno |
| `.iss` mínimo (`Compression=zip`) em console nativo (`Start-Process`) | Mesmo crash | Não é o nosso script, não é LZMA, não é a interop — o **Inno Setup 6.2.2 estava quebrado nesta máquina** |

O elo com o sintoma original: chamado via interop do WSL, o diálogo de erro não tem onde aparecer e o processo degenera em **spin de 100% de CPU em 1 núcleo** — exatamente o "647 s de relógio para 634 s de CPU" medido antes. As duas rodadas interrompidas (`lzma2/max` e `lzma2/normal`) nunca teriam terminado, com qualquer compressor.

### Correção

- `winget upgrade JRSoftware.InnoSetup` → **6.7.3** (o 6.2.2 veio de instalação antiga; o upgrade mantém `C:\Program Files (x86)\Inno Setup 6`, então o `local.env` não muda)
- Compilação do instalador: de "infinito" para **2,6 s** (payload 33 MB → instalador 12 MB)

### Ajustes aplicados (das anotações + modernização)

- `LZMAUseSeparateProcess=yes` + `LZMANumBlockThreads=4` no `[Setup]` — compressão fora do processo 32-bit do compilador, em blocos paralelos; mantidos como boa prática ainda que a causa raiz fosse outra
- `/Q` removido da chamada do ISCC no `build_installer.sh` — o `Compressing: <arquivo>` por item é o que distingue "comprimindo" de "travado"; o silêncio pós-banner do 6.2.2 teria sido denunciado na hora
- `ArchitecturesAllowed`/`ArchitecturesInstallIn64BitMode`: `x64` → `x64compatible` (o 6.7 avisa deprecação de `x64`; `x64compatible` cobre também Windows ARM64 com emulação x64). Cabeçalho do `.iss` atualizado para "Inno Setup 6.3+"

### Smoke test do artefato (automatizado, máquina limpa ao final)

| Fase | Resultado |
|------|-----------|
| `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` | Bundle completo em `%LOCALAPPDATA%\Programs\Decima` + `Decima.lnk` no Menu Iniciar |
| Abrir o exe instalado | Processo sobe com janela "Decima" — runtime C++ app-local validado fora da pasta de build |
| `unins000.exe /VERYSILENT` | Pasta do programa e atalho removidos; `%APPDATA%\Wevasoft\Decima` (`decima.db` + `shared_preferences.json`) **preservado** |

### Lição de diagnóstico registrada

Processo Windows lançado via interop que "trava" consumindo CPU: antes de assumir trabalho pesado, checar **I/O do processo** (`Win32_Process.ReadTransferCount`) e **`MainWindowTitle`** — um diálogo modal invisível parece exatamente um loop CPU-bound. O texto do diálogo é legível via UI Automation sem interação.

## [Melhoria] Etapa 14.1 — Ícone Windows com cantos arredondados

> Pedido do usuário após validar o instalador: o ícone aparecia **quadrado** no instalador, no Menu Iniciar e na barra de tarefas.

O Windows (ao contrário do Android adaptativo/iOS) **não aplica máscara** ao ícone — os cantos arredondados precisam estar no próprio `.ico`, com transparência. O `app_icon.ico` anterior era um único frame de **48 px quadrado**, gerado pelo `flutter_launcher_icons` a partir do full-bleed (`icon_size: 48`).

### Mudanças

- `tool/icon/render.mjs` passa a gerar o `windows/runner/resources/app_icon.ico` no próprio pipeline: o **master** (`decima_icon_master.svg`, squircle de raio 22,4% com fundo transparente) é rasterizado direto do vetor em **16/20/24/32/40/48/64/256 px** e montado num `.ico` multi-tamanho via `png-to-ico` (nova dependência do `tool/icon`; entradas BMP — máxima compatibilidade com o shell)
- `flutter_launcher_icons.yaml`: `windows.generate: false` com comentário-guarda — reativar sobrescreveria o `.ico` com o full-bleed quadrado
- Nenhum SVG novo: o master já era o desenho arredondado da marca; agora Windows usa a mesma identidade do runtime

### Alcance

| Superfície | Origem do ícone |
|------------|-----------------|
| Menu Iniciar, barra de tarefas, alt-tab | `.ico` embutido no `decima.exe` via `Runner.rc` (exige rebuild do exe) |
| Ícone do próprio `setup.exe` | `SetupIconFile` no `decima.iss` (mesmo `.ico`) |
| "Aplicativos instalados" / desinstalação | `UninstallDisplayIcon={app}\decima.exe` |

### Gotcha — cache de ícones do Windows (validado na prática)

Após atualizar por cima, cada superfície tem cache próprio e o refresh não é uniforme:

| Superfície | Cache | O que resolveu |
|------------|-------|----------------|
| Menu Iniciar | Cache do StartMenuExperienceHost | `ie4uinit.exe -show` bastou |
| Barra de tarefas | `%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db` (um por resolução) | `ie4uinit` **não** basta: parar o Explorer → apagar os `iconcache_*.db` → reiniciar o Explorer (a janela do app em execução não é afetada; pastas abertas precisam ser reabertas) |

---

## [Concluída] Etapa 14.2 A — Flush da sessão ao fechar

> Origem: uso diário do Decima instalado no Windows. Fechar pelo `X` descartava o cálculo em andamento — só `=` e `C` persistiam.

### `CalculatorViewModel.flushSession()`

Novo `Future<void> flushSession()` público. Fecha o cálculo pendente exatamente como um `=` faria e **aguarda a escrita chegar ao banco** antes de completar.

| Estado ao fechar | Comportamento |
|------------------|---------------|
| Expressão com ao menos um operador | Avaliada e gravada |
| Parênteses abertos | Auto-fechados antes de avaliar |
| Número solto, sem operador | Não grava — não há cálculo (regra documentada) |
| Sessão vazia / logo após `=` | No-op, sem duplicar linha nem criar sessão nova |
| Cursor no meio da expressão | Mesmo caminho do `=` (o `_editText` é a fonte da verdade) |

### Refatorações que viabilizaram o flush

- `equals()` tinha os caminhos "modo de edição" e "tokens commitados" duplicados quase inteiros. Extraídos `_commitPendingCalculation()` (avalia + registra na timeline/sessão + persiste + reseta) e `_pendingRawExpression()` (normaliza, valida o operador, auto-fecha parênteses). `equals()` virou `_runAction(_commitPendingCalculation)` e `flushSession()` reusa a mesma operação — sem um segundo caminho de avaliação para manter em sincronia
- `_saveOrUpdateSession()` era **fire-and-forget**: devolve `Future<void>` e encadeia toda escrita em `_pendingWrite`, que `flushSession()` aguarda. Uma falha de escrita não envenena a cadeia — as esperas seguintes continuam completando, para o app nunca ficar impossível de fechar
- **Corrida do `_addInFlight`**: quando a 2ª linha chegava com o `add` da 1ª ainda em voo, ela era marcada como persistida e **nunca gravada**. Agora o `update` é encadeado no `Future` do `add` e usa o id que ele devolve
- **Troca de sessão com `add` em voo**: `clear`/`loadSession`/paste passam por `_resetSessionTracking()`, que incrementa `_sessionGeneration`; o `add` só adota o id se a geração não mudou (antes, o id da sessão antiga vazava para a nova). O `update` já encadeado continua gravando na sessão a que suas linhas pertencem

### `WindowCloseHandler` (desktop)

`lib/ui/core/desktop/window_close_handler.dart` — `setPreventClose(true)` + `WindowListener.onWindowClose` → `onFlush()` → `windowManager.destroy()`. Cobre o `X` da title bar, `Alt+F4` e "Fechar janela" da barra de tarefas.

| Garantia | Como |
|----------|------|
| A janela sempre fecha | `destroy()` no `finally`; exceção da gravação engolida |
| Gravação travada não prende o app | `onFlush().timeout(flushTimeout)`, 3 s por padrão |
| Testável sem method channel | `WindowCloseBridge` abstrai o plugin; os testes injetam uma ponte falsa |
| Inerte em mobile | `initState` retorna antes de registrar quando `!PlatformInfo.isDesktop` |

Montado no `MaterialApp.builder` do `_DecimaAppState`, acima do `DesktopShell`.

### Mobile

`AppLifecycleListener` no `_DecimaAppState` com `onHide` / `onPause` / `onExitRequested` — o Android encerra o processo sem garantir `detached`. Registrado **apenas** em mobile: em desktop o `onHide` também dispara ao minimizar, e fechar o cálculo em andamento ao minimizar surpreenderia o usuário.

### Testes

- `calculator_view_model_test.dart` — grupo `flushSession` com 9 cenários (expressão pendente, parênteses abertos, número solto, sessão vazia, pós-`=`, idempotência, `add` em voo, modo de edição, `update` encadeado no `add`)
- `test/widget/core/desktop/window_close_handler_test.dart` — 8 cenários (registro do listener, flush antes do destroy, flush que lança, timeout, dispose, Android, iOS)
- **Total: 657 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 14.2 B — Memória da posição da janela

> Origem: uso diário do Decima instalado no Windows. A janela sempre reabria centralizada, ignorando onde o usuário a tinha deixado.

### Fluxo

| Etapa | Onde | O quê |
|-------|------|-------|
| Gravar | `WindowCloseHandler` → `onSavePosition` | `windowManager.getPosition()` → `SettingsRepository.setWindowPosition(x, y)` |
| Ler | `initDesktopWindow()` | `getWindowPosition()` antes de montar as `WindowOptions` |
| Validar | `isWindowPositionReachable()` | Posição salva × `screenRetriever.getAllDisplays()` |
| Aplicar | `waitUntilReadyToShow` | `center: position == null`; `setPosition` **antes** do `show()` — sem piscar no centro |

### `SettingsRepository`

`getWindowPosition()` / `setWindowPosition(double x, double y)` sobre as chaves `window_x` / `window_y` do `SharedPreferences`. Trafega a entidade `WindowPosition` (`domain/entities/`), com `double` puro em vez de `Offset` — repositórios continuam sem importar Flutter. Só uma das chaves gravada (escrita interrompida) equivale a não ter posição: devolve `null`.

### Regra de alcançabilidade (`lib/ui/core/desktop/window_position.dart`)

Função pura, testada sem plugin. O critério é a **title bar** — é por ela que a janela se move: a soma das interseções da faixa `windowSize.width × titleBarHeight` com a área útil de cada monitor precisa alcançar `minGrabWidth × titleBarHeight` (80 × 40 px).

| Situação | Resultado |
|----------|-----------|
| Janela inteira dentro de um display | Restaura |
| Janela repartida entre dois monitores adjacentes | Restaura — as áreas são **somadas** entre displays |
| Só uma fatia da title bar visível, ≥ 80 × 40 px | Restaura (dá para arrastar de volta) |
| Fatia menor que o mínimo, acima do topo, abaixo da barra de tarefas | Centro |
| Monitor desconectado, mudança de resolução/DPI | Centro |
| `NaN`/infinito, lista de displays vazia, falha ao ler | Centro |

`screen_retriever` (já transitivo do `window_manager`) passou a ser declarado em `dependencies` — a validação importa `Display` direto.

### Gravação no fechamento

`WindowCloseHandler` ganhou `onSavePosition` e `WindowCloseBridge.getPosition()`. As duas gravações do fechamento rodam em `Future.wait` **sem `eagerError`** e sob o mesmo `flushTimeout`: uma travada ou com erro não impede a outra, e nenhuma impede o `destroy()`. Gravar no fechamento (e não a cada `onWindowMoved`) poupa I/O; o custo aceito é perder a última posição num encerramento anormal — a alternativa com debounce está documentada em `docs/fundacao/arquitetura.md`, sem implementar.

### Ordem no `main()`

`setupDependencies()` subiu para antes do branch de plataforma: `initDesktopWindow()` agora recebe o `SettingsRepository` por parâmetro e o `getIt` precisa estar montado. Registrar dependências não tem efeito colateral.

### Testes

- `settings_repository_test.dart` — grupo `windowPosition` com 6 cenários (default, ida e volta, coordenadas negativas, sobrescrita, só `x`, só `y`)
- `test/unit/ui/core/desktop/window_position_test.dart` — 16 cenários da função pura (dentro, secundário, origem exata, fora de tudo, monitor desconectado, parcialmente visível alcançável e não, acima do topo, abaixo da barra de tarefas, repartida entre monitores, sem display, `NaN`/infinito, display sem área útil, tamanho customizado)
- `window_close_handler_test.dart` — 4 cenários novos (posição gravada antes do `destroy`, erro ao gravar posição, erro no flush não impede a posição, sem callback não consulta o plugin)
- **Total: 683 testes — 100% verde**
- `flutter analyze` — zero issues

### Validação no Windows real

`flutter build windows --release` verde na cópia de build do host. A janela foi dirigida por script (`SetWindowPos` + `WM_CLOSE` via interop), lendo `%APPDATA%\Wevasoft\Decima\shared_preferences.json` entre as execuções:

| Cenário | Resultado |
|---------|-----------|
| 1ª abertura, sem posição salva | Centralizada em `2700,156` |
| Mover para `200,150` → fechar | `window_x: 200.0`, `window_y: 150.0` gravados |
| Reabrir | Abriu exatamente em `200,150` |
| Adulterar para `9999,9999` (monitor inexistente) → reabrir | Voltou ao centro e regravou a posição válida |
| Digitar `10 + 5` sem `=` → fechar pelo `WM_CLOSE` → conferir o banco | Linha `0.10 + 0.05 = 0.15` gravada (fecha também o pendente da parte A) |

---

## [Concluída] Etapa 14.3 — CI/CD, fluxo de branches e distribuição

Mudança estrutural de processo: o padrão husky dos outros projetos (`pre-commit`/`commit-msg`/`pre-push`) foi portado para GitHub Actions, e a `main` deixou de aceitar commits diretos.

### Fluxo de branches

- Branch `dev` criada (herdando os 3 commits não pushados da `main`) e promovida a branch padrão
- Rulesets: `main-protegida` (PR + checks `commitlint`/`analyze`/`test`/`build-android`/`build-windows` + bypass por deploy key) e `dev-integracao` (sem force-push/deleção)
- `main` local resetada para `origin/main` — todo o trabalho pendente entra via PR

### Tooling

- `.fvmrc` — pin do Flutter `3.44.2` (o CI lê daqui via ação composta `setup-flutter`)
- `commitlint.yaml` + `commitlint_cli ^0.8.1` — Conventional Commits validados no CI (o merge é ignorado pelo linter, confirmado)
- `tool/bump_version.dart` + `test/tool/bump_version_test.dart` — motor D5/D6 copiado do runway (7 testes verdes); no decima é invocado pelo `release.yml`, não por hook
- `/.github/` removido do `.gitignore` — a linha bloqueava o versionamento dos workflows
- `dart format` aplicado ao repo (26 arquivos) — gate `--set-exit-if-changed` no CI
- `build.gradle.kts` — `signingConfigs.release` lê `android/key.properties` (git-ignorado); keystore de upload em `~/.keystores/decima/decima-release.jks` e em secrets (base64). Sem o arquivo, fallback para debug (forks continuam buildando)

### Workflows

- `ci.yml` (PRs para `dev`/`main`; push na `dev`): commitlint por range, format + analyze, testes com gate de cobertura de 85% (baseline 88,4%), APK release (push na `dev` vira `X.Y.Z-dev.<run>` e distribui ao grupo `dev` do Firebase), bundle Windows zipado com runtime MSVC app-local
- `release.yml` (push na `main`): motor decide o bump pelo range desde a última tag `v*` → commit `chore(release): vX.Y.Z+B` + tag via deploy key (bypass do ruleset) → APK assinado ao grupo `stable` do Firebase com notas do `CHANGELOG.md` → instalador Inno Setup + `.sha256` → GitHub Release. Range sem bump = NOOP (nada é publicado)
- Segurança: `pull_request` (nunca `pull_request_target`), secrets ausentes em fork, `permissions: contents: read` no CI, credenciais só em `$RUNNER_TEMP`

### Firebase

- Projeto `decima-wevasoft` (app Android `com.wevasoft.decima` já registrado); grupos de testers `dev` e `stable` criados via CLI
- Sem SDK Firebase no app — App Distribution usa apenas APK + App ID + service account

### Primeiro release (validação de ponta a ponta)

- Secrets manuais configuradas pelo dev (`FIREBASE_SERVICE_ACCOUNT`, deploy key `release-bot` + `RELEASE_DEPLOY_KEY`)
- PR #1 (`dev` → `main`) mergeado com os 5 checks verdes → **v0.6.0** publicado automaticamente: `chore(release): v0.6.0+6` + tag + `CHANGELOG.md`, APK assinado no grupo `stable`, `decima-0.6.0-windows-x64-setup.exe` + `.sha256` no GitHub Release
- Anti-loop validado: o push do commit de release re-disparou o workflow, que caiu em `NOOP` e pulou os jobs de publicação

### Documentação

- Novo `docs/fundacao/ci-cd.md` (fluxo, jobs, secrets, OWASP CI/CD, gotchas)
- `README.md` com badges de CI/Release e seção "Contribuição e Release"; índice de `docs/` atualizado

### Testes

- `test/tool/bump_version_test.dart` — 7 cenários (RESULT minor/patch/major, NOOP interno, anti-loop de release, range vazio, âncora de fallback)
- **Total: 690 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Fix] Etapa 14.3 — versionCode monotônico entre dev e stable

**Problema (dogfooding)**: o release v0.6.0 saiu com `versionCode 6` (o `+B` do pubspec) e o build dev seguinte com `versionCode 4` (`github.run_number` — contador **por workflow**). Instalar o dev sobre o stable era downgrade: o Android bloqueia e obriga a desinstalar, perdendo os dados.

**Correção**: o `versionCode` de todo APK do CI (jobs `build-android` do `ci.yml` e `release-android` do `release.yml`) passa a ser `minutos desde a epoch Unix` (~29,9 mi hoje; teto do Android de 2,1 bi só no ano ~5960) — uma única sequência crescente, independente de branch/workflow. O `+B` do pubspec continua existindo apenas como contador humano de releases (nome do commit/tag), sem papel de `versionCode`.

**Gotcha documentado**: build local usa o `+B` pequeno do pubspec — para instalar por cima de um APK do CI, passar `--build-number=$(( $(date +%s) / 60 ))`.

---

## [Concluída] Etapa 15 — Suporte a Linux

O alvo Linux já vinha do `flutter create` original — `flutter create --platforms=linux .` não alterou nada em `linux/` (só reescreveu `.metadata`, derrubando as outras plataformas da lista de migração, e mexeu no `pubspec.lock`; ambos revertidos). O trabalho real foi o runner GTK e dois desvios de comportamento do `window_manager` que só aparecem no Linux.

### Runner GTK (`linux/runner/my_application.cc`)

| Desvio do template | Motivo |
|--------------------|--------|
| `GtkHeaderBar` removido | O template cria um quando o WM é o GNOME Shell. Com ele, `TitleBarStyle.hidden` apenas **esconde o widget** e mantém a decoração do lado do cliente (sombra + margem), o que desloca `getPosition`/`setPosition`. Sem ele, o plugin cai em `gtk_window_set_decorated(FALSE)` e a janela fica sem moldura em qualquer WM |
| Tamanho inicial `360x720` (era `1280x720`) | **Obrigatório, não cosmético**: `setResizable(false)` faz o GTK reescrever os geometry hints com o tamanho default da janela, sobrescrevendo o `setSize` das `WindowOptions`. Com o default do template, a janela abria e travava em 1280×720 |
| Título `Decima` (era `decima`) | Aparece no alt-tab e no dock antes de o `window_manager` aplicar as `WindowOptions` |
| `#include <gdk/gdkx.h>` removido | Só existia para a heurística de header bar em X11 |

### Ajustes de plataforma no `lib/` (dois bugs reais encontrados na validação)

**`setMaximizable(false)` vira `_NET_WM_WINDOW_TYPE_DIALOG` no GTK.** Confirmado por `xprop`: a janela era anunciada como diálogo, saindo da barra de tarefas e do alt-tab e deixando de ser minimizável em vários WMs. Como `setResizable(false)` já impede maximizar no GTK, a chamada só trazia o efeito colateral — agora é pulada quando `PlatformInfo.isLinux`.

**`getPosition()` devolve `(0,0)` no Wayland.** O protocolo não expõe coordenadas globais ao cliente. Gravar isso fazia a memória de posição (Etapa 14.2) reabrir a janela encostada no canto superior esquerdo — pior do que não lembrar nada. `isWindowPositionStorable()` (função pura, ao lado de `isWindowPositionReachable`) descarta a origem exata em Linux e `NaN`/infinito em qualquer plataforma. O falso negativo em X11 (janela realmente no canto) custa abrir centralizada da próxima vez.

Novo `PlatformInfo.isLinux` para os dois desvios — mesmo padrão testável do `isDesktop` (`defaultTargetPlatform`, não `Platform`).

### Integração com o desktop (`linux/packaging/`)

- `com.wevasoft.decima.desktop` — `Icon=com.wevasoft.decima` (nome lógico do tema, não caminho) e `StartupWMClass` casando o `WM_CLASS` da janela, que vem do `APPLICATION_ID` via `g_set_prgname`. Sem esse casamento o dock mostra ícone genérico e abre uma segunda entrada
- Ícones do tema `hicolor` em 16/24/32/48/64/128/256/512, gerados pelo `tool/icon/render.mjs` a partir do master (squircle com transparência — Linux não aplica máscara, mesma razão do `.ico` do Windows)
- **`flutter_launcher_icons` não tem suporte a Linux**: a chave `linux: generate: true` do `flutter_launcher_icons.yaml` era ignorada em silêncio desde a Etapa 12. Removida, com comentário apontando para o pipeline real
- `install-desktop-entry.sh` — publica no menu do usuário reescrevendo o `Exec` para o caminho absoluto do bundle; só escreve em `$XDG_DATA_HOME`, sem `sudo`. `--uninstall` desfaz

### Validação manual (X11 e Wayland, via WSLg)

| Cenário | Resultado |
|---------|-----------|
| Abertura, X11 | `360x720+780+180` (centralizada), `_MOTIF_WM_HINTS` com decoração zerada, `_NET_WM_WINDOW_TYPE_NORMAL` |
| Abertura, Wayland | Mesma aparência — title bar customizada, sem moldura do sistema |
| Antes da correção do tamanho | `WM_NORMAL_HINTS` min=max=`1280x720` — o `setSize` era sobrescrito |
| Antes da correção do maximizable | `_NET_WM_WINDOW_TYPE_DIALOG` |
| Keypad (`7`, `5`) | Display `0.75` — Add2 correto |
| Drag pela title bar, Wayland | Janela moveu exatamente o delta arrastado (160,100), tamanho preservado |
| Minimizar | `IsIconic: True`, processo vivo |
| Fechar pelo `X`, com `0.07 + 0.03` pendente | Processo encerrado; `decima.db` com `0.07 + 0.03 = 0.10`; posição gravada |
| Fechar no Wayland | Posição **não** gravada (origem descartada) — a janela volta a centralizar |
| Fechar no X11, janela em `500,300` | `window_x: 462.0`, `window_y: 241.0` gravados |
| Ícone e `.desktop` | `gtk_icon_theme_has_icon` resolve os 8 tamanhos; GIO acha a entrada com `Name=Decima` e o `Exec` absoluto |

### Limitações do ambiente WSLg (não são do app)

- **`_NET_WM_MOVERESIZE` não move janela sob XWayland/Weston**: o drag parecia quebrado com `GDK_BACKEND=x11`. Isolado com um GTK puro chamando `gtk_window_begin_move_drag` — falha igual, inclusive com o timestamp real do evento. Com `GDK_BACKEND=wayland` o drag funciona perfeitamente
- **`_NET_FRAME_EXTENTS` não-zero para janela sem decoração**: Weston reporta `38,38,59,38`, então a posição salva "anda" ~(38,59) a cada ciclo fechar-abrir. WMs conformes (mutter/kwin) zeram os extents quando `_MOTIF_WM_HINTS` desliga a decoração

### Documentação

- Novo `docs/fundacao/empacotamento-linux.md` — artefatos, dependências de build, desvios do runner, ajustes por plataforma, `.desktop`/ícone, referência de AppImage/Flatpak/Snap/`.deb`, dados em runtime, OWASP e gotchas
- `docs/fundacao/arquitetura.md` — infra de desktop, regra de gravação da posição e gotcha de semântica divergente por plataforma
- `README.md` com seção "Instalação (Linux)"; índice de `docs/` atualizado

### Fora de escopo (deliberado)

- Job `build-linux` no CI: exigiria um 6º check obrigatório no ruleset `main-protegida` (ação manual no GitHub) e não está na Etapa 15
- Empacotamento em si (AppImage/Flatpak/Snap) — documentado como referência, conforme o plano

### Testes

- `test/unit/utils/platform_info_test.dart` — 5 testes (novo arquivo; cobre `isDesktop` nas 6 `TargetPlatform` e `isLinux`)
- `test/unit/ui/core/desktop/window_position_test.dart` — 5 testes novos para `isWindowPositionStorable`
- **Total: 700 testes — 100% verde**
- `flutter analyze` — zero issues; `dart format --set-exit-if-changed .` sem alterações

---

## [Fix] Etapa 15 — Ícone da janela no Linux

**Problema (reportado no uso real)**: a janela abria com o ícone genérico do Linux (Tux) em vez do ícone do Decima.

**Causa**: o template do runner GTK **não define ícone de janela nenhum**. Sem `_NET_WM_ICON` o ambiente cai no fallback genérico — confirmado por `xprop -id <id> _NET_WM_ICON` → `not found`. O `.desktop` entregue na etapa resolvia apenas onde o ambiente casa a janela com a entrada pelo `StartupWMClass` (docks tipo GNOME Shell), o que não cobre o caso geral.

**Correção**: `set_application_icon()` no runner, chamado antes de criar a janela, com dois caminhos:

| Caminho | Quando | Como |
|---------|--------|------|
| Tema de ícones | `.desktop` instalado (`gtk_icon_theme_has_icon`) | `gtk_window_set_default_icon_name(APPLICATION_ID)` — respeita tema do usuário e HiDPI |
| PNG do bundle | App rodando solto, sem entrada instalada | `data/flutter_assets/assets/branding/logo.png`, resolvido por `/proc/self/exe`, em 48/128/256 (o PNG fonte tem 1024² — publicar isso encheria a propriedade X com 4 MB de ARGB) |

**Limite conhecido — Wayland**: o GTK3 não tem protocolo para enviar pixels de ícone ao compositor; lá o ícone vem do casamento `app_id` (= `APPLICATION_ID`) com o `.desktop` de mesmo nome. Funciona em GNOME/KDE com a entrada instalada, mas o Weston do WSLg não faz esse lookup e continua mostrando o Tux.

**Validação**:

| Cenário | `_NET_WM_ICON` | Ícone na barra do Windows |
|---------|----------------|---------------------------|
| X11, tema instalado | Presente (32² em diante, do tema) | Ícone do Decima (o WSLg compõe um selo do Tux por cima — comportamento dele) |
| X11, tema removido | Presente (48/128/256, do bundle) | Ícone do Decima, idem |
| Wayland | N/A (propriedade é do X11) | Tux — limitação do WSLg |

---

## [Ajuste] UX de desktop — menu de contexto no clique direito

**Motivação (reportada no uso real)**: no desktop, abrir o menu de contexto exigia manter o botão esquerdo pressionado (toque longo). O gesto natural com mouse é o clique com o botão direito.

**Mudança**: o botão secundário passa a abrir os mesmos menus que o toque longo, sem substituí-lo — dispositivos híbridos (Windows/Linux com tela sensível ao toque) respondem aos dois gestos, e nenhum é condicionado à plataforma.

| Tela | Gesto adicionado | Handler | Abre |
|------|------------------|---------|------|
| Calculadora (display) | Clique direito | `onSecondaryTapUp` no `GestureDetector` existente | `CalculatorContextMenu` (copiar cálculo/resultado/histórico, colar) |
| Histórico (item) | Clique direito | `GestureDetector.onSecondaryTap` envolvendo o `InkWell` | `AlertDialog` de renomear |

**Implementação**:

- `lib/ui/calculator/calculator_page.dart` — `_openContextMenu(viewModel, position)` extraído; `onLongPressStart` e `onSecondaryTapUp` apontam para ele com `details.globalPosition`, mantendo a âncora do menu no ponteiro
- `lib/ui/history/widgets/history_list_item.dart` — `GestureDetector(onSecondaryTap:)` envolve o `InkWell` do `Card`, porque `InkWell` só reconhece o botão primário

**Testes**:

- `test/widget/calculator/calculator_context_menu_test.dart` — 2 testes novos (menu abre no clique direito; copiar pelo item selecionado nele)
- `test/widget/history/history_page_test.dart` — 1 teste novo (dialog de renomear no clique direito)
- **Total: 703 testes — 100% verde**; `flutter analyze` zero issues

**Documentação**: `docs/features/calculadora.md` (tabela "Gestos de abertura" + 2 gotchas), `docs/features/historico.md`

---

## [Concluída] Etapa 15.1 — Pacote `.deb` e distribuição Linux no CD

**Origem**: o release v0.7.0 saiu sem artefato Linux — a Etapa 15 documentou as opções de empacotamento sem implementar. Decisão: `.deb` avulso no GitHub Release (instala com `dpkg -i`/duplo clique, sem repositório APT); loja (Flathub) fica como evolução futura.

### Empacotamento (`tool/deb/build_deb.sh`)

- Empacotamento manual com `dpkg-deb --root-owner-group` (sem `fakeroot` nem `flutter_distributor`)
- Layout FHS: bundle inteiro em `/usr/lib/decima` (relocável, `RUNPATH=$ORIGIN/lib`), symlink `/usr/bin/decima`, `.desktop` **sem reescrita** (`Exec=decima` resolve via `PATH`), ícones `hicolor` (8 tamanhos), AppStream e copyright
- `Depends` mínimo: `libgtk-3-0 (>= 3.24), libglib2.0-0 (>= 2.66), libstdc++6, libc6, zlib1g`
  - **Sem SQLite**: o bundle embute `libsqlite3.so` via native assets do `package:sqlite3` (confirmado no `lib/` do bundle + `native_assets.json`)
  - Nomes antigos funcionam no Ubuntu 24.04+ (t64): os pacotes renomeados publicam `Provides:` versionado (`libgtk-3-0t64` → `libgtk-3-0 (= 3.24.41...)`)
- Sem scripts de mantenedor — caches de menu/ícones/AppStream atualizam pelos dpkg triggers do sistema; nenhum código roda no `dpkg -i`
- Flags: `--skip-build` (CI e reempacotamento) e `--version` (validada contra `^[0-9][A-Za-z0-9.+~]*$` — entra no `control` e em `sed`)
- Saída: `dist/decima-<versão>-linux-<arch>.deb` + `.sha256` (arch por `uname -m`: amd64/arm64)

### AppStream (`linux/packaging/com.wevasoft.decima.metainfo.xml`)

- `id` = `APPLICATION_ID`, `launchable` → `.desktop`, resumo/descrição em en + pt-BR, `@VERSION@`/`@DATE@` injetados no empacotamento
- `appstreamcli validate` — ✔ sem issues; também pré-requisito de um futuro Flathub

### Bug encontrado — `kernel_blob.bin` de 53 MB no bundle release

`build/flutter_assets` é staging **compartilhado** entre debug e release: um `flutter run` (debug) anterior deixou o `kernel_blob.bin` (JIT) lá e o CMake o copiou para o bundle release — que é AOT e nunca lê o arquivo. Evidência: mtime do blob (21:10) anterior ao `libapp.so` (21:52); apagar e rebuildar release o trouxe de volta com o **mesmo** mtime (cópia, não geração). O `.deb` caía de 8,3 MB para 19 MB (27 → 79 MB instalado). Correção: o script remove `kernel_blob.bin`/`*_snapshot_data` no staging; no CI (checkout limpo, só release) o problema não existe.

### CI/CD

- `ci.yml`: job `build-linux` (needs `analyze`+`test`; push na `dev` e PR para `main` — mesmo gating do `build-windows`), toolchain via apt (`ninja-build libgtk-3-dev`), `.deb` como artefato de 14 dias
  - Versão Debian não aceita `-dev.N` (hífen separa a *Debian revision*): builds do CI usam `~dev.N`/`~pr.N` — `~` ordena **antes** da final, então atualizar do dev para o stable nunca é downgrade
- `release.yml`: job `release-linux` (`flutter build linux --release` + `build_deb.sh --skip-build --version <semver>`); `publish` agora agrega os três artefatos no GitHub Release
- Ruleset `main-protegida`: `build-linux` adicionado como 6º check obrigatório via `gh api -X PUT` (aprovado pelo usuário na sessão) — confirmado: os 6 contexts ativos no ruleset

### Documentação

- `docs/fundacao/empacotamento-linux.md` — seção "Pacote `.deb`" (layout, control, t64, triggers), tabela de formatos atualizada (`.rpm` segue referência), novos gotchas (staging compartilhado, `~dev`) e vetores (injeção via `--version`, instalação como root)
- `docs/fundacao/ci-cd.md` — jobs `build-linux`/`release-linux`, 6 checks, `.sha256` do `.deb`
- `README.md` — "Instalação (Linux)" reescrita: `.deb` do release como caminho principal, bundle manual como alternativa sem root

### Validação

- `tool/deb/build_deb.sh --skip-build` → `dist/decima-0.7.0-linux-amd64.deb` (8,3 MB; 27 MB instalado) + `.sha256`
- `dpkg-deb --info`/`--contents` — control, permissões (root:root, 755/644), symlink e layout corretos
- Smoke test sem root: `dpkg-deb -x` + execução via `usr/bin/decima` (symlink) sob WSLg — janela abre, layout relocado resolve libs (`RUNPATH`) e assets (`/proc/self/exe`)
- Instalação real (`sudo dpkg -i`) — **validada pelo usuário**: app instalado, aberto e operando lado a lado com o build Windows. O dpkg trigger regenerou o `icon-theme.cache`; `xprop` confirmou `_NET_WM_ICON` (do tema) e `WM_CLASS` sob X11. Dois quirks do WSLg observados e documentados: Tux na barra de tarefas (Wayland sem lookup `app_id`→`.desktop`) e janela menor que o build Windows (WSLg renderiza a 100% e ignora a escala de DPI do monitor) — nenhum ocorre em desktop Linux real
- Achado da validação: `hicolor-icon-theme` incluído no `Depends` — fornece o `/usr/share/icons/hicolor/index.theme` sem o qual o GTK não resolve os ícones instalados (presente na máquina do teste, mas não garantido em sistemas mínimos)
- Workflows: YAML validado; `build-linux` verde nas duas primeiras execuções (push da `dev` e PR #3, ~1m20s cada)
- **Release v0.8.0** (PR #3, merge com 6 checks verdes): primeiro release com artefato Linux — `decima-0.8.0-linux-amd64.deb` + `.sha256` publicados no GitHub Release ao lado do APK e do instalador Windows

---

## [Concluída] Remoção do suporte a iOS (Etapa 17 cancelada)

**Origem**: levantamento sobre desenvolver para Apple sem conta paga. Conclusão: macOS e iOS têm caminhos opostos — o macOS distribui via assinatura ad-hoc (`CODE_SIGN_IDENTITY = "-"`, já default no template, com atrito de Gatekeeper), enquanto o iOS **não tem nenhum** caminho sem o Apple Developer Program (US$ 99/ano): sem TestFlight, sem App Store, e build com Apple ID gratuito expira em 7 dias até no próprio dispositivo. A Etapa 17 entregaria só um `flutter build ios --no-codesign` verde. Decisão: remover o iOS e manter o macOS (Etapa 16 segue pendente).

### Removido

- Pasta `ios/` — 52 arquivos versionados + 7 artefatos gerados (entre eles um `flutter_export_environment.sh` ainda apontando para o path antigo `flutter/wevacalc/`)
- `flutter_launcher_icons.yaml` — `ios: true` e `remove_alpha_ios: true`; comentários de `image_path` ajustados
- `flutter_native_splash.yaml` — `ios_content_mode`; chave `ios` fixada em `false`
- `.gitignore` — `**/ios/Flutter/.last_build_id`

### Gotcha — os dois pacotes têm defaults opostos para a chave `ios`

| Pacote | Chave ausente | Ação tomada |
|--------|---------------|-------------|
| `flutter_launcher_icons` 0.14.4 | `this.ios = false` (`lib/config/config.dart:25`) | comentar a linha basta |
| `flutter_native_splash` 2.4.8 | `!containsKey(ios) \|\| ios == true` (`lib/cli_commands.dart:194`) → **gera iOS** | `ios: false` **explícito** — apagar a linha reativaria a geração |

### Preservado (intencional)

- Os `case TargetPlatform.iOS:` em `PlatformInfo.isDesktop`/`isLinux` e os testes que os cobrem (`platform_info_test.dart`, `desktop_shell_test.dart`, `window_close_handler_test.dart`, `night_mode_service_test.dart`) — `TargetPlatform` é enum do Flutter e o `switch` precisa continuar exaustivo, independente das plataformas suportadas. **Nenhuma linha de código Dart foi alterada nesta remoção.**
- Registros históricos das Etapas 12 e 14 que mencionam iOS no escopo original — o changelog é append-only

### Reversão

`flutter create --platforms=ios .` regenera o runner em segundos, caso a assinatura paga seja adquirida.

### Validação

- `flutter analyze` — zero warnings
- `flutter test` — 100% verde (regressão intacta)

---

## [Concluída] Etapa 16 — Suporte a macOS

**Objetivo**: habilitar o build macOS reutilizando a infra de desktop da Etapa 14, respeitando as convenções da plataforma (semáforo nativo, janela fixa).

### Contexto de ambiente

- Primeira etapa executada no MacBook. O `flutter` global da máquina (3.41.7) tinha rebaixado o `pubspec.lock` num `pub get` anterior — restaurado e regenerado com o FVM do projeto (3.44.2). Regra registrada: sempre `fvm flutter ...` neste repo
- O runner `macos/` já existia desde a fundação (commit `a64f457`), renomeado na migração WevaCalc→Decima — `flutter create --platforms=macos .` não foi necessário

### Implementado

- `PlatformInfo.isMacOS` — mesmo padrão testável de `isLinux` (guard de `kIsWeb` + `defaultTargetPlatform`)
- `AppTitleBar` com variante macOS: sem botões customizados de minimizar/fechar (o semáforo nativo permanece visível com `TitleBarStyle.hidden`, sobreposto ao canto superior esquerdo); logo + nome **centralizados** — convenção de título do macOS e desvia do semáforo sem precisar de inset mágico. `DragToMoveArea` cobre a barra inteira
- `MainFlutterWindow.swift`: `import window_manager` + `hiddenWindowAtLaunch()` no override de `order(_:relativeTo:)` — setup documentado do plugin; sem ele a janela pisca no tamanho do template antes de o Dart aplicar as `WindowOptions`
- Docs: `docs/fundacao/empacotamento-macos.md` (build, distribuição ad-hoc + Gatekeeper, fluxo Developer ID/notarização como referência); seção "Instalação (macOS)" no `README.md`; índice em `docs/README.md`

### Decisões e achados

| Achado | Detalhe |
|--------|---------|
| Botão verde | `setMaximizable(false)` no macOS **não** desabilita o botão — só veta o zoom em `windowShouldZoom`. Quem o deixa cinza é o `setResizable(false)` (remove `.resizable` do `styleMask`), já chamado desde a Etapa 14. Nenhuma mudança no `initDesktopWindow` |
| Semáforo | `windowButtonVisibility` default `true` mantém os três botões; `false` esconderia o semáforo inteiro (não há API por botão no `window_manager`) — default mantido |
| CocoaPods removido | O primeiro build adicionou integração **dupla** (SwiftPM + CocoaPods). Todos os plugins macOS são Swift Packages e o próprio Flutter recomenda deintegrar: `pod deintegrate` + `Podfile`/`Podfile.lock` apagados + `Flutter-*.xcconfig` e workspace revertidos. Segundo build verde só com SwiftPM, sem avisos |
| Entitlements | Release mínimo (`app-sandbox` apenas); `allow-jit`/`network.server` só em DebugProfile. Dados do app ficam no container `~/Library/Containers/com.wevasoft.decima/` |
| Ícone | `AppIcon.icns` compilado pelo Xcode a partir do appiconset regenerado na Etapa 12 — nenhum `.icns` versionado no repo (comportamento esperado) |

### Testes

- `app_title_bar_test.dart` — novo grupo "AppTitleBar on macOS": botões ocultos, logo+nome centralizados (centro geométrico do conteúdo ≈ centro da barra), drag area e altura preservadas
- `platform_info_test.dart` — grupo `PlatformInfo.isMacOS` espelhando o de `isLinux`

### Validação

- `fvm flutter build macos --release` — `decima.app` 49,1 MB, universal (x86_64 + arm64), `codesign` confirma `Signature=adhoc` e `AppIcon.icns` no bundle
- `flutter test` — 709 testes, 100% verde
- `flutter analyze` — zero warnings; `dart format` — 0 mudanças
- Verificação manual (janela fixa, semáforo nativo, verde inativo) — **validada pelo usuário**

---

## [Ajuste] Etapa 16 — Ícone do Dock, nome do bundle e instalação local

**Origem**: validação visual do usuário — o ícone aparecia **quadrado** no Dock (e o bundle se chamava `decima.app`, que renderizaria "decima" minúsculo no launcher).

### Ícone do Dock (squircle com margens)

- Causa: `macos.image_path` apontava para o **full-bleed quadrado** — mas o macOS, como Windows/Linux, **não aplica máscara**; o squircle precisa estar no próprio PNG, e a convenção Big Sur ainda exige margens (ícone ocupa 824 dos 1024 px do canvas, senão fica maior que os vizinhos)
- `tool/icon/render.mjs` ganhou o passo `decima_icon_macos.png`: master (squircle 22,4% ≈ 22,5% do grid da Apple) rasterizado a 824 px e centrado em canvas 1024 transparente
- Sem node neste Mac, o PNG foi gerado por um one-off Swift/CoreGraphics equivalente a partir de `assets/branding/logo.png` (o próprio master em 1024 do pipeline); o próximo `npm run render` no WSL regenera o arquivo canônico
- `fvm dart run flutter_launcher_icons` regenerou só o `AppIcon.appiconset` (Android/web idênticos — pipeline determinístico)

### Nome do bundle

- `PRODUCT_NAME = Decima` em `AppInfo.xcconfig` (`CFBundleName`/executável/`.app` acompanham); refs `decima.app` atualizadas no `project.pbxproj` (product + `TEST_HOST` ×3) e no `Runner.xcscheme` (`BuildableName` ×5)
- Gotcha real: APFS é case-insensitive — `decima.app` e `Decima.app` são a mesma entrada; um `rm` de "limpeza" no nome antigo apagou o bundle novo (rebuild resolveu). Documentado

### Instalação local

- `ditto` do `Decima.app` para `/Applications` + `lsregister -f` — app no Launchpad/Spotlight como qualquer outro; sandbox container (`com.wevasoft.decima`) inalterado, histórico preservado
- Docs: `empacotamento-macos.md` (linha de instalação, fonte do appiconset, 2 gotchas novos) e `README.md` (bloco de instalação)

### Validação

- `fvm flutter build macos --release` → `Decima.app` (49,1 MB); `codesign` ad-hoc ok; `CFBundleName = Decima`
- Instalado e aberto de `/Applications` — ícone arredondado no Dock **pendente de confirmação visual do usuário**

---

## [Concluída] Etapa 16.1 — Distribuição macOS no CD e enxugamento do canal dev

**Origem**: a Etapa 16 deixou o macOS buildando só na máquina do dev — nenhum release publicava artefato. Na mesma passada, decisão do usuário: aposentar a distribuição Firebase do canal `dev` (o APK de push na `dev` já sai como artefato do Actions e o grupo de testers `dev` nunca teve uso real).

### Empacotamento (`tool/macos/build_zip.sh`)

- Guard de plataforma: aborta fora do `Darwin` — `ditto`/`codesign`/`xcodebuild` não existem em Linux/Windows
- Nome do bundle lido de `PRODUCT_NAME` no `AppInfo.xcconfig` (`Decima.app`) em vez de constante duplicada no script
- `codesign --verify --strict` **antes** de compactar: a assinatura ad-hoc é o que garante integridade do bundle sem conta paga — falhar aqui é falhar cedo
- `ditto -c -k --keepParent` + `shasum -a 256`; saída em `dist/decima-<versão>-macos.zip` (+ `.sha256`), mesmas flags do `build_deb.sh` (`--skip-build`, `--version`)

### CI/CD

| Workflow | Mudança |
|----------|---------|
| `ci.yml` | Job `build-macos` (`macos-latest`, needs `analyze`+`test`, mesmo gating do `build-windows`/`build-linux`) — zip `-dev.N`/`-pr.N` como artefato de 14 dias |
| `ci.yml` | Removidos os steps de distribuição Firebase do grupo `dev` e o env `HAS_FIREBASE` — o CI passa a **não distribuir nada** |
| `release.yml` | Job `release-macos` + artefato somado ao `publish` (7 jobs no total) |
| Ruleset `main-protegida` | `build-macos` como 7º check obrigatório |

### Decisões e achados

| Item | Detalhe |
|------|---------|
| `ditto` obrigatório | O `upload-artifact` não preserva permissões nem symlinks: subir o `.app` cru entregaria um bundle inexecutável. O job compacta antes do upload — o artefato do Actions é um zip com o zip do `ditto` dentro |
| Sufixo de versão | O zip não tem a restrição do `.deb` (`~dev.N`): usa `-dev.N`/`-pr.N`, igual ao bundle do Windows |
| Sem secrets Apple | O CI assina ad-hoc como a máquina local — sem Developer ID nem notarização (conta paga fora do escopo); o SHA-256 no release é a verificação de integridade |
| SwiftPM | Ligado por padrão no canal stable do Flutter 3.44.2 (`features.dart`) — nenhum `flutter config` extra no runner; CocoaPods segue fora do projeto |
| Firebase | O grupo `stable` do `release.yml` ficou intacto; só o canal `dev` foi aposentado (o grupo pode ser apagado no console) |

### Documentação

- `docs/fundacao/empacotamento-macos.md` — script na tabela de artefatos/comandos, seção **CI/CD** (matriz contexto→job→artefato) e 2 gotchas novos (`zip` comum destrói o bundle; script só roda no macOS)
- `docs/fundacao/ci-cd.md` — jobs novos, 7 checks obrigatórios, "o CI não distribui nada", Firebase restrito ao `release.yml`, 4 gotchas novos (upload-artifact, runner arm64/universal, sem secrets Apple, CocoaPods)
- `README.md` — Instalação (macOS) a partir do GitHub Release (com `ditto -x -k`), bloco de compilação local preservado

### Validação

- `flutter analyze` / `flutter test` / `dart format` — regressão intacta (etapa sem código Dart)
- `bash -n tool/macos/build_zip.sh` — sintaxe ok; execução real só no runner macOS
- CI `build-macos` verde no push da `dev` (4m49s) e no PR #4 para a `main` — 7 checks obrigatórios verdes
- Release **v0.9.0**: `decima-0.9.0-macos.zip` (20,2 MB) + `.sha256` publicados junto do APK, do instalador Windows e do `.deb`
- Zip conferido fora do runner: `sha256sum -c` OK, `Decima.app/` com 88 arquivos (49,0 MB) e `_CodeSignature` preservado, binário **universal** (x86_64 + arm64), `CFBundleShortVersionString = 0.9.0`
- Abrir o zip do release em outro Mac (Gatekeeper) — **pendente de verificação do usuário**

---

## [Fix] Etapa 14.2 — Fechamento lento da janela no Windows

**Problema (reportado no uso real)**: no Windows, clicar no `X` deixava a janela na tela por alguns segundos antes de ela sumir — regressão introduzida junto com o flush da sessão ao fechar (Etapa 14.2 A). Linux e macOS não apresentavam o atraso.

**Causa**: `windowManager.destroy()` não tem a mesma semântica nos três desktops.

| Plataforma | O que o plugin faz (`window_manager` 0.5.2) | Efeito na janela |
|------------|---------------------------------------------|------------------|
| Linux | `_is_prevent_close = false` + `gtk_window_close()` | Some na hora |
| macOS | `NSApp.terminate(nil)` | Some na hora |
| Windows | `PostQuitMessage(0)` | **Continua na tela** durante todo o desligamento do engine |

No Windows, `PostQuitMessage(0)` apenas enfileira `WM_QUIT`: nenhuma janela é destruída. Antes do `setPreventClose(true)` o `WM_CLOSE` seguia para o `DefWindowProc`, que chama `DestroyWindow` — a janela sumia no ato e o encerramento do engine acontecia com ela já fora da tela. Com a interceptação, esse caminho deixou de existir e o custo de shutdown virou tempo de tela.

**Correção**: `WindowManagerCloseBridge.destroy()` desvia só no Windows para `setPreventClose(false)` + `close()`. O novo `WM_CLOSE` chega ao `DefWindowProc` sem ser interceptado, `DestroyWindow` roda e o fechamento volta a ser instantâneo. Linux e macOS seguem no `destroy()` direto.

O desvio tem um eco: o plugin emite o evento `close` **antes** de consultar o `preventClose`, então esse `close()` reentra no handler como um novo `onWindowClose`. Trava `_closing` no `_WindowCloseHandlerState` absorve o eco — e, de quebra, cliques repetidos no `X` enquanto as gravações rodam, que antes disparavam um flush por clique. A trava só é liberada se o próprio `destroy()` falhar, para o app nunca ficar impossível de fechar.

**Arquivos**:

| Arquivo | Mudança |
|---------|---------|
| `lib/ui/core/desktop/window_close_handler.dart` | Desvio de plataforma no `destroy()` da ponte real; trava `_closing`; `destroy()` do `finally` protegido por `try` |
| `lib/utils/platform_info.dart` | `PlatformInfo.isWindows` |

**Testes**:

- `test/unit/ui/core/desktop/window_manager_close_bridge_test.dart` (novo) — 3 testes espionando o canal `window_manager`: Windows emite `setPreventClose(false)` + `close`; Linux e macOS emitem `destroy`
- `test/widget/core/desktop/window_close_handler_test.dart` — 3 testes novos (clique repetido durante o flush, eco do `close` após o `destroy`, trava liberada quando o `destroy` falha)
- **Total: 715 testes — 100% verde**; `flutter analyze` zero issues

**Documentação**: `docs/fundacao/arquitetura.md` — subseção "`destroy()` por plataforma", 2 garantias novas na tabela do fechamento e 2 gotchas

**Validação manual (Windows)** — build de release da cópia `decima-winbuild`, os três caminhos que chegam como `onWindowClose`:

| Caminho | Janela some no ato | Flush |
|---------|--------------------|-------|
| `X` da title bar | Sim | `10 + 5` sem `=` → gravado no mesmo segundo do fechamento |
| `Alt+F4` | Sim | `10 + 5` sem `=` → gravado no mesmo segundo do fechamento |
| "Fechar janela" na barra de tarefas | Sim | `10 + 5` sem `=` → gravado no mesmo segundo do fechamento |

Medição por script (`PostMessage WM_CLOSE` → janela invisível): **155 ms**. Nos três fechamentos manuais o processo sobreviveu à janela por 43–48 ms — é o desligamento do engine que antes acontecia com a janela ainda na tela.

---

## [Fix] Etapa 18 — Moldura verde de foco no Android com teclado físico

**Problema (reportado na revisão da Etapa 18)**: com teclado físico no Android, a calculadora respondia corretamente, mas a **primeira tecla** acendia uma moldura verde na borda da tela, que permanecia durante toda a digitação.

**Causa**: não é do app. A primeira tecla física tira a janela do *touch mode*; a partir daí o Android desenha o **realce de foco padrão** (`defaultFocusHighlight`) na view focada. A view focada é a `FlutterView`, que ocupa a tela inteira — o realce vira uma moldura na borda do app. O verde-lima é a cor do realce no One UI.

**Correção**: `MainActivity.onStart()` chama `disableDefaultFocusHighlight(window.decorView)`, que percorre a hierarquia e desliga `defaultFocusHighlightEnabled` em cada view. Guard de API 26 dentro da própria função (o `minSdk` do projeto é 24; abaixo de 26 o framework não desenha o realce). O feedback de foco do app continua sendo o glow do botão equivalente no keypad, do `KeyFlashController` (Etapa 13).

| Alternativa descartada | Motivo |
|------------------------|--------|
| `<item name="android:defaultFocusHighlightEnabled">false</item>` no tema | É atributo de `View`, não de janela: o tema da Activity não alcança a `FlutterView`, que é criada programaticamente (`defStyleAttr = 0`) |
| `FlutterActivity.FLUTTER_VIEW_ID` direto | Depende de constante do embedding; percorrer o `decorView` cobre também as views que o engine adiciona ao redor |

**Arquivo**: `android/app/src/main/kotlin/com/wevasoft/decima/MainActivity.kt`

**Validação**: `flutter build apk --debug` — sucesso (compila o Kotlin novo); `flutter analyze` zero issues e 715 testes verdes (nenhum código Dart alterado). **Verificação no device com teclado físico pendente do usuário.**

**Documentação**: `docs/features/calculadora.md` — bullet em "Feedback visual e foco" e gotcha novo
