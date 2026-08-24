# Plano de Implementação — Decima

## Resumo

O projeto está dividido em **22 etapas** sequenciais, numeradas até 23 — a **etapa 17 (iOS) foi removida do escopo** e a numeração das demais foi preservada. As **etapas 1-4** cobrem toda a lógica de negócio, dados e infraestrutura (sem UI). As **etapas 5-8** cobrem a UI da calculadora e ajustes de comportamento (porcentagem, fila de toques e parênteses + delete). A **etapa 9** cobre as demais telas (histórico e configurações) e integração de navegação. A **etapa 10** adiciona suporte a copiar e colar via menu de contexto. A **etapa 11** introduz o cursor editável no display. A **etapa 12** substitui o icônico/splash padrão do Flutter pelo logo próprio do Decima. A **etapa 13** habilita operação por teclado físico. As **etapas 14-16** habilitam o suporte multi-plataforma (Windows, Linux, macOS), com janela fixa e title bar customizada nas plataformas desktop. A **etapa 18** é a revisão final, cobrindo polimento de animações, fluxos completos (incluindo clipboard, cursor, teclado físico e title bar) e qualidade geral em todas as plataformas. As **etapas 19-23** formam o ciclo de refatoração pós-entrega — sem mudança de comportamento: limites de tamanho de arquivo, lints e inventário (19), extração do motor de edição da expressão para o domínio (20), decomposição do `CalculatorViewModel` em sub-controllers (21), decomposição dos widgets grandes (22) e migração de comentários para a documentação com a revisão SOLID final (23). Cada etapa cabe na janela de contexto de 172k tokens. Todas seguem o fluxo TDD obrigatório (Red → Green → Refactor).

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

## Etapa 14.3 — CI/CD, fluxo de branches e distribuição

**Objetivo**: Substituir o fluxo de qualidade local dos outros projetos (husky: `pre-commit`/`commit-msg`/`pre-push`) por um pipeline de CI/CD no GitHub Actions, proteger a `main` contra commits diretos e distribuir builds (dev e release) via Firebase App Distribution e GitHub Releases. Originalmente fora do plano — antecipado como mudança estrutural de processo.

**Escopo**:

- **Fluxo de branches**: `dev` como branch padrão de trabalho (commits diretos permitidos); `main` só recebe código via PR com checks verdes. Rulesets no GitHub: `main-protegida` (PR + 5 checks obrigatórios + bypass por deploy key para o bot de release) e `dev-integracao` (sem force-push/deleção)
- **CI** (`.github/workflows/ci.yml`, em PRs para `dev`/`main` e pushes na `dev`):
  - `commitlint` — Conventional Commits via `commitlint_cli` (Dart) + `commitlint.yaml` (mesmo padrão do runway/verbum/dosia)
  - `analyze` — `dart format --set-exit-if-changed` + `flutter analyze` (zero warnings)
  - `test` — `flutter test --coverage` com gate de cobertura mínima (85%; baseline 88,4%)
  - `build-android` — APK release; push na `dev` gera versão `X.Y.Z-dev.<run>` e distribui ao grupo `dev` do Firebase
  - `build-windows` — bundle + runtime MSVC app-local zipado (instalador Inno só no release: `VersionInfoVersion` exige versão numérica)
- **Release** (`.github/workflows/release.yml`, em push na `main`): porta do hook `pre-push` D5/D6 — `tool/bump_version.dart` (copiado do runway com teste) decide o bump SemVer pelo range desde a última tag `v*`, commita `chore(release): vX.Y.Z+B` + tag via deploy key, builda APK assinado e instalador Windows, distribui no Firebase (grupo `stable`) e publica GitHub Release com `.sha256`
- **Assinatura Android**: keystore de upload dedicado (fora do repo, em secrets no CI; `key.properties` git-ignorado com fallback para debug)
- **Infra**: `.fvmrc` pinando Flutter 3.44.2 (fonte da versão no CI), remoção de `/.github/` do `.gitignore`, ação composta `setup-flutter`
- **Firebase**: projeto `decima-wevasoft`, app `com.wevasoft.decima`, grupos de testers `dev` e `stable` — sem SDK Firebase no app

