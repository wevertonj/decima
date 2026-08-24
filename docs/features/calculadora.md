# Calculadora

> Tela principal do Decima: entrada Add2, timeline de cálculos, keypad, cursor editável, copiar/colar e operação por teclado físico.

## Visão Geral

A calculadora é a tela principal do Decima. Utiliza o conceito **Add2** — entrada automática de 2 casas decimais sem necessidade de pressionar ponto — com suporte a todas as operações básicas.

## Conceito Add2

O diferencial do Decima é a entrada numérica com **2 casas decimais automáticas**. O usuário digita apenas números e o sistema posiciona o separador decimal automaticamente conforme os dígitos são inseridos:

- Digitar `1` → `0.01`
- Digitar `12` → `0.12`
- Digitar `125` → `1.25`
- Digitar `1250` → `12.50`
- Digitar `12500` → `125.00`

O separador decimal é **sempre implícito** — as 2 últimas posições são sempre a parte decimal. Isso torna a entrada de valores monetários extremamente rápida.

### Exemplo de Uso Completo

```
12.50 × 3.00 − 4.45
```

O usuário digita: `1250`, `×`, `300`, `−`, `445`

## Funcionalidades

- **Operações básicas**: Soma (+), subtração (−), multiplicação (×), divisão (÷)
- **Porcentagem (%)**: Cálculo de porcentagem com exibição literal na expressão (ex: `100.00 + 10.00%`). Comportamento contextual: em `+`/`−` aplica percentual sobre o operando anterior; em `×`/`÷` converte para fração.
- **Parênteses inteligentes ( )**: Botão único que decide entre abrir e fechar com base no contexto. Suporte a aninhamento ilimitado. Parênteses não fechados ao pressionar `=` são auto-fechados.
- **Duplo zero (00) e triplo zero (000)**: Atalhos para entrada rápida de zeros
- **Limpar (C)**: Reseta o display e a expressão. Cor contextual: dimmed quando não há conteúdo, primary quando há conteúdo (transição animada).
- **Backspace (⌫)**: Disponível na barra de ícones (não no keypad). Remove o último caractere/token. Cor contextual igual ao botão `C`.
- **Igual (=)**: Avalia a expressão, exibe o resultado, persiste no histórico e prepara nova linha

## Layout

### Display — Timeline

A tela funciona como uma **timeline vertical** com scroll:

- **Linhas superiores** (cor secundária/sutil): Cálculos anteriores da sessão. O usuário pode rolar para cima para ver o que já saiu da tela.
- **Penúltima linha** (texto branco): Cálculo atual sendo digitado pelo usuário.
- **Última linha** (texto cinza): Prévia do resultado em tempo real, exibida apenas quando a expressão forma um cálculo válido.

Conforme o usuário confirma um cálculo (pressiona `=`), a linha atual sobe para o histórico da timeline e uma nova linha de entrada aparece.

#### Performance — Load More

Para sessões longas com muitos cálculos, a timeline exibe apenas as últimas N linhas por padrão. Um botão "load more" no topo permite carregar os cálculos anteriores da sessão sob demanda. Isso evita renderizar centenas de widgets simultaneamente.

### Barra de Ícones

Localizada entre a timeline e o keypad:

- **Ícone de relógio (⏱)**: Abre o histórico salvo. Ao retornar com uma entrada selecionada, a sessão é carregada na timeline.
- **Ícone de backspace (⌫)**: Apaga o último caractere/token. Cor contextual (dimmed sem conteúdo, primary com conteúdo).
- **Ícone de configurações (⚙)**: Abre as configurações

### Keypad

- **Linha 1**: C, %, ( ), ÷
- **Linha 2**: 7, 8, 9, ×
- **Linha 3**: 4, 5, 6, −
- **Linha 4**: 1, 2, 3, +
- **Linha 5**: 000, 00, 0, =

Botões numéricos são neutros. Operadores e o botão `=` usam a cor `primary` (acento). Os botões `C`, `%` e `( )` são botões de ação com cor contextual.

