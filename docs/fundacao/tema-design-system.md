# Tema e Design System

## Estilo Visual

O design do Decima é inspirado na **One UI (Samsung)**: elegante, escuro por padrão, com superfícies sutilmente elevadas e botões circulares. O visual deve transmitir leveza e sofisticação.

### Características Principais

- **Fundo escuro** com superfícies sutilmente elevadas
- **Botões circulares** com feedback visual suave (LED glow no texto + flash de fundo)
- **Operadores** destacados com a cor `primary` derivada da seed
- **Display** com tipografia grande e limpa, escala adaptativa (48 → 36 → 28px) e fallback multiline
- **Hierarquia visual** clara entre expressão, resultado e operações
- Ícones **solid e rounded** do Material Icons

### O que EVITAR

- Visual rígido do Material Design padrão
- Blocos pesados e bordas agressivas
- Excesso de elevação/sombras

## Temas

### Seed Colors

O app oferece 9 opções de seed color para personalização. Todas as cores do app derivam da seed escolhida via `ColorScheme.fromSeed()`.

Paleta disponível (em `AppColors.seedColors`):

- Blue (`#005CEE`, padrão), Emerald, Orange, Cyan, Pink, Amber, Rose, Slate, Yellow

### Cores de Superfície Customizadas

O `ColorScheme.fromSeed` é sobrescrito com cores de superfície próprias para reforçar a estética One UI:

- **Dark**: background `#181818`, surface `#212121`, surfaceContainer `#2D2D2D`
- **Light**: background `#F4F4F5`, surface `#FFFFFF`, surfaceContainer `#E8E8EA`

### Modos

- `ThemeMode.light` — Tema claro
- `ThemeMode.dark` — Tema escuro
- `ThemeMode.system` — Segue o sistema

### Transição entre Temas

A troca de tema (claro/escuro e seed color) deve ser **animada suavemente**, nunca uma mudança abrupta.

## Layout — Constantes

Todos os valores de spacing, padding e radius são definidos em constantes centralizadas no tema. **Nunca use valores hardcoded**.

```dart
// ✅ Correto
Padding(
  padding: EdgeInsets.all(AppLayout.padding.medium),
  child: child,
)

// ❌ Proibido
Padding(
  padding: EdgeInsets.all(16.0),
  child: child,
)
```

### Estrutura do AppLayout

```dart
class AppLayout {
  static const spacing = AppSpacing();
  static const padding = AppPadding();
  static const radius = AppRadius();
}

class AppSpacing {
  const AppSpacing();
  double get xs => 4.0;
  double get small => 8.0;
  double get medium => 16.0;
  double get large => 24.0;
  double get xl => 32.0;
}
```

## Animações — Regras Obrigatórias

**Toda** mudança visual causada por reatividade ou mudança de estado deve ser animada. Nenhuma transição pode ser "seca" (0ms).

### Widgets Recomendados

- `AnimatedContainer` — Mudanças de cor, tamanho, padding, decoração
- `AnimatedSize` — Expansão/retração de conteúdo
- `AnimatedSwitcher` — Troca de widgets (ex: valor no display)
- `AnimatedOpacity` — Aparecer/desaparecer suavemente
- `Hero` — Transições entre telas

### Curvas de Aceleração

Use curvas orgânicas que transmitam leveza:

| Curva | Uso Recomendado |
|-------|-----------------|
| `Curves.fastOutSlowIn` | Expansões, mudanças de cor |
| `Curves.easeOutQuart` | Transições de display, entrada de conteúdo |
| `Curves.easeInOut` | Transições gerais |

**Evite** `Curves.linear` — transições lineares parecem mecânicas.

### Durações Padrão

- **Rápida** (100-200ms): Feedback de toque, mudança de valor
- **Média** (200-350ms): Expansão, mudança de tema, troca de modo
- **Lenta** (350-500ms): Transições de tela, animações de destaque

### Exemplo — Botão da Calculadora

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 150),
  curve: Curves.fastOutSlowIn,
  decoration: BoxDecoration(
    color: isPressed
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.transparent,
    shape: BoxShape.circle,
  ),
  child: child,
)
```

### Exemplo — Troca de Valor no Display

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOutQuart,
  child: Text(
    displayValue,
    key: ValueKey(displayValue),
    style: Theme.of(context).textTheme.displayLarge,
  ),
)
```

## Tipografia

- **Display principal**: Fonte grande e limpa para o resultado atual
- **Expressão**: Tamanho menor, cor secundária, acima do resultado
- **Botões numéricos**: Tamanho médio, peso regular
- **Botões de operação**: Mesma hierarquia, cor de acento
