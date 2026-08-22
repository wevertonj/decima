# Plano de Implementação — Decima

## Resumo

O projeto está dividido em **18 etapas** sequenciais. As **etapas 1-4** cobrem toda a lógica de negócio, dados e infraestrutura (sem UI). As **etapas 5-8** cobrem a UI da calculadora e ajustes de comportamento (porcentagem, fila de toques e parênteses + delete). A **etapa 9** cobre as demais telas (histórico e configurações) e integração de navegação. A **etapa 10** adiciona suporte a copiar e colar via menu de contexto. A **etapa 11** introduz o cursor editável no display. A **etapa 12** substitui o icônico/splash padrão do Flutter pelo logo próprio do Decima. A **etapa 13** habilita operação por teclado físico. As **etapas 14-17** habilitam o suporte multi-plataforma (Windows, Linux, macOS, iOS), com janela fixa e title bar customizada nas plataformas desktop. A **etapa 18** é a revisão final, cobrindo polimento de animações, fluxos completos (incluindo clipboard, cursor, teclado físico e title bar) e qualidade geral em todas as plataformas. Cada etapa cabe na janela de contexto de 172k tokens. Todas seguem o fluxo TDD obrigatório (Red → Green → Refactor).

---

## Etapa 1 — Fundação e Infraestrutura

**Objetivo**: Estabelecer a base do projeto — dependências, estrutura de pastas, tema, layout, injeção de dependência, rotas e internacionalização.

**Escopo**:

- Atualizar `pubspec.yaml` com todas as dependências (get_it, sqflite, shared_preferences, mocktail, etc.)
- Criar estrutura de pastas (`config/`, `data/`, `domain/`, `ui/`, `utils/`)
- `AppLayout` — constantes de spacing, padding, radius
- `AppColors` — 9 seed colors disponíveis
- `AppTheme` — ThemeData claro e escuro com `ColorScheme.fromSeed()`
- `dependencies.dart` — configuração inicial do GetIt
- `routes.dart` — configuração de rotas (Calculator, History, Settings)
- Setup de internacionalização (l10n.yaml, ARB pt/en, extension `context.l10n`)
- `main.dart` — entry point limpo usando a infraestrutura criada (tela placeholder)

**Testes**:

- Unitários: `AppLayout` (valores de spacing/padding/radius)
- Unitários: `AppColors` (lista de seed colors)
- Unitários: `AppTheme` (geração de ThemeData claro/escuro)

**Entregável**: App compila e roda com tela placeholder, tema funcional, l10n configurado, `flutter test` e `flutter analyze` passando.

---

## Etapa 2 — Domínio e Camada de Dados (base)

**Objetivo**: Criar as entidades de negócio, enums, models de banco, database helper e o HistoryRepository com CRUD básico.

**Escopo**:

- **Entities**: `Calculation` (expression, result, timestamp)
- **Entities**: `HistoryEntry` (id, expression, result, createdAt)
- **Enums**: `OperationType` (add, subtract, multiply, divide)
- **Enums**: `ThemeModeOption` (light, dark, system)
- **Enums**: `DecimalSeparator` (dot, comma)
- **Models**: `HistoryModel` (toMap, fromMap, toEntity)
- **Database**: `AppDatabase` (SQLite helper)
- **Repository**: `HistoryRepository` (interface) — getAll, add, delete, clear
- **Repository**: `HistoryRepositoryImpl` (implementação com SQLite)
- Registrar database e repository no GetIt

**Testes**:

- Unitários: Criação e propriedades das entities
- Unitários: Valores dos enums
- Unitários: `HistoryModel` (serialização/deserialização toMap/fromMap/toEntity)
- Unitários: `HistoryRepositoryImpl` (CRUD com banco em memória)

**Entregável**: Camada de dados base completa e testada.

---

## Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação)

**Objetivo**: Estender a camada de dados com suporte a nome customizado, favoritos e paginação no histórico. Como não há usuários ainda, o schema do banco é alterado diretamente (sem migration versionada).

**Escopo**:

- **HistoryEntry**: Adicionar campos `name` (String?, opcional) e `isFavorite` (bool, default false)
- **HistoryModel**: Adicionar campos `name` e `isFavorite` com serialização
- **Schema SQLite**: Adicionar colunas `name TEXT` e `is_favorite INTEGER NOT NULL DEFAULT 0`
- **HistoryRepository** (interface): Novos métodos:
  - `getPaginated(limit, offset)` — paginação com LIMIT/OFFSET
  - `getFavorites(limit, offset)` — apenas favoritos, paginado
  - `updateName(id, name)` — renomear entrada
  - `toggleFavorite(id)` — alternar favorito
  - `getById(id)` — buscar entrada individual
- **HistoryRepositoryImpl**: Implementação dos novos métodos
- Atualizar fixtures e testes existentes para incluir os novos campos

**Testes**:

- Unitários: `HistoryEntry` com name e isFavorite (criação, copyWith, equality)
- Unitários: `HistoryModel` com novos campos (toMap, fromMap, toEntity, fromEntity)
- Unitários: `HistoryRepositoryImpl` — getPaginated, getFavorites, updateName, toggleFavorite, getById

**Entregável**: Camada de dados completa com suporte a nome, favorito e paginação. Pronta para ser consumida pelos ViewModels.

---

## Etapa 3 — Motor da Calculadora (Add2 + Avaliação de Expressões)

**Objetivo**: Implementar toda a lógica de negócio da calculadora — entrada Add2, parsing e avaliação de expressões, e o CalculatorViewModel.

**Escopo**:

- **Add2Engine**: Lógica de entrada com 2 casas decimais automáticas
  - Inserção de dígitos (`inputDigit`)
  - Backspace com reajuste (`deleteLastDigit`)
  - Formatação do valor atual (`formattedValue`)
  - Reset
- **ExpressionEvaluator**: Parser e avaliador de expressões matemáticas
  - Operações básicas (+, −, ×, ÷)
  - Porcentagem (%)
  - Tratamento de erros (divisão por zero, expressão inválida)
- **NumberFormatter**: Formatação de números com separador configurável (ponto/vírgula) e separador de milhar
- **CalculatorViewModel**:
  - Gerencia a entrada Add2 para o número atual
  - Monta a expressão completa (números + operadores)
  - Exibe prévia do resultado em tempo real
  - Confirma cálculo (`=`) e adiciona ao histórico
  - Timeline de cálculos da sessão atual com "load more" para sessões longas
  - Controle de quantidade visível na timeline (ex: últimas 20 linhas) com carregamento sob demanda
  - Integração com `HistoryRepository` para persistir resultados
  - Carregamento de sessão a partir do histórico