## Regras do Add2

- As 2 últimas posições do número são **sempre** a parte decimal
- O separador decimal é exibido automaticamente — o usuário nunca o digita manualmente
- O botão `⌫` remove o último dígito e reajusta o valor (ex: `12.50` → `1.25`)
- O display respeita a configuração de separador (ponto ou vírgula) definida nas configurações
- Valores são formatados com separador de milhar quando aplicável

## Persistência

Toda operação avaliada (ao pressionar `=`) é salva no histórico (SQLite) com:

- Expressão completa (preserva o `%` literal e parênteses)
- Resultado
- Timestamp

### Flush ao fechar o app

`CalculatorViewModel.flushSession()` fecha o cálculo em andamento antes de o processo terminar — nenhum cálculo é perdido por fechar o app sem pressionar `=`.

| Situação ao fechar | Comportamento |
|--------------------|---------------|
| Expressão com ao menos um operador (`10.00 + 5.00`) | Avaliada e gravada como se o `=` tivesse sido pressionado |
| Parênteses abertos (`( 10.00 + 5.00`) | Auto-fechados antes de avaliar, igual ao `=` |
| Número solto, sem operador (`12.00`) | **Não** grava — não há cálculo, apenas um número digitado |
| Sessão vazia | No-op |
| Logo após um `=` | No-op — não duplica a linha nem cria sessão nova |
| Cursor no meio da expressão (modo de edição) | Mesmo caminho do `=`: o texto editado é a fonte da verdade |

`flushSession()` é idempotente e o `Future` que devolve só completa depois de a escrita chegar ao banco — inclusive um `add` ainda em voo, cujo id é aguardado para que a segunda linha vire `update` da mesma sessão, nunca uma sessão nova.

| Plataforma | Gatilho |
|------------|---------|
| Desktop | `WindowCloseHandler` — `X` da title bar, `Alt+F4` e "Fechar janela" da barra de tarefas |
| Mobile | `AppLifecycleListener` (`onHide` / `onPause` / `onExitRequested`) no `_DecimaAppState` |

## Fila de Toques

Todo toque em qualquer botão é enfileirado e processado em ordem, mesmo durante animações de feedback. O `onPressed` é despachado no `onTapDown` (sem aguardar `tapUp`), eliminando latência. Não há `debounce`/`throttle` — toques nunca são descartados. Animações (LED glow, flash de fundo) são independentes do despacho da ação.

## Copiar e Colar

O display da calculadora suporta copiar e colar via menu de contexto sobre a área da timeline. As opções aparecem condicionalmente conforme o estado atual:

- **Copiar cálculo**: visível quando há expressão na entrada atual; copia o texto completo do display (ex: `1000.00 + 10.00%`)
- **Copiar resultado**: visível quando há prévia ou resultado pós-`=`; copia o valor numérico
- **Copiar histórico**: visível quando a timeline da sessão tem entradas; copia todas no formato `<expressão> = <resultado>` (uma por linha)
- **Colar**: sempre visível; desabilitado quando a área de transferência está vazia

### Gestos de abertura

| Gesto | Handler | Contexto |
|-------|---------|----------|
| Toque longo | `onLongPressStart` | Touch (mobile e telas sensíveis ao toque no desktop) |
| Clique com o botão direito | `onSecondaryTapUp` | Mouse/trackpad — dispensa manter o botão esquerdo pressionado no desktop |

Ambos abrem o mesmo menu, ancorado na posição global do ponteiro (`details.globalPosition` → `_openContextMenu`). Nenhum é condicionado à plataforma: um dispositivo híbrido responde aos dois.

### Validação e Normalização do Colar

A entrada colada passa por um parser que aceita:

- **Inteiros**: padded com `.00` (face value, ex: `1250` → `1250.00`)
- **Decimais com ponto**: preservam as casas decimais (ex: `12.50`, `12.5` → `12.50`)
- **Decimais com vírgula**: vírgula tratada como separador decimal (ex: `12,50`)
- **Separador de milhar**: ignorado (ex: `1.000,00` → `1000.00`, `1,000.00` → `1000.00`)
- **Operadores**: aceita variantes (`*`, `x`, `X` → `×`; `/` → `÷`; `-` → `−`)
- **Expressões**: parsed por completo (ex: `10 + 5`, `(10 + 5) × 2`, `100 + 10%`)

Conteúdo inválido exibe um snackbar com mensagem localizada (`pasteInvalid`). Operações bem-sucedidas exibem o snackbar `copied`.

### Colar linhas já resolvidas

Texto no formato `<expressão> = <resultado>` — exatamente o que **Copiar histórico** produz — é restaurado como sessão, fechando o ciclo copiar → colar:

| Entrada colada | Timeline | Display |
|----------------|----------|---------|
| `10 + 5 = 15` | `10.00 + 5.00 = 15.00` | `15.00` |
| `10 + 5 = 15`<br>`20 × 2 = 40` | duas linhas | `40.00` |
| `10 + 5 = 15`<br>`7 + 3` | uma linha | `7.00 + 3.00` (prévia `10.00`) |

Regras:

| Regra | Comportamento |
|-------|---------------|
| Resultado à direita do `=` | Apenas **validado** como número isolado; a expressão é sempre recalculada, para nunca gravar no histórico um resultado que não corresponde à expressão (`10 + 5 = 99` produz `15.00`) |
| Última linha sem `=` | Vira a entrada em aberto, com prévia ativa |
| Todas as linhas com `=` | O display recebe o resultado da última, no mesmo estado que um `=` deixa (o próximo dígito começa um número novo) |
| Linha em aberto antes de uma resolvida | Rejeitado — evita ambiguidade de ordem |
| Expressão sem operador à esquerda do `=` | Rejeitado, igual à regra do `=` na calculadora (`10 = 5` não é um cálculo) |
| Linha inavaliável | Aborta o paste inteiro; todas as linhas são avaliadas **antes** de qualquer mutação de estado |
| Persistência | As linhas coladas entram na sessão pendente e são gravadas no próximo `=` ou `C` |

`PasteInputParser.parseContent` retorna um `PastedContent` (`resolvedLines` + `input`); `PasteInputParser.parse` continua servindo o caso de expressão única. Fixtures de teste manual em `plano/fixtures-colar.md`.

### Implementação

- `ClipboardService` (interface em `lib/data/services/`) abstrai o `Clipboard` do Flutter, permitindo mock nos testes
- `PasteInputParser` (em `lib/domain/`) converte texto bruto em tokens normalizados (`x.yy`, operadores, parênteses, `%`)
- `CalculatorViewModel` expõe `copyExpression()`, `copyResult()`, `copyHistory()`, `pasteFromClipboard()` e os getters `hasExpression`, `hasResult`, `hasHistory` para a UI
- `CalculatorContextMenu` (widget) renderiza o menu via `showMenu`, ancorado na posição global do gesto que o abriu

## Cursor Editável

O display suporta um cursor de edição que permite navegar e modificar a expressão em qualquer ponto, não apenas no final.

### Movimentação do cursor

- **Toque em um caractere**: posiciona o cursor imediatamente antes do caractere tocado (`onCharTap` → `setCursorPosition`)
- **Swipe horizontal no display**: arrastar para a esquerda move o cursor à direita; arrastar para a direita move à esquerda (threshold ±200 px/s)
- **Apagar do teclado** (⌫) sempre opera relativo à posição atual do cursor
- Ao mover o cursor para fora do final, a calculadora entra em **modo de edição mid-expression**; ao retornar ao final, volta ao modo normal automaticamente

### Modo de edição

