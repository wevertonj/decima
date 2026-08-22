---
applyTo: '**'
---

# Guia de Desenvolvimento — WevaCalc

## Linguagem e Comunicação
- Sempre responda em português brasileiro
- Use `context.l10n.*` para todas as strings visíveis ao usuário (arquivos ARB)
- Nunca use texto hardcoded em widgets
- **Sempre rode** o `flutter analyze` após concluir qualquer modificação no código
- **Em ajustes maiores, novas features ou refatorações**, sempre rode o `flutter test` para garantir que o sistema se mantém íntegro
- Use Icons solid e rounded do Material Icons

## Sobre o Projeto

WevaCalc é uma calculadora elegante e minimalista que utiliza o conceito **Add2** — entrada automática de 2 casas decimais sem pressionar ponto. Suporta todas as operações básicas.

- **Calculadora Add2**: Entrada com 2 casas decimais automáticas (digitar `1250` = `12.50`), suporte a +, −, ×, ÷, % e botão `000`
- **Timeline**: Display em formato de timeline scrollável — linha atual em branco, prévia do resultado em cinza, cálculos anteriores acima
- **Histórico**: Operações persistidas em SQLite. Ao carregar uma entrada, a timeline restaura a sessão permitindo continuar o cálculo
- **Temas**: Suporte a tema claro/escuro com 9 opções de seed color para personalização
- **Formato de número**: Opção de exibir separador decimal como ponto ou vírgula
- **Internacionalização**: Suporte multi-idioma via arquivos ARB

## TDD — Test-Driven Development (Regra Obrigatória)

Este projeto segue rigorosamente o fluxo TDD:

1. **Red**: Escreva o teste ANTES da implementação. O teste deve falhar.
2. **Green**: Implemente o mínimo necessário para o teste passar.
3. **Refactor**: Refatore o código mantendo os testes verdes.

> **Regra crítica**: Se a implementação quebrar testes existentes de outros módulos, **corrigir a implementação, nunca os testes**. Não é permitido reescrever, deletar ou alterar testes/features que já funcionam para acomodar código novo.

- **Antes de implementar qualquer feature**, escreva os testes correspondentes
- **Antes de dar uma tarefa como concluída**, rode `flutter test` e garanta 100% verde
- Testes são cidadãos de primeira classe neste projeto

## Gerenciamento de Documentação
- **Sempre consulte** o diretório `/docs` antes de implementar novos recursos ou padrões
- **Atualize a documentação** ao fazer mudanças arquiteturais ou adicionar novos padrões
- **Atualize quando**:
  - Adicionar novas camadas, serviços ou padrões
  - Modificar processos de build/deploy
  - Alterar configuração ou setup do ambiente
  - Implementar novas ferramentas ou workflows de desenvolvimento
  - Adicionar ou alterar padrões de teste
- Mantenha a documentação sincronizada com as mudanças no código
- Use `/docs` como fonte única da verdade para decisões arquiteturais e práticas de desenvolvimento
- **Estilo de Documentação**: Escreva como se os recursos tivessem sido implementados corretamente desde o início
  - Foque em COMO o sistema funciona, não em como foi corrigido
  - Evite comparações "antes/depois" ou seções "problema resolvido"
  - Mantenha o texto conciso e direto
  - Documente o estado atual, não a evolução

## Design System e Animações (Estilo Premium/One UI)
- **Estilo Visual**: O app possui um design dark e elegante, fortemente inspirado na **One UI (Samsung)**, com tons escuros, acentos em amarelo/dourado e botões circulares. **EVITE** o visual rígido, blocos pesados e padrões estritos do Material Design padrão.
- **Tipografia**: Display de resultados com fonte grande e limpa. Operações e valores devem ter hierarquia visual clara.
- **Botões**: Circulares com feedback visual suave ao toque. Operadores destacados com cor de acento (amarelo/dourado).
- **Animações Suaves OBRIGATÓRIAS**: Sempre que houver alteração visual por reatividade ou mudança de estado (itens que expandem, retraem, aparecem, desaparecem ou mudam de cor), **obrigatoriamente** aplique animações fluidas. Nenhuma mudança de UI deve ser "seca" (0ms).
- **Ferramentas Recomendadas**: Utilize intensamente `AnimatedContainer`, `AnimatedSize`, `AnimatedSwitcher`, `AnimatedOpacity` e `Hero` transitions.
- **Curvas de Aceleração**: Utilize curvas de transição orgânicas que passem a sensação de leveza e polimento (ex: `Curves.fastOutSlowIn`, `Curves.easeOutQuart`, ou simulações de mola/spring). Evite transições estritamente lineares.
- **Transição entre temas**: A troca de tema (claro/escuro e seed color) deve ser animada suavemente.