**Testes**:

- Unitários: `Add2Engine` (todos os cenários de entrada, backspace, zeros, 00)
- Unitários: `ExpressionEvaluator` (operações, precedência, %, erros)
- Unitários: `NumberFormatter` (ponto, vírgula, milhar)
- Unitários: `CalculatorViewModel` (estado inicial, inputDigit, operações, =, C, ⌫, timeline, load more na timeline, persistência)

**Entregável**: Toda a lógica da calculadora funcional e testada, sem nenhuma dependência de UI.

---

## Etapa 4 — Lógica do Histórico e Configurações

**Objetivo**: Implementar os ViewModels e repositórios restantes — toda a lógica de histórico e configurações, sem nenhuma UI.

**Escopo**:

- **HistoryViewModel**:
  - Carrega lista de histórico do repository **paginada** (ex: 20 por página)
  - Método `loadMore()` para carregar próxima página
  - Controle de `hasMore` para saber se há mais páginas
  - Deleta entrada individual
  - Limpa todo o histórico com reset de paginação
  - Renomear entrada (`updateName`)
  - Favoritar/desfavoritar entrada (`toggleFavorite`)
  - Filtro: todos / apenas favoritos
  - Notifica listeners sobre mudanças
- **SettingsRepository**: Interface + implementação com SharedPreferences
  - Salvar/carregar: ThemeMode, seedColor, decimalSeparator, locale
- **SettingsViewModel**:
  - Gerencia estado das preferências
  - Notifica listeners sobre mudanças
  - Persiste alterações via repository
- Registrar SettingsRepository e ViewModels no GetIt

**Testes**:

- Unitários: `HistoryViewModel` (carregamento paginado, loadMore, hasMore, deleção, limpeza, rename, toggleFavorite, filtro favoritos, notificações)
- Unitários: `SettingsRepository` (CRUD de preferências)
- Unitários: `SettingsViewModel` (estado inicial, alteração de preferências, persistência)

**Entregável**: Toda a lógica de negócio do app completa e testada. A partir daqui, só resta a UI.

---

## Etapa 5 — UI da Calculadora

**Objetivo**: Construir a interface da tela principal — timeline, keypad e botões com animações e design One UI.

**Escopo**:

- **CalculatorButton**: Botão circular com `AnimatedContainer` para feedback de toque
  - Variantes: numérico (neutro), operador (cor de acento), ação (C, ⌫, =)
- **CalculatorKeypad**: Grid de botões (5 linhas × 4 colunas)
  - Layout: C, %, ⌫, ÷ | 7, 8, 9, × | 4, 5, 6, − | 1, 2, 3, + | 000, 00, 0, =
- **TimelineDisplay**: Widget scrollável mostrando histórico da sessão
  - Exibe apenas as últimas N linhas por padrão
  - Botão "load more" no topo para carregar cálculos anteriores da sessão
  - Linhas anteriores (cor secundária/sutil)
  - Linha atual (branco) — expressão sendo digitada
  - Última linha (cinza) — prévia do resultado
  - Auto-scroll ao adicionar nova linha
  - **AnimatedSwitcher** no display de valores
- **CalculatorPage**: Scaffold principal com layout vertical (timeline + barra de ícones + keypad)
- **Barra de ícones**: ⏱ (histórico) e ⚙ (configurações) — navegação ainda sem destino funcional
- Todas as strings via `context.l10n`
- Todos os valores de layout via `AppLayout`

**Testes**:

- Widget: `CalculatorButton` responde a toque e exibe variantes
- Widget: `CalculatorKeypad` exibe todos os botões
- Widget: `TimelineDisplay` exibe linhas, faz scroll e exibe "load more"
- Widget: `CalculatorPage` renderiza corretamente
- Widget: Integração teclado → display (digitar e ver resultado)

**Entregável**: Tela da calculadora funcional com design One UI, animações suaves e testes de widget passando.

---

## Etapa 6 — Exibição literal da porcentagem

**Objetivo**: Alterar a forma como a porcentagem é exibida sem alterar o resultado matemático. O `%` passa a aparecer literalmente na expressão (e na timeline), enquanto a prévia e o resultado final continuam refletindo o cálculo já existente.

**Escopo**:

- **CalculatorViewModel**:
  - A expressão exibida (`expression`) preserva o token `%` junto ao número (ex: `1000.00 + 10.00%`)
  - A prévia (`previewResult`) continua resolvendo o `%` normalmente (ex: `1100.00`)
  - O resultado final ao pressionar `=` mantém o comportamento atual (cálculo correto)
  - Garantir que a entrada `Add2` continue funcionando após o `%` (ex: começar novo número/operador depois)
  - O `%` aplicado pela ação dedicada (`applyPercentage`) deve produzir o token literal na expressão, não substituir o número
- **ExpressionEvaluator**:
  - Continuar avaliando `%` com o comportamento contextual já existente
  - Garantir que a expressão com `%` literal seja parseável tanto para a prévia quanto para o cálculo final
- **TimelineDisplay**:
  - Linhas anteriores e atual exibem o `%` literal
  - Prévia (linha em cinza) exibe apenas o resultado numérico
- **Histórico**: A entrada persistida deve guardar a expressão literal com `%`, mantendo compatibilidade com o carregamento de sessão

**Testes**:

- Unitários: `CalculatorViewModel` — `expression` mantém `%` literal, `previewResult` calcula corretamente, `=` produz o mesmo resultado de antes
- Unitários: `ExpressionEvaluator` — parsing de expressões com `%` literal em diferentes contextos (`+`, `−`, `×`, `÷`)
- Widget: `TimelineDisplay` exibe `%` literal na expressão e resultado calculado na prévia
- Regressão: nenhum teste existente da Etapa 3/5 deve quebrar

**Entregável**: Porcentagem exibida literalmente na expressão e timeline, com prévia e resultado matematicamente corretos.

---

## Etapa 7 — Fila de processamento de toques (anti-perda em digitação rápida)

**Objetivo**: Garantir que **todo** toque em qualquer botão da calculadora seja processado em ordem, mesmo durante animações ou rebuilds reativos. Eliminar perda de toques ao digitar muito rápido.

**Escopo**:

- **Diagnóstico**:
  - Auditar o pipeline de toque do `CalculatorButton` → `CalculatorKeypad` → `CalculatorViewModel`
  - Identificar pontos onde `setState`/`AnimatedContainer`/`AnimationController` podem descartar gestos (ex: `GestureDetector` reconstruído, `IgnorePointer` durante animação)