No modo de edição o display permanece **consciente do bloco numérico** sob o cursor — toda inserção ou remoção de dígito reaplica a formatação Add2 ao bloco circundante (separador decimal, separador de milhar e o `%` opcional são preservados). Uma vez ativado (cursor movido para fora do final), o modo de edição **persiste** até `=`, `C`, carregamento de histórico ou colagem.

- **Dígitos** (`0`–`9`, `00`, `000`) são inseridos na posição do cursor dentro do bloco numérico atual; o bloco inteiro é reformatado via Add2 (`23.71` em vez de `2,371` quando se digita `1` após `2,37`)
- **Operadores** (`+`, `−`, `×`, `÷`) **partem o bloco em duas metades** quando há dígitos em ambos os lados do cursor (`12.50` cursor entre `2` e `.` + `+` → `0.12 + 0.50`); nas bordas (cursor sem dígitos antes ou sem dígitos depois) o operador é inserido literalmente como ` op `
- **`%`** é anexado ao final do bloco numérico atual (no-op quando o bloco já termina em `%`)
- **`( )`** fecha (`)` no fim do bloco numérico) somente quando há um `(` sem par no texto **e** o caractere à esquerda do ponto de fechamento é um operando completo (dígito, `%` ou `)`); caso contrário abre um `(` imediatamente **antes** do bloco, agrupando o número que o cursor está tocando. Ao abrir, o cursor mantém a posição relativa (a inserção acontece à sua esquerda); ao fechar, vai para depois do `)`
- **⌫** dentro de um bloco numérico remove um dígito e reformata o bloco via Add2; quando o caractere imediatamente antes do cursor é parte de um operador-com-espaços (` op ` entre dois blocos), o operador é removido inteiro e os blocos vizinhos são **mesclados** via Add2 (raws normalizados via `int.parse` para descartar zeros de padding); fora dos blocos remove o caractere literal
- **`=`** avalia o texto editado, normalizando separadores de milhar e o separador decimal configurado, auto-fechando parênteses abertos (igual ao modo normal), e grava o resultado na timeline
- **C** sai do modo de edição e limpa toda a sessão

A prévia de resultado (`previewResult`) é recalculada em tempo real a partir do texto editado. O `ExpressionEvaluator` retorna `null` para expressões malformadas (operador pendurado, parêntese vazio etc.), mantendo a UI segura contra exceções durante a edição.

### Visual do cursor

O cursor é o widget `BlinkingCursor` (`lib/ui/calculator/widgets/blinking_cursor.dart`, Etapa 22): uma barra vertical fina (2 px de largura) na cor `colorScheme.primary`, com altura proporcional ao `fontSize` atual do display. O blink usa `Timer.periodic(530ms)` em vez de `AnimationController`, evitando que widget tests com `pumpAndSettle` fiquem bloqueados.

Em modo **multiline** (quando a expressão estoura a largura e o display usa `Wrap`), o cursor continua sendo renderizado: ele é injetado no fluxo de tokens de modo a ficar preso ao grupo numérico atual (impede quebra de linha entre dígito e cursor) ou como token próprio em fronteiras (espaço/operador, ponto natural de quebra).

### Implementação