**Testes**:

- Unitários: `test/tool/bump_version_test.dart` (7 cenários — RESULT/NOOP, âncora de range, anti-loop)
- Validação: pipeline verde no primeiro PR `dev` → `main`

**Entregável**: `main` imutável fora de PRs, todo push validado por CI, releases automáticos versionados com changelog e builds distribuídos no Firebase (dev e stable) e GitHub Releases.

---

## Etapa 15 — Suporte a Linux

**Objetivo**: Habilitar o build para Linux reutilizando a infra de desktop da Etapa 14. Validar a title bar customizada e o tamanho fixo no ambiente Linux (GTK).

**Escopo**:

- **Habilitação da plataforma**:
  - `flutter create --platforms=linux .` — o runner GTK já existia do `create` original e ficou inalterado pelo comando; o efeito colateral em `.metadata`/`pubspec.lock` foi revertido
  - `window_manager` validado no GTK sob X11 e Wayland
- **Runner GTK** (`linux/runner/my_application.cc`) — três desvios do template:
  - Remoção do `GtkHeaderBar`: com ele, `TitleBarStyle.hidden` só esconde o widget e mantém a decoração do lado do cliente, desalinhando `getPosition`/`setPosition`. Sem ele o plugin cai em `gtk_window_set_decorated(FALSE)` e a janela fica sem moldura em qualquer WM
  - Tamanho inicial `360x720` (era `1280x720`): **obrigatório**, não cosmético — `setResizable(false)` faz o GTK reescrever os geometry hints com o tamanho default e sobrescrever o `setSize` das `WindowOptions`
  - Título `Decima` (era `decima`)
  - `set_application_icon()`: o template não define ícone de janela, e sem `_NET_WM_ICON` o ambiente cai no genérico. Usa o tema quando o `.desktop` está instalado e cai no `logo.png` do próprio bundle quando não está. Em Wayland o ícone depende do casamento `app_id` ↔ `.desktop`, que o GTK3 não consegue suprir por protocolo
- **Ajustes específicos por plataforma no `lib/`** (dois desvios reais encontrados na validação, decididos por `PlatformInfo.isLinux`):
  - `setMaximizable(false)` não é chamado no Linux: o plugin implementa isso como `GDK_WINDOW_TYPE_HINT_DIALOG`, e a janela saía da barra de tarefas/alt-tab e deixava de minimizar. `setResizable(false)` já impede maximizar no GTK
  - `isWindowPositionStorable()` descarta a origem `(0,0)` no Linux: no Wayland `getPosition()` sempre devolve a origem, e gravá-la reabriria a janela encostada no canto em vez de centralizada
- **Integração com o desktop** (`linux/packaging/`):
  - `com.wevasoft.decima.desktop` com `StartupWMClass` casando o `WM_CLASS` da janela
  - Ícone do tema `hicolor` em 8 tamanhos, derivado do master pelo `tool/icon` — o `flutter_launcher_icons` **não** tem suporte a Linux (a chave `linux:` era ignorada em silêncio e foi removida)
  - `install-desktop-entry.sh` — publica/remove no menu do usuário, sem `sudo`
- **Empacotamento (documentado, não implementado)**:
  - AppImage, Flatpak, Snap e `.deb`/`.rpm` em `docs/fundacao/empacotamento-linux.md`
- **Reutilização**:
  - `DesktopShell` e `AppTitleBar` da Etapa 14 funcionam sem alterações

**Testes**:

- Unit: `PlatformInfo.isLinux` (novo arquivo, cobre também `isDesktop`) e `isWindowPositionStorable` — 10 cenários
- Verificação manual (X11 e Wayland, via WSLg): janela fixa 360×720, title bar customizada, drag, minimizar, fechar com flush da sessão e gravação da posição
- `flutter build linux --release` — sucesso
- Regressão: suíte existente verde, `flutter analyze` sem warnings

**Entregável**: Decima rodando no Linux com a mesma experiência do Windows.

---

## Etapa 15.1 — Pacote `.deb` e distribuição Linux no CD