- **Solução — Queue de eventos**:
  - Criar uma fila (`Queue<CalculatorAction>`) no `CalculatorViewModel` (ou em um `InputDispatcher` dedicado registrado no GetIt)
  - Cada toque é enfileirado imediatamente (sem await) e processado sequencialmente em um loop assíncrono (microtask)
  - O processamento atualiza estado e dispara animações; nenhum toque é descartado por estar "em animação"
  - Garantir thread-safety lógica (Dart é single-threaded, mas evitar reentrância)
- **CalculatorButton**:
  - Usar `Listener` ou `GestureDetector` com `behavior: HitTestBehavior.opaque`
  - O callback de toque despacha imediatamente a ação para a fila — não aguarda animação
  - Animações de feedback (flash, glow LED) são puramente visuais e independentes do despacho
- **Métrica/Validação**:
  - Teste de stress: simular N toques em rajada e verificar que todos foram processados na ordem correta
  - Sem `debounce`/`throttle` que descarte eventos

**Testes**:

- Unitários: `CalculatorViewModel` — enfileirar 50 ações em rajada e validar a ordem e o estado final
- Widget: `CalculatorKeypad` — `tester.tap` em rajada (sem `pumpAndSettle` entre toques) reflete todos os dígitos
- Widget: `CalculatorButton` permanece responsivo durante a animação de feedback (toque novo durante glow ainda é registrado)
- Regressão: testes da Etapa 5 continuam verdes

**Entregável**: Digitação rápida nunca perde toques; toda ação é processada em ordem, animações continuam fluidas.

---

## Etapa 8 — Reorganização do keypad: delete contextual e parênteses

**Objetivo**: Reorganizar a primeira linha do keypad: mover ⚙ (configurações) para junto de ⏱ (histórico), substituir o slot antigo do ⚙ por um botão de **apagar tudo** (com cor contextual), e substituir o backspace (⌫) por um botão de **parênteses `( )`** com abertura/fechamento automáticos.

**Escopo**:

- **Barra de ícones (acima do keypad)**:
  - Agora contém ⏱ (histórico) e ⚙ (configurações), lado a lado
- **Keypad — Botão Apagar (`C`)**:
  - Ocupa o slot onde estava ⚙
  - Apaga toda a expressão e a entrada atual (clear total)
  - **Cor contextual**:
    - Sem nada para apagar (expressão vazia e entrada zerada): cor padrão dos ícones de ação
    - Com qualquer conteúdo: cor `primary` (mesma cor da fonte dos operadores)
  - Transição animada de cor (`AnimatedDefaultTextStyle` ou `AnimatedSwitcher`) — sem mudança "seca"
- **Keypad — Botão Parênteses `()`**:
  - Ocupa o slot onde estava `⌫`
  - Comportamento inteligente (toggle automático):
    - Se não há parêntese aberto pendente → insere `(`
    - Se há parêntese aberto pendente E o último token permite fechamento (número, `%`, `)`) → insere `)`
    - Caso contrário (após operador), insere novo `(`
  - Permite expressões aninhadas: `(10.00 × 50.00) + 30.00 + (48.00 ÷ (18.00 × 1.50%))`
- **CalculatorViewModel**:
  - Novo método `inputParenthesis()` com a lógica de toggle
  - Estado derivado `hasContent` (bool) para colorir o botão `C`
  - Contador de parênteses abertos (`openParenCount`) para guiar o toggle
  - Validação ao confirmar (`=`): se houver parênteses não fechados, fechar automaticamente antes de avaliar (ou bloquear com feedback — definir na implementação)
- **ExpressionEvaluator**:
  - Suporte completo a parênteses com aninhamento ilimitado, respeitando precedência
  - Tratamento de erros: parênteses desbalanceados, parênteses vazios `()`
- **NumberFormatter / TimelineDisplay**:
  - Renderização correta dos parênteses na expressão e no histórico
- **Acessibilidade / l10n**:
  - Labels via `context.l10n.*` para os novos botões (`clearAll`, `parenthesis`)

**Testes**:

- Unitários: `ExpressionEvaluator` — expressões com parênteses simples, aninhados, com `%`, com erro de balanceamento
- Unitários: `CalculatorViewModel` — `inputParenthesis` em diferentes estados, contador de abertos, `hasContent` reativo, `clearAll`
- Widget: `CalculatorKeypad` — novo layout (⚙ removido do keypad, `C` no lugar, `( )` no lugar do `⌫`)
- Widget: Botão `C` muda de cor conforme `hasContent` (com animação)
- Widget: Botão `( )` insere `(` ou `)` conforme contexto
- Widget: Barra de ícones contém ⏱ e ⚙ lado a lado
- Regressão: testes anteriores continuam verdes

**Entregável**: Keypad reorganizado com botão de apagar contextual e parênteses funcionais (incluindo aninhamento), barra de ícones com ⏱ + ⚙.

---

## Etapa 9 — UI do Histórico e Configurações

**Objetivo**: Construir as telas de histórico e configurações, conectar toda a navegação e integrar com a calculadora.

**Escopo**:

- **HistoryPage**: Tela com lista de sessões salvas
  - Lista **paginada** em ordem cronológica inversa (mais recente primeiro)
  - Botão/indicador "load more" no final da lista para carregar mais entradas
  - Cada item mostra: nome (se houver), expressão (truncada se muito longa), resultado e data/hora
  - Ícone de favorito (★) em cada item — toque para alternar
  - Filtro: Todos / Favoritos (tabs ou toggle)
  - Toque longo ou menu: renomear entrada (campo de texto para dar nome)
  - Expressões longas exibidas em formato compacto (truncadas com "..." expandível)
  - Animação de entrada para cada item da lista
  - Botão/ação para limpar histórico com diálogo de confirmação
- **Integração Timeline ↔ Histórico**:
  - Ao tocar em uma entrada, a timeline carrega aquela sessão
  - Navegação de volta à calculadora com contexto carregado
- **SettingsPage**:
  - Seção **Tema**: Toggle claro/escuro/sistema + 9 círculos de cor com prévia visual
  - Seção **Formato de número**: Toggle ponto/vírgula
  - Seção **Idioma**: Seletor de idioma
  - Toda mudança reflete imediatamente com animação suave
- **Integração com o App**:
  - `main.dart` carrega preferências antes de iniciar
  - Tema, separador e idioma se propagam para toda a aplicação
  - Troca de tema animada globalmente
- Conectar navegação completa: ⏱ → HistoryPage, ⚙ → SettingsPage
- Atualizar ARBs com strings do histórico e configurações (incluindo favoritos, renomear, load more, etc.)

