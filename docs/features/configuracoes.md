# Configurações

## Visão Geral

Tela de configurações acessada pelo ícone de engrenagem (⚙) na tela principal da calculadora.

## Funcionalidades

### Tema

- **Modo**: Claro, Escuro ou Sistema, selecionado via `SegmentedButton<ThemeModeOption>` com ícones (☀/🌙/🔆)
- **Seed Color**: 9 opções de cor base exibidas como círculos coloridos (40×40) em um `Wrap`. A opção selecionada ganha borda, sombra glow na cor e ícone de check com cor de contraste automática.
- A troca de tema e cor reflete imediatamente no app inteiro com transição animada

### Formato de Número

- **Separador decimal**: `SegmentedButton<DecimalSeparator>` com exemplos visuais: `1,000.00` (ponto) e `1.000,00` (vírgula)
- O separador de milhar se ajusta automaticamente (ponto → vírgula de milhar; vírgula → ponto de milhar)
- Mudança aplicada imediatamente no display da calculadora

### Idioma

- `Wrap` de `ChoiceChip` com 4 opções: Sistema (default), English, Português, Español
- Mudança aplicada imediatamente, refletindo em todo o app via rebuild reativo do `MaterialApp`

## Persistência

As preferências do usuário (modo de tema, seed color index, separador decimal, locale) são armazenadas localmente via `SettingsRepositoryImpl` (SharedPreferences). São carregadas no startup do app antes do `runApp` e restauradas ao reabrir.

O `SettingsViewModel` é registrado como **lazy singleton** no GetIt para que a mesma instância seja escutada pelo `DecimaApp` (raiz) e pela `SettingsPage`, garantindo propagação global das mudanças.

## UI

- Layout em `ListView` com seções separadas por título (em cor `primary`, peso w600)
- AppBar transparente com título centralizado
- Toda mudança reflete imediatamente no app via listener no `SettingsViewModel`
- Animações suaves nas seleções (`AnimatedContainer`, `AnimatedSwitcher`)