## Visão Geral da Arquitetura

Este é um app Flutter seguindo princípios **SOLID** com uma arquitetura limpa e simples:

```
lib/
├── config/        # Configuração do app, DI, rotas, tema
├── data/          # Camada de dados: repositories, database, models
├── domain/        # Regras de negócio: entities, enums
├── ui/            # Camada visual: pages, widgets, view models
└── utils/         # Utilitários: extensions, formatters, l10n
```

**Regra simples:**
- Acessa banco de dados? → `data/`
- É visual? → `ui/`
- É regra de negócio? → `domain/`
- Todo o resto? → `utils/`

## Principais Padrões e Convenções

### Princípios SOLID
- **S** — Single Responsibility: Cada classe tem uma única responsabilidade
- **O** — Open/Closed: Aberto para extensão, fechado para modificação
- **L** — Liskov Substitution: Subtipos devem ser substituíveis por seus tipos base
- **I** — Interface Segregation: Interfaces específicas são melhores que interfaces genéricas
- **D** — Dependency Inversion: Dependa de abstrações, não de implementações

### Injeção de Dependência
- Use um service locator (GetIt) configurado em `lib/config/dependencies.dart`
- Registre todos os services, repositories e demais dependências lá

### Camada de Dados (`lib/data/`)
- **Database**: SQLite local para armazenar histórico de operações
- **Repositories**: Interface + Implementação — encapsulam toda lógica de acesso a dados
- **Models**: Classes para serialização/deserialização do banco de dados

### Camada de Domínio (`lib/domain/`)
- **Entities**: Classes Dart puras representando conceitos do domínio (Calculation, HistoryEntry, etc.)
- **Enums**: Tipos de operação, etc.

### Camada de UI (`lib/ui/`)
- **Pages**: Telas do app (Calculadora, Histórico, Configurações)
- **Widgets**: Componentes reutilizáveis (botões da calculadora, display, etc.)
- **View Models**: Gerenciamento de estado com ChangeNotifier/ValueNotifier

### Utils (`lib/utils/`)
- **Extensions**: Extensões de String, num, Context, etc.
- **Formatters**: Formatadores de número, moeda, etc.
- **l10n**: Arquivos ARB para internacionalização

### Estilo de Código
- **Return Statement**: Sempre deixe uma linha em branco antes do `return`, exceto quando for a única linha
- **Imports**: Organize na ordem (Dart SDK → Flutter → Packages → Project)
- **Naming**: Inglês para código, português para comentários

### Testes (Fluxo e Padrões Obrigatórios)

> **Regra crítica**: Se a implementação quebrar testes existentes de outros módulos, **corrigir a implementação, nunca os testes**. Não é permitido reescrever, deletar ou alterar testes/features que já funcionam para acomodar código novo.

- **Fluxo TDD**: (1) Escreva o teste; (2) Veja falhar; (3) Implemente o mínimo; (4) Veja passar; (5) Refatore.
- **Estrutura e Nomenclatura**: Organize por tipo (unit, widget) em `test/`. Descrições sempre em inglês começando com "should".
- **Padrão**: AAA (Arrange, Act, Assert).
- **Mocking (`mocktail`)**: Centralize mocks em `test/mocks/`. Registre *fallback values* no `setUpAll` para tipos usados com `any()`.
- **Fixtures**: Centralize dados de teste reutilizáveis em `test/fixtures/`.
- **Antes de implementar código**, escreva os testes correspondentes
- **Ao concluir**, rode `flutter test` e corrija qualquer falha antes de considerar a tarefa completa