**Testes**:

- Widget: `HistoryPage` renderiza lista paginada
- Widget: Load more carrega mais entradas
- Widget: Toque em item navega/carrega na timeline
- Widget: Favoritar/desfavoritar atualiza ícone
- Widget: Filtro favoritos mostra apenas favoritos
- Widget: Renomear entrada atualiza nome exibido
- Widget: Confirmação antes de limpar histórico
- Widget: Expressão longa truncada corretamente
- Widget: `SettingsPage` renderiza todas as seções
- Widget: Seleção de cor atualiza tema
- Widget: Toggle de separador atualiza formato

**Entregável**: Todas as telas implementadas, navegação completa e funcional.

---

## Etapa 10 — Copiar e Colar

**Objetivo**: Implementar suporte a copiar e colar no display da calculadora via menu de contexto ativado por toque longo.

**Escopo**:

- **Menu de contexto (toque longo no display)**:
  - Toque longo sobre o display abre um menu de contexto com animação suave
  - Opções exibidas condicionalmente conforme o estado da calculadora:
    - **Copiar cálculo** — visível quando há expressão na entrada atual ou na timeline
    - **Copiar resultado** — visível quando há um resultado/prévia calculado
    - **Copiar histórico** — visível quando há entradas na timeline da sessão
    - **Colar** — sempre visível; desabilitado se a área de transferência estiver vazia ou inválida

- **Copiar cálculo**: copia a expressão atual (ex: `1000.00 + 10.00%`) para a área de transferência
- **Copiar resultado**: copia o resultado ou a prévia atual (ex: `1100.00`) para a área de transferência
- **Copiar histórico**: copia todas as entradas da timeline da sessão formatadas como texto

- **Colar**:
  - Lê o conteúdo da área de transferência
  - Valida se é um número ou expressão matemática válida (inteiros, decimais com ponto ou vírgula, operadores básicos)
  - Se válido: insere na calculadora convertendo inteiros automaticamente para Add2 (ex: `1250` → `12.50`, `12.5` → `12.50`)
  - Se inválido: exibe snackbar com mensagem de erro via `context.l10n.*`

- **`ClipboardService`** (`lib/data/services/clipboard_service.dart`):
  - Interface + implementação que encapsulam o `Clipboard` do Flutter
  - Permite mock nos testes sem dependência direta do widget
  - Registrada no GetIt

- **Validação de entrada colada** (lógica em `CalculatorViewModel`):
  - Suporte a: inteiros (`1250`), decimais com ponto (`12.50`), decimais com vírgula (`12,50`)
  - Suporte a expressões simples (`10 + 5`, `100 × 3`, `1.000,00 + 50`)
  - Normalização: separadores de milhar ignorados, vírgula convertida para ponto antes de processar
  - Números inteiros colados: convertidos via Add2 (sem ponto → 2 casas decimais automáticas)
  - Números com casas decimais: inseridos diretamente com as casas preservadas

**Testes**:

- Unitários: `CalculatorViewModel` — colar número inteiro (conversão Add2), colar decimal com ponto, colar decimal com vírgula, colar expressão válida, colar texto inválido (gera erro), colar quando display está vazio
- Unitários: lógica de validação e normalização da entrada colada
- Widget: toque longo no display abre o menu de contexto
- Widget: opções visíveis e ocultas conforme estado (sem expressão, sem resultado, com/sem histórico)
- Widget: "Copiar cálculo" copia a expressão correta para o clipboard
- Widget: "Copiar resultado" copia o resultado correto
- Widget: "Colar" com dado válido atualiza o display
- Widget: "Colar" com dado inválido exibe snackbar de erro

**Entregável**: Fluxo completo de copiar e colar no display da calculadora com menu de contexto animado, validação de entrada e feedback visual de erro.

---

## Etapa 11 — Cursor Editável no Display

**Objetivo**: Implementar um cursor navegável no display da calculadora, permitindo ao usuário mover a posição de inserção e editar valores em qualquer ponto da expressão.

**Motivação**: Atualmente a entrada só acontece no final da expressão. Com um cursor editável, o usuário pode corrigir erros no meio do cálculo sem precisar apagar tudo.

**Escopo**:

- **Modelo de posição do cursor**:
  - `cursorPosition` (int) no CalculatorViewModel indicando o índice de inserção na expressão
  - Mover cursor para esquerda/direita (botões ou gesto de toque)
  - Toque direto em um caractere do display posiciona o cursor naquele ponto
  - Cursor sempre entre caracteres (não sobrepõe)

- **Visual do cursor**:
  - Barra vertical piscante (blinking) na posição atual, usando Timer (não AnimationController) para não bloquear `pumpAndSettle`
  - Altura proporcional ao fontSize animado atual
  - Cor: `colorScheme.primary`
  - Animação suave ao mover de posição (slide horizontal com `TweenAnimationBuilder`)

- **Integração com AnimatedInputDisplay**:
  - Novo prop `cursorPosition` (int?) — se null, sem cursor visível
  - Novo prop `cursorColor` (Color)
  - O cursor é inserido entre os widgets de caractere na posição indicada
  - GestureDetector em cada caractere para detectar toque e callback `onCharTap(int index)`

- **Integração com CalculatorViewModel**:
  - `inputDigit()` insere na `cursorPosition` em vez de sempre no final
  - `deleteLastDigit()` (backspace) apaga o caractere antes do cursor
  - `selectOperator()` insere operador na posição do cursor
  - Após inserção/deleção, cursor avança/recua automaticamente
  - `moveCursorLeft()` e `moveCursorRight()` com bounds checking

- **UX no keypad**:
  - Dois novos botões (◀ ▶) ou gesto de swipe horizontal no display para mover o cursor
  - Alternativa: long-press no display ativa modo de edição com cursor

- **Testes**:
  - Unitários: ViewModel com cursorPosition (inserção no meio, backspace no meio, mover cursor, bounds)
  - Widget: AnimatedInputDisplay com cursor visível na posição correta
  - Widget: Toque em caractere posiciona cursor
  - Widget: Integração keypad → edição no meio da expressão

**Entregável**: Cursor editável funcional no display, permitindo navegar e editar a expressão em qualquer ponto.

---

## Etapa 12 — Logo customizado e identidade visual

**Objetivo**: Substituir os ícones e splash padrão do Flutter por uma identidade visual própria do Decima, em todas as plataformas já configuradas no projeto. O logo deve refletir o estilo premium/One UI do app (escuro, com acento dourado/amarelo).

**Escopo**:

- **Arte do logo**:
  - Importar logo em PNG em `assets/branding/logo.png`
  - Variantes por densidade em `assets/branding/2.0x/logo.png` e `assets/branding/3.0x/logo.png` (resolução nativa do Flutter)
  - Versão monocromática adicional para uso em splash/contextos de uma cor
  - Versão adaptativa Android (foreground + background) seguindo as guidelines do Material You
- **Geração de ícones**:
  - Adicionar `flutter_launcher_icons` em `dev_dependencies`
  - Configurar `flutter_launcher_icons.yaml` para gerar ícones de Android, iOS, web, Windows, Linux e macOS a partir das fontes
  - Rodar a geração e versionar os artefatos resultantes
- **Splash screen**:
  - Adicionar `flutter_native_splash` em `dev_dependencies`
  - Configurar splash com fundo do app (`AppColors.darkBackground` / `lightBackground`) e logo centralizado
  - Suportar Android 12+ splash API
  - Gerar splash para todas as plataformas configuradas
- **Logo dentro do app**:
  - Criar widget `AppLogo` em `lib/ui/core/widgets/app_logo.dart` para uso em telas internas (ex: cabeçalho de Configurações ou diálogo "Sobre")
  - Aceita `size` e `monochrome` como parâmetros
  - Usa `Image.asset` apontando para o PNG (Flutter escolhe a densidade automática conforme o `devicePixelRatio`)
- **Limpeza**:
  - Remover qualquer referência ao ícone/splash padrão do Flutter
  - Atualizar `pubspec.yaml` declarando os assets de branding

**Testes**:

- Widget: `AppLogo` renderiza com o tamanho correto
- Widget: `AppLogo` em modo monocromático aplica a cor do tema
- Verificação manual: ícone do app aparece corretamente no launcher de cada plataforma
- Verificação manual: splash screen aparece com a arte correta

**Entregável**: Decima com identidade visual própria (ícones e splash) em todas as plataformas, sem traços do template padrão do Flutter.

---

## Etapa 13 — Suporte a teclado físico

**Objetivo**: Permitir operar a calculadora inteiramente via teclado físico (essencial para uso em desktop e produtividade em mobile com teclado externo). Cada toque virtual passa a ter um equivalente em tecla física, despachado pelo mesmo pipeline (fila de toques da Etapa 7).

**Escopo**:

- **Mapeamento de teclas**:
  - Dígitos `0`–`9` → `inputDigit`
  - `+`, `-`, `*` (ou `x`/`X`), `/` → operadores (`+`, `−`, `×`, `÷`)
  - `Enter` ou `=` → `equals`
  - `Backspace` → backspace contextual (a Etapa 8 já garante o comportamento de delete)
  - `Esc` ou `Delete` → `clearAll` (botão `C`)
  - `%` → `applyPercentage`
  - `(` e `)` → `inputParenthesis` (toggle inteligente da Etapa 8)
  - `,` e `.` → atalho para `00` (Add2 não usa ponto literal — decidir entre ignorar e mapear para `00`; documentar a escolha)
  - `←` / `→` → `moveCursorLeft` / `moveCursorRight` (depende da Etapa 11)
  - `Ctrl/Cmd+C` → copiar resultado (Etapa 10)
  - `Ctrl/Cmd+V` → colar (Etapa 10)
- **Implementação**:
  - Criar `KeyboardShortcutsHandler` em `lib/ui/calculator/widgets/keyboard_shortcuts_handler.dart`
  - Usar `Focus` + `Shortcuts` + `Actions` (idiomático Flutter) ou `RawKeyboardListener` para capturar eventos físicos
  - Cada `Intent` mapeia para um método do `CalculatorViewModel` — passa pela mesma fila de toques, garantindo ordem e ausência de perda
  - Feedback visual idêntico ao toque (glow LED + flash) — reaproveitar `CalculatorButton` expondo um método `triggerFeedback()` ou notificar via `ValueNotifier` por tecla
- **Foco**:
  - `CalculatorPage` envolve a árvore com `Focus(autofocus: true)` para receber eventos sem cliques prévios
  - Garantir que campos de texto (rename do histórico, busca futura) não interceptem indevidamente as teclas
- **Acessibilidade**:
  - Documentar atalhos disponíveis em `docs/features/calculadora.md`
  - Considerar uma seção "Atalhos" futura nas Configurações (não obrigatória nesta etapa)

**Testes**:

- Unitários: mapeamento de `LogicalKeyboardKey` → ação do ViewModel
- Widget: `tester.sendKeyEvent` para cada tecla mapeada produz o estado esperado
- Widget: `Backspace` em estado vazio não quebra o app
- Widget: combinações `Ctrl+C` / `Ctrl+V` disparam copiar/colar
- Widget: feedback visual (glow) aparece ao acionar via teclado
- Regressão: testes anteriores continuam verdes; toques no teclado virtual não são afetados

**Entregável**: Calculadora totalmente operável via teclado físico, com feedback visual equivalente ao toque e sem perda de eventos.

---

## Etapa 14 — Suporte a Windows (com infra de desktop e title bar customizada)

**Objetivo**: Habilitar o build para Windows e estabelecer a **infraestrutura de desktop compartilhada** (janela de tamanho fixo não-redimensionável + title bar customizada do app, sem a barra padrão do sistema). Esta etapa entrega o código reutilizado pelas etapas seguintes (Linux, macOS).

**Escopo**:

- **Habilitação da plataforma**:
  - Rodar `flutter create --platforms=windows .` para gerar o runner nativo
  - Atualizar `pubspec.yaml` com a seção de plataformas se necessário
- **Infra de desktop compartilhada** (`lib/ui/core/desktop/`):
  - Adicionar `window_manager` em `dependencies`
  - `DesktopWindowConfig` — constantes de tamanho fixo (ex: 360 × 720, alinhado à proporção do mobile) e nome do app
  - `DesktopWindowInitializer` — função `Future<void> initDesktopWindow()` chamada no `main` antes de `runApp`:
    - `windowManager.ensureInitialized()`
    - `WindowOptions` com `size`, `minimumSize`, `maximumSize` (todos iguais), `center: true`, `titleBarStyle: TitleBarStyle.hidden`, `title`
    - `windowManager.setResizable(false)`
  - `AppTitleBar` — widget reutilizável (`lib/ui/core/widgets/app_title_bar.dart`):
    - Área arrastável (`DragToMoveArea` do `window_manager`)
    - Logo + nome do app à esquerda
    - Botões de minimizar / fechar à direita (sem maximizar — janela é fixa)
    - Cores integradas ao `ColorScheme` atual (segue tema claro/escuro)
    - Animações suaves no hover dos botões
  - `DesktopShell` — wrapper que adiciona `AppTitleBar` acima do conteúdo apenas quando `Platform.isWindows || Platform.isLinux || Platform.isMacOS`
  - `main.dart` chama `initDesktopWindow()` em desktop antes do `runApp` e envolve a `MaterialApp` com `DesktopShell`