> Origem: o release v0.7.0 saiu sem artefato Linux — a Etapa 15 documentou as opções de empacotamento sem implementar nenhuma. Decisão: `.deb` avulso no GitHub Release (instalável com `dpkg -i`/duplo clique, sem exigir repositório APT); presença em loja (Flathub) fica como evolução futura.

**Objetivo**: Empacotar o bundle Linux como `.deb` reutilizável (script local + CI) e integrá-lo ao pipeline: artefato de validação no CI e `.deb` + `.sha256` no GitHub Release.

**Escopo**:

- **Empacotamento** (`tool/deb/build_deb.sh`):
  - Layout FHS: bundle inteiro em `/usr/lib/decima/`, symlink `/usr/bin/decima`, `.desktop` e ícones `hicolor` de `linux/packaging/` em `/usr/share/`, AppStream em `/usr/share/metainfo/`
  - `DEBIAN/control` gerado com `Installed-Size` calculado; `dpkg-deb --root-owner-group` (sem fakeroot)
  - `Depends` mínimo (`libgtk-3-0`, `libglib2.0-0` + base): o SQLite **não** entra — o bundle embute `libsqlite3.so` via native assets do `package:sqlite3`; nomes antigos funcionam nos sistemas `t64` (Ubuntu 24.04+) porque os pacotes renomeados publicam `Provides:` versionado
  - Sem scripts de mantenedor: caches de `.desktop`/ícones/AppStream atualizam via dpkg triggers dos pacotes do sistema
  - Versão Debian: `X.Y.Z` no release; `X.Y.Z~dev.N` / `X.Y.Z~pr.N` nos builds do CI (`~` ordena antes da final)
  - Saída: `dist/decima-<versão>-linux-amd64.deb` + `.sha256`
- **AppStream** (`linux/packaging/com.wevasoft.decima.metainfo.xml`):
  - `id` = `APPLICATION_ID`, `launchable` apontando para o `.desktop`, resumo/descrição em inglês e pt-BR; `@VERSION@`/`@DATE@` substituídos pelo script no empacotamento
- **CI** (`ci.yml`): job `build-linux` (needs `analyze`+`test`, mesmo gating do `build-windows`: push na `dev` e PR para `main`), build + `.deb` como artefato de 14 dias; vira o 6º check obrigatório do ruleset `main-protegida`
- **Release** (`release.yml`): job `release-linux` (`flutter build linux --release` + `build_deb.sh --skip-build`), artefato somado ao GitHub Release pelo `publish`
- **Documentação**: `docs/fundacao/empacotamento-linux.md` (seção do `.deb`, tabela de opções atualizada), `docs/fundacao/ci-cd.md` (novos jobs, 6 checks), `README.md` (Instalação (Linux) com o `.deb`)

**Testes**:

- Estrutural: `dpkg-deb --info`/`--contents` conferindo control, layout, permissões e symlink
- Instalação local: `dpkg -i` → abrir pelo menu → operar → remover com `dpkg -r` preservando `~/.local/share/com.wevasoft.decima`
- CI: `build-linux` verde no push da `dev`; primeiro release com `.deb` publicado
- Regressão: suíte de testes e `flutter analyze` intactos (etapa sem código Dart)

**Entregável**: Todo release da `main` publica `decima-<versão>-linux-amd64.deb` com SHA-256 no GitHub Release, e o CI valida o empacotamento a cada PR para `main`.

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

## Etapa 16.1 — Distribuição macOS no CD e enxugamento do canal dev

> Origem: a Etapa 16 entregou o `.app` buildando só na máquina do dev — nenhum release publicava artefato macOS. Na mesma passada, o canal `dev` do Firebase App Distribution foi aposentado: o APK de push na `dev` já sai como artefato do Actions e o grupo de testers `dev` nunca teve uso real.

**Objetivo**: Empacotar o `Decima.app` em zip reutilizável (script local + CI) e integrá-lo ao pipeline — artefato de validação no CI e `.zip` + `.sha256` no GitHub Release —, removendo a distribuição Firebase do CI.

**Escopo**:

- **Empacotamento** (`tool/macos/build_zip.sh`):
  - Guard de plataforma (`uname -s` = `Darwin`): `ditto`/`codesign` não existem fora do macOS
  - Nome do bundle lido de `PRODUCT_NAME` (`AppInfo.xcconfig`) — sem constante duplicada no script
  - `codesign --verify --strict` antes de compactar: a assinatura ad-hoc é a garantia de integridade do bundle, falhar cedo é melhor que publicar um `.app` quebrado
  - `ditto -c -k --keepParent` (nunca `zip`: symlinks, bit de execução e metadados invalidariam a assinatura)
  - Versão: `X.Y.Z` no release; `X.Y.Z-dev.N` / `X.Y.Z-pr.N` nos builds do CI (o zip não tem a restrição de formato da versão Debian)
  - Saída: `dist/decima-<versão>-macos.zip` + `.sha256`
- **CI** (`ci.yml`): job `build-macos` em `macos-latest` (needs `analyze`+`test`, mesmo gating do `build-windows`/`build-linux`: push na `dev` e PR para `main`), zip como artefato de 14 dias; vira o 7º check obrigatório do ruleset `main-protegida`
- **Release** (`release.yml`): job `release-macos` (`flutter build macos --release` + `build_zip.sh --skip-build`), artefato somado ao GitHub Release pelo `publish`
- **Firebase no CI**: remover os steps de distribuição do grupo `dev` e o env `HAS_FIREBASE` do `ci.yml` — o CI passa a não distribuir nada; o `release.yml` mantém o grupo `stable` intacto
- **Documentação**: `docs/fundacao/empacotamento-macos.md` (script, seção CI/CD, gotchas do `ditto`/`upload-artifact`), `docs/fundacao/ci-cd.md` (novos jobs, 7 checks, Firebase só no release), `README.md` (Instalação (macOS) a partir do release)

**Testes**:

- CI: `build-macos` verde no push da `dev` e no PR para `main`
- Release: primeiro `decima-<semver>-macos.zip` + `.sha256` publicado no GitHub Release
- Manual: extrair o zip do release em outro Mac, liberar no Gatekeeper e abrir o app
- Regressão: suíte de testes e `flutter analyze` intactos (etapa sem código Dart)

**Entregável**: Todo release da `main` publica `decima-<versão>-macos.zip` com SHA-256 no GitHub Release, o CI valida o empacotamento a cada PR para `main` e nenhuma distribuição Firebase acontece fora do canal `stable`.

---

## Etapa 17 — Suporte a iOS *(removida do escopo)*

**Motivo**: sem uma assinatura do Apple Developer Program (US$ 99/ano) não existe **nenhum** caminho de distribuição para iOS — não há TestFlight nem App Store, e um build assinado com Apple ID gratuito expira em 7 dias até no próprio dispositivo. A etapa entregaria apenas um `flutter build ios --no-codesign` verde: uma pasta `ios/` que quebra a cada bump de dependência e que ninguém consegue instalar.

O macOS foi mantido justamente porque a assimetria não se aplica a ele — a assinatura ad-hoc (`CODE_SIGN_IDENTITY = "-"`, default do template) produz um `.app` distribuível, com atrito de Gatekeeper mas instalável.

**Removido**: pasta `ios/` (52 arquivos versionados), `ios: true` + `remove_alpha_ios` do `flutter_launcher_icons.yaml`, `ios: true` + `ios_content_mode` do `flutter_native_splash.yaml`.

**Preservado**: os `case TargetPlatform.iOS:` em `PlatformInfo` e os testes que os cobrem — o enum é do Flutter e o `switch` precisa continuar exaustivo, independente das plataformas suportadas.

**Reversão**: `flutter create --platforms=ios .` regenera o runner em segundos caso a assinatura paga seja adquirida.

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
  - Verificar paridade visual entre Android, Windows, Linux e macOS
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

**Status (revisão de 2026-08-23)**: todo o escopo já havia sido entregue e validado nas Etapas 5–16.1 — a checagem item a item, com a etapa de origem de cada validação, está em `plano/tarefas.md`. Os quatro itens que restavam foram confirmados pelo usuário na própria revisão: a transição default do `MaterialPageRoute` e o cross-fade de tema do `MaterialApp` ficam como estão, o teclado externo no Android opera a calculadora corretamente e a paridade visual foi conferida em cada plataforma durante o desenvolvimento (o Linux só não foi visto em instalação nativa, apenas via WSLg).