- A manipulação de texto do modo de edição vive no **`ExpressionEditor`** (`lib/domain/expression_editor.dart`, Etapa 20): operações estáticas puras que recebem um `EditorState(text, cursor)` imutável e devolvem o novo — inserir dígitos, operador (split de bloco), parêntese, `%` e backspace (merge de blocos)
- `CalculatorViewModel` mantém `cursorPosition` (int), `_editText` (String?) e `_atEnd` (bool); no modo de edição delega ao editor e apenas aplica o `EditorState` devolvido (`_applyEditorState`) + `notifyListeners`
- `openParenCount` conta os parênteses do `_editText` (`ExpressionEditor.countOpenParens`) quando o modo de edição está ativo — a lista de tokens commitados fica obsoleta nesse modo, e contá-la reportaria um balanço diferente do que o usuário vê
- O bloco numérico sob o cursor é detectado pela faixa máxima de caracteres `[0-9.,%]` contígua; inserções e remoções operam sobre os dígitos brutos do bloco e o resultado é re-formatado via `NumberFormatter.format` aplicando Add2
- **Ancoragem do cursor por dígitos-à-direita**: após cada reformatação Add2, o cursor é restaurado de modo a preservar exatamente o mesmo número de dígitos à sua direita dentro do bloco. Como Add2 padroniza com zero à esquerda (raw `20` → `0.20`), o lado direito é a referência estável; ancorar pela esquerda faria o cursor pular a cada padding/depadding
- `ExpressionEditor.normalizeForEvaluator` converte o texto formatado para a forma canônica esperada pelo `ExpressionEvaluator` — fica no editor porque desfaz a formatação de exibição que o próprio editor mantém, e o avaliador segue sem conhecer `DecimalSeparator`
- `AnimatedInputDisplay` recebe `cursorPosition`, `cursorColor` e `onCharTap` e renderiza o cursor (`BlinkingCursor`) entre os widgets de caractere; o diff que decide qual caractere anima (pop-in, roll ou estático) é o helper puro `CharSlotDiffer` (`lib/ui/calculator/char_slot_differ.dart`, Etapa 22), testável sem árvore de widgets — o widget fica só com layout, animação e scroll
- `TimelineDisplay` envolve o display em `GestureDetector.onHorizontalDragEnd` para o swipe

## Atalhos de Teclado

A calculadora é totalmente operável por teclado físico. Cada tecla chama o **mesmo método** do `CalculatorViewModel` usado pelo keypad virtual — não existe caminho paralelo de despacho, então a fila de toques (ver *Fila de Toques*) continua garantindo ordem e ausência de perda.

| Tecla | Ação | Método do `CalculatorViewModel` |
|-------|------|---------------------------------|
| `0`–`9`, `Numpad 0`–`9` | Dígito | `inputDigit` |
| `.`, `,`, `Numpad .` | Atalho `00` | `inputDoubleZero` |
| `+`, `Numpad +` | Soma | `setOperator('+')` |
| `-`, `Numpad -` | Subtração | `setOperator('−')` |
| `*`, `x`, `X`, `Numpad *` | Multiplicação | `setOperator('×')` |
| `/`, `Numpad /` | Divisão | `setOperator('÷')` |
| `Enter`, `=`, `Numpad Enter`, `Numpad =` | Avaliar | `equals` |
| `Backspace` | Apagar último dígito/token | `backspace` |
| `Esc`, `Delete` | Limpar tudo | `clear` |
| `%` | Porcentagem literal | `applyPercentage` |
| `(`, `)` | Parêntese inteligente (toggle) | `inputParenthesis` |
| `←`, `→` | Mover cursor | `moveCursorLeft` / `moveCursorRight` |
| `Ctrl+C` / `Cmd+C` | Copiar resultado | `copyResult` |
| `Ctrl+V` / `Cmd+V` | Colar | `pasteFromClipboard` |

### Decisões de mapeamento

| Decisão | Motivo |
|---------|--------|
| `.` e `,` → `00` | Add2 não tem ponto literal (o separador decimal é implícito). Completar os centavos é o uso natural dessas teclas (`1` + `.` → `1.00`) |
| `000` sem tecla dedicada | Não há tecla física convencional para o atalho; use `00` seguido de `0` |
| `x` e `X` → `×` | Convenção de calculadoras; `Ctrl+X` continua sendo ignorado (não é interpretado como multiplicação) |
| `Ctrl/Cmd+C` copia o **resultado** | A expressão completa e o histórico da sessão continuam disponíveis no menu de contexto (toque longo ou clique direito) |
| `Backspace` fica sem glow | O botão `⌫` está na barra de ícones, não no keypad — não existe `CalculatorButton` correspondente para acender |

### Resolução das teclas

`KeyboardShortcuts.resolve` (em `lib/ui/calculator/keyboard_shortcuts.dart`) é uma função pura que traduz `(logicalKey, character, modificadores)` em um `CalculatorKeyCommand`, em três camadas:

| Ordem | Camada | Cobre |
|-------|--------|-------|
| 1 | Combinações com `Ctrl`/`Cmd` | `Ctrl/Cmd+C` e `Ctrl/Cmd+V`. Qualquer outra combinação retorna `null`, para não roubar atalhos do sistema |
| 2 | `LogicalKeyboardKey` nomeada | `Enter`, `Backspace`, `Esc`, `Delete`, setas e todo o bloco numérico — teclas que não produzem caractere confiável |
| 3 | Caractere impresso | `event.character`, com fallback para `LogicalKeyboardKey.keyLabel` |

O caractere é a fonte **primária** da camada 3 porque teclas como `%`, `*`, `(` e `)` dependem de modificadores e do layout: o `logicalKey` reportado varia entre plataformas (Shift+5 pode chegar como `digit5` ou como `percent`), o caractere não.

### Feedback visual e foco

- `KeyFlashController` (`ValueNotifier<KeyFlash?>`) notifica o rótulo acionado; cada `CalculatorButton` cujo `label` coincide reproduz **a mesma** animação do toque (glow LED + flash de fundo), com fade out imediato — não existe "soltar o dedo"
- O campo `sequence` do `KeyFlash` muda a cada acionamento para que a mesma tecla repetida reinicie a animação em vez de ser descartada por igualdade de valor
- `KeyboardShortcutsHandler` envolve a `CalculatorPage` em `Focus(autofocus: true)`, então o app recebe teclas sem clique prévio
- Eventos `KeyRepeatEvent` são aceitos: segurar `Backspace` apaga repetidamente
- `MainActivity.onStart()` desliga o `defaultFocusHighlightEnabled` de toda a hierarquia de views no Android: sem isso, a primeira tecla física tira a janela do touch mode e o sistema desenha seu realce de foco na `FlutterView`, que ocupa a tela inteira (moldura verde no One UI)

## Segurança e Cibersegurança