- **Específico do Windows**:
  - Validar que o build `flutter build windows` gera o `.exe` corretamente
  - Conferir ícone do app (gerado na Etapa 12) integrado ao executável
  - Ajustar `windows/runner/Runner.rc` se necessário para metadados (nome, versão, descrição)
- **Limitações conhecidas**:
  - Sem suporte a maximizar (por design — tamanho fixo)
  - Snap do Windows desabilitado (decorrência do tamanho fixo)

**Testes**:

- Widget: `AppTitleBar` renderiza logo, nome e botões
- Widget: `AppTitleBar` botão fechar dispara callback
- Widget: `DesktopShell` envolve filho com title bar em desktop
- Verificação manual: app abre em janela de tamanho fixo, sem barra do sistema, draggable pela title bar customizada
- `flutter build windows` — sucesso

**Entregável**: Decima rodando no Windows com janela fixa, title bar própria do app e infra reutilizável para Linux/macOS.

---

## Etapa 14.1 — Instalador Windows (.exe)

**Objetivo**: Empacotar o build Release do Windows em um instalador `.exe` distribuível, permitindo instalar o Decima na máquina para uso diário e publicar o artefato no GitHub Releases. Originalmente o empacotamento estava fora de escopo (apenas documentado) — antecipado por necessidade de dogfooding.

**Escopo**:

- **Ferramenta**: Inno Setup 6.3+ (`ISCC.exe`), escolhido sobre MSIX por não exigir certificado instalado pelo usuário final para sideload
- **Script do instalador** (`tool/installer/decima.iss`):
  - `AppId` fixo (GUID) para que novas versões atualizem in-place
  - Instalação **por usuário** (`PrivilegesRequired=lowest`) → `%LOCALAPPDATA%\Programs\Decima`, sem prompt de UAC
  - Wizard mínimo (sem Welcome/Ready/Group), pt-BR + inglês conforme locale do sistema
  - Atalho no Menu Iniciar sempre; atalho de desktop como tarefa opcional
  - `CloseApplications=yes` — fecha o app aberto antes de sobrescrever binários
  - Dados do usuário (`%APPDATA%\Wevasoft\Decima`) preservados na desinstalação
- **Script de build** (`tool/installer/build_installer.sh`):
  - Orquestra a bridge WSL→Windows: `rsync` → `flutter clean` → `flutter build windows --release` → runtime C++ → `ISCC.exe` → `dist/`
  - Versão extraída do `pubspec.yaml` e injetada via `/DAppVersion`
  - Flags `--no-clean` e `--skip-build` para iteração
  - Configuração de máquina em `local.env` (não versionado), com `local.env.example` versionado
- **Runtime C++ app-local**: DLLs do redist MSVC copiadas para junto do `decima.exe`, eliminando o pré-requisito "Visual C++ Redistributable"
- **Documentação**: `docs/fundacao/empacotamento-windows.md` + seção de instalação no `README.md` (incluindo o aviso de SmartScreen)

**Fora de escopo (documentado)**:

- Assinatura de código (certificado OV exige token HSM pago) — SmartScreen exibirá aviso
- Auto-update — sem mecanismo; atualização é reinstalar por cima
- Publicação em winget / Microsoft Store

**Testes**:

- Verificação manual: instalar, abrir pelo Menu Iniciar, operar o app, desinstalar
- Verificação manual: reinstalar por cima preserva o histórico em `%APPDATA%`

**Entregável**: `dist/decima-<versão>-windows-x64-setup.exe` funcional, reprodutível por um comando, e Decima instalado na máquina de desenvolvimento para uso diário.

---

## Etapa 14.2 — Persistência ao fechar e memória da janela

**Objetivo**: Corrigir dois atritos identificados no **uso diário do Decima instalado no Windows**: (1) fechar pelo `X` descarta o cálculo em andamento — hoje só `=` e `C` persistem no histórico; (2) a janela sempre reabre centralizada, ignorando onde o usuário a deixou.

**Escopo**:

- **A — Flush da sessão ao fechar** (multiplataforma):
  - Estado atual: `CalculatorViewModel._saveOrUpdateSession()` é chamado apenas em `equals()`, `clear()` e `loadSession()`, e é **fire-and-forget** (o `Future` do repositório não é aguardado). Uma expressão digitada e nunca avaliada não existe em `_sessionLines` — não há o que gravar; e mesmo o `=` recém-pressionado pode ter a escrita interrompida pelo encerramento do processo
  - Novo `Future<void> flushSession()` público no `CalculatorViewModel`:
    - Avalia a expressão pendente quando ela é avaliável (contém ao menos um operador), auto-fechando parênteses — mesmo caminho do `equals()`, extraído para um helper compartilhado
    - Número digitado sem operador **não** vira entrada de histórico (não há cálculo) — regra documentada
    - Aguarda de fato a escrita: `_saveOrUpdateSession()` passa a devolver `Future<void>` e o `add` em voo (`_addInFlight`) é aguardado antes de retornar
    - Idempotente — chamadas repetidas não duplicam linhas nem criam sessões novas
  - **Desktop**: interceptar o fechamento com `windowManager.setPreventClose(true)` + `WindowListener.onWindowClose` → `flushSession()` → `windowManager.destroy()`. Cobre o `X` da `AppTitleBar`, `Alt+F4` e "Fechar janela" pela barra de tarefas
  - **Mobile**: `AppLifecycleListener` (`onExitRequested` / `onHide` / `onPause`) no shell do app — o Android encerra o processo sem garantir `detached`, então o flush precisa acontecer já no `paused`/`hidden`
  - Risco a mitigar: `setPreventClose(true)` sem um `destroy()` garantido deixa o app impossível de fechar — o `destroy()` fica em `finally`, com timeout no flush
- **B — Memória da posição da janela** (desktop):
  - `SettingsRepository` ganha `getWindowPosition()` / `setWindowPosition(x, y)` sobre `SharedPreferences` (chaves `window_x` / `window_y`), trafegando `double` — nada de `Offset`, para manter repositórios e ViewModels livres de import do Flutter
  - `initDesktopWindow()` lê a posição salva: `center: true` só quando não há posição válida; caso contrário `setPosition` **antes** do `show()`, para não piscar no centro
  - Validação contra os monitores atuais via `screen_retriever` (já presente como dependência transitiva do `window_manager`; declarar em `dependencies` se importado direto): posição fora de qualquer display — monitor desconectado, mudança de resolução ou de DPI — cai no centro. A regra fica em uma **função pura** testável sem plugin
  - Gravação no fechamento, junto do flush da sessão (menos I/O que salvar a cada `onWindowMoved`); `onWindowMoved` com debounce fica documentado como alternativa caso encerramentos anormais se mostrem comuns