O único bug novo da revisão — a moldura verde que o Android desenhava na borda da tela ao primeiro toque no teclado físico, realce de foco do sistema sobre a `FlutterView` — foi corrigido em `MainActivity.onStart()` e validado no APK do release v0.9.1. **Etapa concluída.**

**Entregável**: App completo, polido, testado e pronto para uso em todas as plataformas suportadas (Android, Windows, Linux, macOS), com identidade visual própria, suporte a teclado físico e todas as features integradas e refinadas.

---

## Etapa 19 — Fundação da Refatoração: limites de tamanho, lints e inventário

> Origem: revisão de manutenibilidade pós-v0.9.1. O app está funcional e 100% testado, mas as violações de SOLID se concentram em poucos arquivos — `calculator_view_model.dart` acumula **1.526 linhas e seis responsabilidades**, e seu teste espelho tem 2.583. As Etapas 19–23 formam um ciclo de refatoração **sem mudança de comportamento**: a suíte existente é a rede de segurança e nenhuma expectativa de teste é alterada, apenas movida.

**Objetivo**: Estabelecer a infraestrutura de qualidade que orienta o ciclo (limite de linhas por arquivo, verificação no CI, lints mais rígidos, política de comentários) e publicar o inventário que as Etapas 20–23 consomem.

**Escopo**:

- **Limite de linhas por arquivo**: ideal de **≤ 600 linhas** por arquivo Dart em `lib/` e `test/` (excluindo gerados: `lib/utils/l10n/`), documentado em `docs/fundacao/padroes-codigo.md` junto com a tabela de decomposição por camada:
  - ViewModel se aproximando do limite → sub-controllers em `ui/<feature>/controllers/`
  - Page/Widget > ~500 → widgets extraídos para `widgets/` e lógica pura para helpers testáveis
  - Domain/Service > ~400 → classes colaboradoras com responsabilidade única
- **Verificador** (`tool/check_file_length.dart`): lista os arquivos acima do limite e sai com erro quando algum fora da **allowlist** estoura; a allowlist nasce com os arquivos que aguardam as Etapas 20–21 (`calculator_view_model.dart`, `calculator_view_model_test.dart`) e é **zerada ao fim da Etapa 21**. Mesmo padrão do `bump_version.dart`: script Dart com teste próprio
- **CI**: novo step no job `analyze` rodando o verificador
- **Lints**: curar e ativar regras extras em `analysis_options.yaml` alinhadas às convenções já documentadas — candidatas: `directives_ordering` (ordem de imports já documentada), `always_use_package_imports`, `prefer_single_quotes`, `unawaited_futures`, `prefer_final_locals`, `sort_pub_dependencies` — corrigindo os avisos resultantes. `unawaited_futures` em particular torna explícito, via `unawaited(...)`, cada fire-and-forget intencional da persistência de sessão
- **Política de comentários** (definida aqui, aplicada em massa na Etapa 23), registrada em `docs/fundacao/padroes-codigo.md`:
  - Doc comment (`///`) em API pública: contrato em 1–3 linhas (**o quê**, nunca o como)
  - Inline (`//`) apenas para invariante local que o código não consegue expressar
  - "Porquê" de design, história e trade-offs → `docs/` (seções de features ou tabelas de Gotchas)
  - Proibido comentário que narra o óbvio
  - **Idioma**: resolver a inconsistência atual — o padrão documenta comentários em pt-BR, mas ~95% do código está em inglês, com arquivos misturando os dois. Recomendação: manter a regra pt-BR (consistente com `docs/`) e traduzir apenas o que sobreviver à triagem da Etapa 23
- **Inventário baseline** em `plano/observacoes.md`: tabela dos maiores arquivos, responsabilidades misturadas e densidade de comentários, com o destino planejado de cada um

**Testes**:

- Unitários: `test/tool/check_file_length_test.dart` (limite, allowlist, exclusão de gerados, saída de erro)
- Regressão: suíte completa verde, `flutter analyze` zero warnings com o novo conjunto de lints, cobertura ≥ baseline

