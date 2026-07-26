# Fixtures de Colar (Ctrl+V / menu de contexto)

> Strings de teste manual para o fluxo de colar do WevaCalc, com o resultado verificado contra `PasteInputParser` + `CalculatorViewModel`.

Assume **separador decimal = ponto** nas Configurações. Com vírgula configurada, só a formatação do display muda (`1.250,00`) — o parse é independente da preferência.

Como testar: copie a string de qualquer app, foque a calculadora e pressione `Ctrl+V` (ou toque longo no display → **Colar**).

## Números simples

Preenchem o display, sem prévia.

| String | Display |
|--------|---------|
| `1250` | `1,250.00` |
| `12.50` | `12.50` |
| `12.5` | `12.50` |
| `12,50` | `12.50` |
| `1.000,00` | `1,000.00` |
| `1,000.00` | `1,000.00` |
| `1,234,567` | `1,234,567.00` |
| `12,5%` | `12.50%` |

## Expressões em aberto

Preenchem o display e exibem a prévia.

| String | Display | Prévia |
|--------|---------|--------|
| `10 + 5` | `10.00 + 5.00` | `15.00` |
| `50-20` | `50.00 − 20.00` | `30.00` |
| `100 * 3` | `100.00 × 3.00` | `300.00` |
| `100x3` | `100.00 × 3.00` | `300.00` |
| `100/4` | `100.00 ÷ 4.00` | `25.00` |
| `100 + 10%` | `100.00 + 10.00%` | `110.00` |
| `(10 + 5) × 2` | `( 10.00 + 5.00 ) × 2.00` | `30.00` |
| `((10+5)×2)÷3` | `( ( 10.00 + 5.00 ) × 2.00 ) ÷ 3.00` | `10.00` |
| `1.000,00 + 250,50` | `1,000.00 + 250.50` | `1,250.50` |

## Linhas resolvidas (`<expressão> = <resultado>`)

Cada linha com `=` vira uma entrada da timeline; o display recebe o resultado da última linha (estado idêntico ao de pressionar `=`). O resultado colado é **recalculado** a partir da expressão.

| String | Timeline | Display |
|--------|----------|---------|
| `10 + 5 = 15` | `10.00 + 5.00 = 15.00` | `15.00` |
| `10.00 + 5.00 = 15.00` | `10.00 + 5.00 = 15.00` | `15.00` |
| `10 + 5 = 99` | `10.00 + 5.00 = 15.00` | `15.00` |
| `100 + 10% = 110.00` | `100.00 + 10.00% = 110.00` | `110.00` |
| `(10 + 5) × 2 = 30.00` | `( 10.00 + 5.00 ) × 2.00 = 30.00` | `30.00` |
| `1,000.00 + 250.50 = 1,250.50` | `1,000.00 + 250.50 = 1,250.50` | `1,250.50` |

### Múltiplas linhas

| String | Timeline | Display |
|--------|----------|---------|
| `10 + 5 = 15`<br>`20 × 2 = 40` | 2 linhas (`15.00`, `40.00`) | `40.00` |
| `10 + 5 = 15`<br>`7 + 3` | 1 linha (`15.00`) | `7.00 + 3.00` (prévia `10.00`) |

### Round-trip do histórico da sessão

O caso de uso principal: **Copiar histórico** (toque longo no display) produz exatamente esse formato, então colar de volta restaura a sessão. Faça um par de cálculos, copie o histórico, pressione `C` e cole.

## Fronteira — aceitas, resultado contra-intuitivo

Servem justamente para travar a heurística de separadores.

| String | Display | Por quê |
|--------|---------|---------|
| `1.000` | `1,000.00` | separador único com 3 dígitos finais = milhar, não decimal |
| `1.005` | `1,005.00` | mesma regra — **não** é `1.01` |
| `10.999` | `10,999.00` | idem |
| `0,125` | `125.00` | idem (o `0` inicial vira parte do inteiro) |
| `10 5` | `105.00` | todo espaço em branco é removido antes do parse |
| `1,000.567` | `1,000.57` | 3+ casas decimais arredondam half-up |
| `1.000,999` | `1,001.00` | arredondamento com carry para o inteiro |

## Inválidas — devem exibir o snackbar `pasteInvalid`

Sem `=`:

```
not a number
10 +
+ 10
(10 + 5
10 + 5)
()
10 ++ 5
10%%
%50
R$ 1.250,00
1,0009
12.34.56
1250abc
-50
```

Com `=`:

```
10 + 5 =
= 15
10 + 5 = 15 = 15
10 ++ 5 = 15
10 + 5 = 3 × 5
10 ÷ 0 = Error
10 = 5
```

Mais: texto vazio e texto só com espaços. E, em múltiplas linhas, uma linha em aberto **antes** de uma resolvida:

```
7 + 3
10 + 5 = 15
```

### Limitações conscientes

| String | Motivo |
|--------|--------|
| `R$ 1.250,00` | Prefixo de moeda invalida a string inteira — copiar valor de planilha/site com `R$` não cola |
| `-50` | Números negativos não são aceitos (o `−` inicial não tem operando à esquerda) |
| `10 = 5` | Linha resolvida exige operador na expressão, igual à regra do `=` na calculadora — sem isso viraria a linha sem sentido `10.00 = 10.00`, já que o resultado é recalculado |
| `10 ÷ 0 = Error` | O resultado `Error` não é número; divisão por zero não é colável |
| `10 + 5 = 3 × 5` | O lado direito precisa ser um número isolado, não uma expressão |

O `%` no resultado é tolerado (`10 + 5 = 15.00%` cola como `15.00`), porque o lado direito é apenas validado como número — nunca usado.

## Segurança e Cibersegurança

| Vetor | Risco no contexto | Regra aplicada |
|-------|-------------------|----------------|
| Injeção via clipboard (OWASP A03) | Texto arbitrário de outro app chega ao avaliador de expressões | `PasteInputParser` é allowlist de tokens (dígitos, `+ − × ÷ % ( ) =`); qualquer outro caractere invalida a entrada inteira **sem alterar o estado** |
| Dado inconsistente no histórico | Resultado colado divergente da expressão seria persistido | O resultado à direita do `=` é apenas validado; a expressão é sempre recalculada antes de virar linha da timeline |
| Falha parcial | Uma linha inválida no meio deixaria a calculadora em estado híbrido | Todas as linhas são avaliadas **antes** de qualquer mutação de estado; qualquer falha aborta o paste inteiro |
| Perda silenciosa de dados | Colar substitui a sessão em andamento | `_saveOrUpdateSession()` roda antes do reset, preservando o trabalho pendente no histórico |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| Espaços em branco são removidos antes do parse | `10 5` cola como `105.00`, não como erro | Comportamento intencional (tolerância a texto copiado com espaços); documentado aqui |
| Heurística de separador único | `1.005` → `1,005.00`, não `1.01` | Regra: 1 ou 2 dígitos após o separador = decimal; 3 dígitos = milhar |
| Linha em aberto só pode ser a última | `7 + 3` antes de uma linha com `=` é rejeitado | Evita ambiguidade de ordem entre timeline e input |
| Resultado da última linha entra com `_shouldResetOnInput` | O próximo dígito **substitui** o valor em vez de concatenar | Igual ao estado pós-`=` |
| Linhas coladas não são persistidas na hora | Fechar o app após colar perde as linhas | Elas entram em `_sessionLines` e são gravadas no próximo `=` ou `C` |
| Formatação depende da preferência de separador | O mesmo texto colado exibe `1,250.00` ou `1.250,00` | Parse é independente da preferência; só o display muda |