- **Fora de escopo**: memória de tamanho da janela (o tamanho é fixo por design) e memória de qual monitor por índice (a validação por coordenada já resolve o caso comum)

**Testes**:

- Unit: `flushSession()` com expressão pendente avaliável, com número solto, com sessão já persistida (idempotência) e com escrita em voo
- Unit: `SettingsRepository` — salvar/ler posição, ausência devolve `null`
- Unit: função pura de validação de posição contra uma lista de displays (dentro, fora, parcialmente visível)
- Widget: handler de fechamento chama o flush antes de destruir a janela
- Verificação manual: digitar sem `=` → fechar pelo `X` → reabrir e conferir o histórico; mover a janela → fechar → reabrir no mesmo lugar; desconectar o monitor secundário → volta ao centro

**Entregável**: nenhum cálculo perdido ao fechar o app, em qualquer plataforma, e janela desktop que reabre onde o usuário a deixou.

---

## Etapa 15 — Suporte a Linux

**Objetivo**: Habilitar o build para Linux reutilizando a infra de desktop da Etapa 14. Validar a title bar customizada e o tamanho fixo no ambiente Linux (GTK).

**Escopo**:

- **Habilitação da plataforma**:
  - Rodar `flutter create --platforms=linux .` para gerar o runner GTK
  - Garantir que `window_manager` funciona corretamente no Linux (depende do compositor)
- **Ajustes específicos**:
  - Validar `TitleBarStyle.hidden` no GTK — alguns compositores Wayland exigem configuração adicional
  - Conferir cursor de drag e botões de janela funcionais
  - Verificar integração do ícone do app no `.desktop` (criar se necessário em `linux/`)
- **Empacotamento (opcional, documentado)**:
  - Documentar como gerar AppImage ou pacote Flatpak/Snap (sem implementar, apenas referência)
- **Reutilização**:
  - Nenhum código novo na pasta `lib/` — apenas configuração nativa em `linux/`
  - `DesktopShell` e `AppTitleBar` da Etapa 14 funcionam sem alterações

**Testes**:

- Verificação manual: app abre em janela fixa no Linux com title bar customizada
- Verificação manual: drag, minimizar e fechar funcionam
- `flutter build linux` — sucesso
- Regressão: testes existentes continuam verdes

**Entregável**: Decima rodando no Linux com a mesma experiência do Windows.

---

## Etapa 16 — Suporte a macOS

**Objetivo**: Habilitar o build para macOS reutilizando a infra de desktop da Etapa 14, com adaptações para o sistema (semáforo de botões, entitlements e assinatura).

**Escopo**:

- **Habilitação da plataforma**:
  - Rodar `flutter create --platforms=macos .` para gerar o runner Cocoa
- **Ajustes específicos**:
  - `TitleBarStyle.hidden` no macOS preserva os botões do semáforo (close/minimize/maximize) — esconder o de maximizar via `windowManager.setMaximizable(false)` ou `setWindowButtonVisibility`
  - Decisão de UX: manter os botões nativos do semáforo OU substituí-los pelos botões customizados do `AppTitleBar` (recomendado: manter o semáforo nativo no macOS por convenção da plataforma; `AppTitleBar` exibe apenas logo + nome, sem botões à direita quando em macOS)
  - `DesktopShell` ganha a flag `Platform.isMacOS` para ajustar o `AppTitleBar` conforme acima
  - Configurar entitlements em `macos/Runner/*.entitlements` se necessário
  - Conferir ícone `.icns` (gerado na Etapa 12)
- **Empacotamento (documentado)**:
  - Documentar processo básico de assinatura/notarização para distribuição (sem implementar, apenas referência)

**Testes**:

- Widget: `AppTitleBar` em macOS oculta botões customizados de minimizar/fechar
- Verificação manual: app abre em janela fixa no macOS com semáforo nativo, sem botão verde de maximizar
- `flutter build macos` — sucesso
- Regressão: testes existentes continuam verdes

**Entregável**: Decima rodando no macOS respeitando convenções da plataforma, com janela fixa.

---

## Etapa 17 — Suporte a iOS

**Objetivo**: Habilitar o build para iOS. Como é uma plataforma mobile, **não há title bar customizada nem janela fixa** — o app segue o comportamento padrão fullscreen do iOS, apenas garantindo paridade visual com Android.

**Escopo**:

- **Habilitação da plataforma**:
  - Rodar `flutter create --platforms=ios .` para gerar o runner
  - Configurar `ios/Runner/Info.plist`: nome do app, orientações suportadas (apenas portrait, alinhado ao Android), status bar style
- **Identidade visual**:
  - Confirmar que ícones e splash gerados na Etapa 12 cobrem iOS
  - Configurar `LaunchScreen.storyboard` para integrar com o splash gerado (`flutter_native_splash` cuida na maioria dos casos)
- **Ajustes específicos**:
  - Garantir que `sqflite` e `shared_preferences` funcionam no iOS (pacotes já suportam)
  - Conferir teclado físico (Etapa 13) em iPad com Magic Keyboard / Smart Keyboard
  - Conferir comportamento de safe area (notch / Dynamic Island)
  - Validar haptic feedback (opcional) coerente com Android
- **Limitações**:
  - Sem suporte oficial a iPadOS multitasking com janela fixa nesta etapa (fora de escopo)

**Testes**:

- Verificação manual: app roda no simulador iOS com layout idêntico ao Android
- Verificação manual: splash e ícone corretos no iOS
- Verificação manual: teclado físico funciona em iPad
- `flutter build ios --no-codesign` — sucesso (build sem assinatura para validar compilação)
- Regressão: testes existentes continuam verdes

**Entregável**: Decima rodando no iOS com paridade visual e funcional em relação ao Android.

---

## Etapa 18 — Polimento, Integração e Revisão Final

**Objetivo**: Refinamento de animações, transições entre telas, revisão geral de qualidade e documentação — cobrindo inclusive os fluxos introduzidos pelas etapas de Copiar/Colar (10), Cursor Editável (11), Logo (12), Teclado Físico (13) e suporte multi-plataforma (14–17).

**Escopo**:

- **Animações**:
  - Revisar e refinar todas as animações (curvas, durações), incluindo:
    - Abertura/fechamento do menu de contexto de copiar/colar
    - Slide horizontal e blink do cursor editável
    - Hover e press dos botões da `AppTitleBar` em desktop
  - Transição animada entre telas (Hero, page transitions)
  - Animação de troca de tema global suave
- **Integração Final**:
  - Fluxo completo: calculadora → histórico → carregar sessão → continuar cálculo
  - Fluxo completo: configurações → mudar tema/separador → reflexo imediato na calculadora
  - Verificar que preferências persistem ao fechar e reabrir
  - Fluxo: sessão longa na timeline → load more carrega cálculos anteriores
  - Fluxo: histórico paginado → load more → favoritar → filtrar → renomear
  - Fluxo: copiar cálculo/resultado/histórico → colar em outro app e de volta na calculadora
  - Fluxo: colar valor inválido → snackbar de erro com texto via `context.l10n.*`
  - Fluxo: navegar com cursor editável → inserir/apagar no meio da expressão → confirmar com `=`
  - Verificar interação entre cursor editável, parênteses inteligentes e porcentagem literal
  - Fluxo: operação completa via teclado físico em desktop e mobile com teclado externo
  - Verificar que o logo e o splash aparecem corretamente em todas as plataformas
  - Verificar paridade visual entre Android, iOS, Windows, Linux e macOS
- **Qualidade**:
  - `flutter analyze` — zero warnings
  - `flutter test` — 100% verde
  - Revisar cobertura de testes (incluindo clipboard service, cursor, teclado físico, title bar)
  - Verificar que nenhuma string está hardcoded
  - Verificar que nenhum valor de layout está hardcoded
  - Verificar que ViewModels não importam Flutter (exceto `foundation.dart`)
  - Builds de release passam em todas as plataformas suportadas
- **Documentação**:
  - Atualizar docs se houve desvio da arquitetura planejada
  - Documentar comportamento de copiar/colar e cursor editável em `docs/features/calculadora.md`
  - Documentar atalhos de teclado em `docs/features/calculadora.md`
  - Documentar infra de desktop (`AppTitleBar`, `DesktopShell`, `DesktopWindowConfig`) em `docs/fundacao/arquitetura.md`

**Testes**:

- Revisão e complementação de testes de widget para fluxos completos
- Testes de integração dos fluxos principais (calculadora, histórico, configurações, clipboard, cursor, teclado físico)

**Entregável**: App completo, polido, testado e pronto para uso em todas as plataformas suportadas (Android, iOS, Windows, Linux, macOS), com identidade visual própria, suporte a teclado físico e todas as features integradas e refinadas.

---

## Diagrama de Dependências entre Etapas

```
Etapa 1 (Fundação)
    │
    ▼
Etapa 2 (Domínio/Dados base)
    │
    ▼
Etapa 2.1 (Dados: nome, favorito, paginação)
    │
    ▼
Etapa 3 (Motor Calculadora)
    │
    ▼
Etapa 4 (Lógica Histórico/Config)     ← Toda lógica pronta
    │
    ▼
Etapa 5 (UI Calculadora)
    │
    ▼
Etapa 6 (Porcentagem literal)
    │
    ▼
Etapa 7 (Fila de toques)
    │
    ▼
Etapa 8 (Delete contextual + parênteses)
    │
    ▼
Etapa 9 (UI Histórico/Config)
    │
    ▼
Etapa 10 (Copiar e Colar)
    │
    ▼
Etapa 11 (Cursor Editável)
    │
    ▼
Etapa 12 (Logo customizado)
    │
    ▼
Etapa 13 (Teclado físico)
    │
    ▼
Etapa 14 (Windows + infra desktop)
    │
    ▼
Etapa 14.1 (Instalador Windows .exe)
    │
    ▼
Etapa 14.2 (Persistência ao fechar + posição da janela)
    │
    ▼
Etapa 15 (Linux)
    │
    ▼
Etapa 16 (macOS)
    │
    ▼
Etapa 17 (iOS)
    │
    ▼
Etapa 18 (Polimento e Revisão Final)
```

## Resumo da Divisão

| Foco | Etapas |
|------|--------|
| **Lógica e Dados** | 1, 2, 2.1, 3, 4 |
| **Interface Visual e Comportamento** | 5, 6, 7, 8, 9 |
| **Funcionalidades extras** | 10, 11 |
| **Identidade visual e entrada** | 12, 13 |
| **Multi-plataforma** | 14, 14.1, 14.2, 15, 16, 17 |
| **Polimento Final** | 18 |

## Estimativa de Complexidade por Etapa

| Etapa | Complexidade | Arquivos novos (aprox.) | Testes (aprox.) |
|-------|-------------|------------------------|-----------------|
| 1 — Fundação | Baixa | ~12 | ~6 |
| 2 — Domínio/Dados base | Média | ~10 | ~8 |
| 2.1 — Dados (nome, favorito, paginação) | Baixa-Média | ~0 (edições) | ~10 |
| 3 — Motor Calculadora | Alta | ~6 | ~12 |
| 4 — Lógica Histórico/Config | Média | ~6 | ~8 |
| 5 — UI Calculadora | Alta | ~8 | ~8 |
| 6 — Porcentagem literal | Baixa | ~0 (edições) | ~6 |
| 7 — Fila de toques | Média | ~1-2 | ~6 |
| 8 — Delete contextual + parênteses | Média-Alta | ~0-1 (edições) | ~10 |
| 9 — UI Histórico/Config | Alta | ~10 | ~12 |
| 10 — Copiar e Colar | Média | ~3-4 | ~8 |
| 11 — Cursor editável | Média-Alta | ~2-3 | ~8 |
| 12 — Logo customizado | Baixa-Média | ~3-5 (assets + widget) | ~2 |
| 13 — Teclado físico | Média | ~1-2 | ~10 |
| 14 — Windows + infra desktop | Média-Alta | ~4-5 (DesktopShell, AppTitleBar, config) | ~4 |
| 14.1 — Instalador Windows | Baixa-Média | ~4 (iss, build script, docs) | manual |
| 14.2 — Persistência ao fechar + posição da janela | Média | ~2-3 (close handler, posição) | ~12 |
| 15 — Linux | Baixa | ~0 (só nativo) | ~0 |
| 16 — macOS | Baixa-Média | ~0-1 (ajuste do AppTitleBar) | ~1 |
| 17 — iOS | Baixa | ~0 (só nativo) | ~0 |
| 18 — Polimento e Revisão Final | Baixa | ~2 | ~4 |
| **Total** | | **~70-80** | **~115** |