**Entregável**: Limite de 600 linhas documentado e verificado no CI, lints rígidos ativos, política de comentários publicada e inventário registrado. Nenhum comportamento alterado.

---

## Etapa 20 — Refatoração do Domínio: motor de edição da expressão

**Objetivo**: Extrair do `CalculatorViewModel` as ~500 linhas do motor de edição por cursor — manipulação pura de string, sem estado de UI nem persistência — para uma classe de domínio testável isoladamente.

**Motivação (SRP)**: `_editText`/`_cursorPos`/`_atEnd` e a família `_edit*` (`_editInsertDigits`, `_editInsertLiteral`, `_editBackspace`, `_editSplitBlockWithOperator`, `_tryMergeBlocksAtCursor`, `_editInsertParenthesis`, `_editApplyPercentInBlock`, `_replaceBlockWithFormatted`, mais os helpers `_findNumberBlock`, `_stripToDigits`, `_countDigits`, `_positionWithDigitsAfter`) formam um editor de texto completo embutido no ViewModel. Nada disso toca repositório, clipboard ou `notifyListeners` — é domínio puro que hoje só pode ser testado através da fachada.

**Escopo**:

- **`domain/expression_editor.dart`** — `ExpressionEditor` (Dart puro, sem import de Flutter):
  - Estado imutável `EditorState(text, cursor)`; cada operação recebe um estado e devolve o novo
  - Operações: inserir dígitos, operador (com split de bloco quando o cursor está no meio de um número), parêntese, `%`, e backspace (com merge de blocos ao apagar operador) — todas Add2-aware, preservando a reancoragem do cursor pela contagem de dígitos à direita
  - `DecimalSeparator` como parâmetro (o editor não conhece Settings)
- `_normalizeForEvaluator` migra junto (para o editor ou para o `ExpressionEvaluator` — decidir na implementação e documentar)
- **`PasteInputParser`**: mover de `utils/` para `domain/` — pela regra de classificação da própria arquitetura ("É regra de negócio? → `domain/`"); imports atualizados
- **ViewModel delega**: o modo de edição vira "chamar o editor e aplicar o `EditorState` devolvido + `notifyListeners`"
- **Testes movidos, não reescritos**: nasce `test/unit/domain/expression_editor_test.dart` absorvendo os cenários de edição/cursor hoje dentro de `calculator_view_model_test.dart`; o teste do parser muda de pasta acompanhando o arquivo. Os testes de integração do ViewModel (fluxos completos com cursor) permanecem

**Testes**:

- Unitários: `ExpressionEditor` — todos os cenários atuais de edição no meio da expressão (inserção, backspace com merge, split por operador, parênteses, `%`, reancoragem do cursor, multiline)
- Regressão: suíte completa verde sem alterar nenhuma expectativa; cobertura ≥ baseline

**Entregável**: Motor de edição como unidade de domínio isolada e testada; `calculator_view_model.dart` ~500 linhas menor; allowlist do verificador reduzida.

---

## Etapa 21 — Refatoração do ViewModel: sub-controllers

**Objetivo**: Decompor o restante do `CalculatorViewModel` em colaboradores com responsabilidade única, deixando-o como fachada **≤ 600 linhas** para a UI, e espelhar a mesma divisão no teste de 2.583 linhas.

**Escopo**:

- **`ui/calculator/controllers/session_recorder.dart`** — persistência da sessão: absorve `_sessionLines`, `_currentSessionId`, `_persistedLineCount`, `_pendingAdd`, `_pendingWrite`, `_sessionGeneration`, `_saveOrUpdateSession`, `_trackWrite`, `flushSession` e `_resetSessionTracking`. Encapsula o encadeamento de escritas, as gerações de sessão e a idempotência do flush — invariantes hoje explicados por ~40 linhas de comentário no ViewModel que passam a ser o contrato natural da classe
- **`ui/calculator/controllers/clipboard_controller.dart`** — copiar/colar: `copyExpression`, `copyResult`, `copyHistory`, `pasteFromClipboard`, `clipboardHasText`, `_applyPastedContent`, `_restoreInputTokens` (usa `ClipboardService` + `PasteInputParser`)
- **Timeline** (`_visibleCount`, `loadMoreTimelineEntries`, `visibleTimelineEntries`): avaliar extração para `timeline_controller.dart` ou manutenção no ViewModel se o tamanho já ficou confortável — decidir na implementação e registrar
- **DIP**: `Add2Engine` e `ExpressionEvaluator` deixam de ser instanciados dentro do ViewModel e passam a ser injetados via construtor (com default), como já acontece com os repositórios; wiring em `dependencies.dart`
- O ViewModel permanece a **única API para a UI** (fachada `ChangeNotifier`); os controllers recebem repositórios/serviços via construtor e são mockáveis nos testes
- **Testes fatiados por área**: `calculator_view_model_test.dart` é dividido em arquivos focados sob `test/unit/ui/calculator/` (entrada/operadores, parênteses/porcentagem, sessão/persistência, clipboard, timeline, cursor/integração com o editor), mais testes diretos de `SessionRecorder` e `ClipboardController`. Nenhum cenário descartado
- **Allowlist do verificador zerada**: a partir daqui, nenhum arquivo de `lib/` ou `test/` acima de 600 linhas

**Testes**:

- Unitários: `SessionRecorder` (criação/atualização, escrita em voo, gerações, flush idempotente) e `ClipboardController` (copiar/colar, conteúdo inválido, round-trip com o parser)
- Regressão: suíte completa verde com as mesmas expectativas; cobertura ≥ baseline

**Entregável**: `CalculatorViewModel` legível de uma sentada, cada responsabilidade em uma classe nomeável, verificador de tamanho sem exceções.

---

## Etapa 22 — Refatoração da UI: widgets enxutos

**Objetivo**: Aplicar a disciplina de responsabilidade única aos widgets que concentram lógica além de renderização — nenhum deles viola o limite de 600, mas todos misturam preocupações que dificultam manutenção.

**Escopo**:

- **`AnimatedInputDisplay`** (538 linhas): extrair o diffing de caracteres/slots (comparação entre texto anterior e atual para decidir quais caracteres animam) para um helper puro testável sem árvore de widgets; extrair o cursor para widget próprio. O widget principal fica com layout, animação e scroll
- **`HistoryListItem`** (390 linhas): extrair o diálogo de renomear (`_showRenameDialog`) para `ui/history/widgets/rename_entry_dialog.dart`; avaliar extração de header/linhas expandidas/footer conforme a leitura ficar
- **`history_page.dart`**: mover `_AnimatedListItem` para `ui/history/widgets/`
- **`main.dart`**: avaliar extração do observer de ciclo de vida (flush em `paused`/`hidden` no mobile) para `ui/core/` — `main.dart` fica só com bootstrap
- Revisão de passagem: nenhum widget novo recebe lógica de negócio (apenas apresentação + callbacks para o ViewModel)

**Testes**:

- Unitários: helper de diffing de caracteres (cenários hoje só cobertos via testes de widget)
- Widget: testes existentes continuam passando; widgets extraídos com API pública ganham teste próprio
- Regressão: suíte completa verde; cobertura ≥ baseline

**Entregável**: Widgets com uma responsabilidade cada, lógica pura testável fora da árvore de widgets.

---

## Etapa 23 — Comentários → Documentação e revisão SOLID final

**Objetivo**: Aplicar a política de comentários da Etapa 19 a todo o código — migrar o "porquê" para `docs/`, apagar o óbvio, manter o mínimo intencional — e fechar o ciclo com a revisão SOLID final.

**Motivação**: ~700 linhas de comentário em `lib/` (fora l10n gerado), 283 delas no ViewModel pré-refatoração. Boa parte (a) explica invariantes que deixam de existir com as classes menores das Etapas 20–22, (b) duplica o que `docs/features/calculadora.md` já documenta (fila de toques, flush ao fechar, Add2, colar) ou (c) é rationale de design que pertence às tabelas de Gotchas. Além disso, arquivos misturam comentários em inglês e português.

**Escopo**:

- **Triagem arquivo a arquivo** (maiores densidades: `paste_input_parser.dart` 51, `window_close_handler.dart` 49, `animated_input_display.dart` 44, `keyboard_shortcuts.dart` 38, `window_position.dart` 29, além do que restou do ViewModel), classificando cada comentário em:
  - **Manter** — contrato de API pública em 1–3 linhas ou invariante local inexpressável em código
  - **Migrar** — rationale/história/trade-off → seção ou Gotcha do doc correspondente
  - **Apagar** — narração do óbvio ou redundância com nome de método/teste
- **Destinos das migrações**: `docs/features/calculadora.md` (edição/cursor, fila de toques, flush, clipboard), `docs/features/configuracoes.md` (janela/posição), `docs/fundacao/arquitetura.md` (estrutura pós-refatoração: `domain/expression_editor`, `ui/calculator/controllers/`, thresholds de tamanho) — nada migrado pode se perder: cada fato removido do código precisa existir em `docs/`
- **Idioma**: uniformizar os comentários sobreviventes conforme a decisão da Etapa 19
- **Renomear** `ui/core/desktop/window_position.dart` → `window_position_validator.dart` (ou similar): hoje o nome colide com a entity `domain/entities/window_position.dart`
- **Revisão SOLID final**, classe a classe: uma responsabilidade nomeável por classe; dependências por abstração onde há mais de uma implementação ou necessidade de mock; interfaces mínimas; varredura de dead code
- Sincronizar `docs/` com o estado final do código; atualizar `plano/changelog.md`

**Testes**:

- Regressão: suíte completa verde (etapa não altera comportamento), `flutter analyze` zero warnings, `dart format` limpo, cobertura ≥ baseline
- Verificador de tamanho sem exceções

**Entregável**: Código autoexplicativo com comentários mínimos e intencionais, documentação como fonte única do "porquê", nenhum arquivo acima de 600 linhas, projeto pronto para manutenção de longo prazo.

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
Etapa 14.3 (CI/CD + fluxo de branches)
    │
    ▼
Etapa 15 (Linux)
    │
    ▼
Etapa 16 (macOS)
    │
    ▼
Etapa 18 (Polimento e Revisão Final)
    │
    ▼
Etapa 19 (Limites, lints e inventário)
    │
    ▼
Etapa 20 (Domínio: motor de edição)
    │
    ▼
Etapa 21 (ViewModel: sub-controllers)
    │
    ▼
Etapa 22 (UI: widgets enxutos)
    │
    ▼
Etapa 23 (Comentários → docs + revisão SOLID)
```

## Resumo da Divisão

| Foco | Etapas |
|------|--------|
| **Lógica e Dados** | 1, 2, 2.1, 3, 4 |
| **Interface Visual e Comportamento** | 5, 6, 7, 8, 9 |
| **Funcionalidades extras** | 10, 11 |
| **Identidade visual e entrada** | 12, 13 |
| **Multi-plataforma** | 14, 14.1, 14.2, 15, 15.1, 16, 16.1 |
| **Processo e infraestrutura** | 14.3 |
| **Polimento Final** | 18 |
| **Refatoração e manutenibilidade** | 19, 20, 21, 22, 23 |

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
| 14.3 — CI/CD + fluxo de branches | Média | ~6 (workflows, motor, configs) | ~7 |
| 15 — Linux | Baixa | ~0 (só nativo) | ~0 |
| 16 — macOS | Baixa-Média | ~0-1 (ajuste do AppTitleBar) | ~1 |
| 16.1 — Distribuição macOS no CD | Baixa | ~1 (script de empacotamento) | manual |
| ~~17 — iOS~~ | *removida do escopo* | — | — |
| 18 — Polimento e Revisão Final | Baixa | ~2 | ~4 |
| 19 — Limites, lints e inventário | Baixa-Média | ~2 (verificador + config) | ~4 |
| 20 — Domínio: motor de edição | Alta | ~2 (editor + estado) | movidos + novos |
| 21 — ViewModel: sub-controllers | Alta | ~3-4 (controllers + fatias de teste) | movidos + novos |
| 22 — UI: widgets enxutos | Média | ~4-5 (widgets/helpers extraídos) | ~6 |
| 23 — Comentários → docs + revisão SOLID | Média | ~0-1 (edições e rename) | ~0 |
| **Total** | | **~70-80** | **~115** |