### Tema e Design System
- **Colors**: Use `ColorScheme.fromSeed()` com 9 opções de seed color para o usuário escolher
- **Modo**: Suporte a tema claro e escuro (`ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`)
- **Spacing/Padding/Radius**: Defina constantes de layout no tema — nunca use valores hardcoded
- Definição do tema em `lib/ui/core/theme/` ou `lib/config/theme/`
- Nunca use valores de layout hardcoded

### Banco de Dados Local (SQLite)
- Use o pacote `sqflite` para persistência local
- Armazene todo o histórico de cálculos
- Migrations versionadas para evolução do schema
- Repository pattern para abstrair o acesso ao banco

### Internacionalização
- Todo texto via arquivos ARB em `utils/l10n/` ou `lib/l10n/`
- Acesse via `context.l10n.*`
- Nunca use strings hardcoded na UI

### Navegação
- Configuração centralizada de rotas
- Tela principal: Calculadora (timeline) com ícones para Histórico (⏱) e Configurações (⚙)

## Princípios Críticos

### NUNCA Faça
- ❌ Use o estilo padrão e rígido do Material Design (use o visual premium/One UI)
- ❌ Deixe mudanças de estado na UI sem animações (use `AnimatedContainer`, `AnimatedSize`, etc.)
- ❌ Texto hardcoded em widgets (use `context.l10n.*`)
- ❌ Valores de spacing/padding hardcoded (use theme/constantes de layout)
- ❌ Use `print()` para logging
- ❌ Pule a escrita de testes antes da implementação (TDD é obrigatório)
- ❌ Reescreva ou delete testes existentes para acomodar código novo
- ❌ Finalize uma tarefa sem rodar `flutter test`
- ❌ Importe Flutter em View Models (mantenha-os puros)
- ❌ Acesse o banco de dados diretamente da UI (use repositories)

### SEMPRE Faça
- ✅ Aplique animações suaves (curves/springs) em **qualquer** expansão, retração ou mudança de estado na UI
- ✅ Siga TDD: teste primeiro, implemente depois
- ✅ Rode `flutter analyze` após cada modificação e `flutter test` em ajustes maiores
- ✅ Use `context.l10n.*` para todo texto da UI
- ✅ Use constantes de layout do tema para spacing, padding e radius
- ✅ Deixe linha em branco antes do `return` (exceto se for única linha)
- ✅ Atualize a documentação ao alterar a arquitetura
- ✅ Siga o padrão AAA nos testes
- ✅ Registre dependências no service locator (GetIt)
- ✅ Escreva testes para todo código novo
- ✅ Corrija testes quebrados imediatamente — ajustando a implementação, nunca os testes
- ✅ Consulte `/docs` antes de implementar novos recursos

## Referência Rápida

```dart
// ✅ CORRETO — Padrões do Projeto

// Texto UI
Text(context.l10n.calculatorTitle)

// Animação Suave (Estilo Premium One UI)
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.fastOutSlowIn,
  decoration: BoxDecoration(
    color: isPressed
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.transparent,
    shape: BoxShape.circle,
  ),
  child: child,
)

// Transição entre valores no display
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOutQuart,
  child: Text(
    displayValue,
    key: ValueKey(displayValue),
    style: Theme.of(context).textTheme.displayLarge,
  ),
)

// Layout com constantes do tema
Padding(
  padding: EdgeInsets.all(AppLayout.padding.medium),
  child: Column(
    children: [
      SizedBox(height: AppLayout.spacing.small),
    ],
  ),
)

// Entity simples
class Calculation {
  final String expression;
  final String result;
  final DateTime timestamp;

  const Calculation({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}
```

## Referência de Documentação

Consulte estes arquivos quando necessário (use a ferramenta `read_file`):

| Categoria | Documento | Caminho |
|-----------|-----------|---------|
| **Fundação** | README | `docs/README.md` |
| **Fundação** | Arquitetura | `docs/fundacao/arquitetura.md` |
| **Fundação** | Padrões de Código | `docs/fundacao/padroes-codigo.md` |
| **Fundação** | Tema e Design System | `docs/fundacao/tema-design-system.md` |
| **Features** | Calculadora (Add2) | `docs/features/calculadora.md` |
| **Features** | Histórico | `docs/features/historico.md` |
| **Features** | Configurações | `docs/features/configuracoes.md` |
| **Qualidade** | Testes | `docs/qualidade/testes.md` |