| Vetor | Risco no contexto | Regra aplicada |
|-------|-------------------|----------------|
| Entrada não confiável (OWASP A03 — Injection) | Texto arbitrário colado da área de transferência chega ao avaliador de expressões | `PasteInputParser` faz allowlist de tokens (dígitos, `+ − × ÷ % ( ) =`); qualquer outro caractere invalida a entrada inteira sem alterar estado |
| Dado inconsistente no histórico | Um resultado colado divergente da expressão seria persistido | O lado direito do `=` é apenas validado; a expressão é sempre recalculada antes de virar linha da timeline |
| Falha parcial de estado | Uma linha inválida no meio de um paste multi-linha deixaria a calculadora híbrida | Todas as linhas são avaliadas antes de qualquer mutação; qualquer falha aborta o paste inteiro |
| Entrada não confiável via teclado | Teclas arbitrárias acionando ações não previstas | `KeyboardShortcuts.resolve` também é allowlist — teclas fora do mapa retornam `null` e o evento é devolvido ao framework (`KeyEventResult.ignored`) |
| Exposição de dados em log | Expressões e resultados podem ser dados financeiros do usuário | Nenhum `print`/log de expressão, resultado ou conteúdo do clipboard |
| Vazamento por clipboard | Copiar histórico expõe a sessão inteira a qualquer app | Cópia sempre explícita (menu de contexto ou `Ctrl/Cmd+C`); nunca automática |
| Menor privilégio | — | A calculadora não faz I/O de rede; persistência restrita ao SQLite local e ao `SharedPreferences` do app |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| `logicalKey` de teclas com modificador varia por plataforma | `%`, `*`, `(`, `)` podem não ser reconhecidos se resolvidos só pelo `logicalKey` | Resolver pelo `character` primeiro; `keyLabel` só como fallback |
| `KeyEventSimulator` não simula `LogicalKeyboardKey.percent`/`parenthesisLeft` sem `physicalKey` explícito | Widget test lança assert no mapa de teclas da plataforma | Nos testes, enviar a tecla base com `character` (`sendKeyEvent(LogicalKeyboardKey.digit5, character: '%')`) |
| `TextField` no mesmo subtree do handler | Digitar no campo dispararia a calculadora também (eventos sobem a cadeia de foco) | `_isTextEditingFocused()` procura `EditableTextState` acima do foco primário e devolve `KeyEventResult.ignored` |
| `FocusNode` do `TextField` está no `Focus` interno do `EditableText` | Comparar `primaryFocus.context.widget is EditableText` nunca dá match | Usar `findAncestorStateOfType<EditableTextState>()` |
| Android desenha o realce de foco padrão fora do touch mode | A primeira tecla física acende uma moldura na borda da tela (a `FlutterView` é a view focada e cobre tudo) | `disableDefaultFocusHighlight(window.decorView)` no `onStart` da `MainActivity` (API 26+; abaixo disso o framework não desenha o realce) |
| `Focus(autofocus: true)` do handler concorre com outros `autofocus` no mesmo escopo | Em testes com `TextField(autofocus: true)` o handler ganha o foco | Dar foco ao campo explicitamente (tap/`requestFocus`) no teste; no app não há `TextField` na árvore da calculadora |
| `AnimationController.value = 0` + `forward()` no glow por teclado | Sem `tapUp`, o LED ficaria aceso para sempre se só ligássemos o valor | `_onKeyFlash` acende e inicia o fade out no mesmo frame |
| Rótulos dos botões duplicados entre keypad e handler | Divergência silenciosa quebra o feedback visual | Rótulos não numéricos são constantes em `CalculatorKeypad` (`clearLabel`, `percentLabel`, `parenthesisLabel`, `equalsLabel`, `doubleZeroLabel`, `tripleZeroLabel`) |
| `_committed` fica obsoleto quando o modo de edição é ativado | Estado derivado calculado sobre ele divergia do texto exibido (`openParenCount` reportava 0 com `(` na tela) | Todo estado derivado de parênteses lê `_editText` quando ele existe |
| Inserir `)` no fim do bloco numérico sem `(` pendente | Gerava `)` órfão (`12.50)`), tornando a expressão inavaliável e a prévia `null` | `_editInsertParenthesis` só fecha com `openParenCount > 0`; caso contrário abre antes do bloco |
| `flushSession()` altera o estado visível (a expressão vira linha da timeline) | Em desktop, chamar no `onHide` faria o cálculo em andamento sumir ao **minimizar** | O `AppLifecycleListener` só é registrado em mobile; em desktop o gatilho é o `WindowCloseHandler` |
| `_saveOrUpdateSession()` era fire-and-forget | O processo podia morrer no meio da escrita, perdendo o `=` recém-pressionado | Devolve `Future<void>` e encadeia toda escrita em `_pendingWrite`, que `flushSession()` aguarda |
| `add` em voo quando chega a 2ª linha da sessão | A linha era marcada como persistida sem nunca ser gravada (`_addInFlight` só bumpava o contador) | O `update` é encadeado no `Future` do `add` e usa o id que ele devolve |
| `clear`/`loadSession`/paste com `add` em voo | O id da sessão antiga era adotado pela sessão nova | `_resetSessionTracking()` incrementa `_sessionGeneration`; o `add` só adota o id se a geração não mudou |
| `InkWell` e `IconButton` ignoram o botão secundário do mouse | Um `onSecondaryTap` colocado neles nunca dispara | Envolver com `GestureDetector`; no display o `GestureDetector` que já trata o toque longo recebe `onSecondaryTapUp` |
| `WidgetTester.tap` usa `kPrimaryButton` e `PointerDeviceKind.touch` por padrão | Um teste de clique direito passaria como toque comum | Passar `buttons: kSecondaryButton` e `kind: PointerDeviceKind.mouse` (import `package:flutter/gestures.dart`) |
