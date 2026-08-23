# Decima — Documentação

Documentação centralizada do projeto Decima.

## Estrutura

```
docs/
├── README.md                          # Este arquivo
├── fundacao/
│   ├── arquitetura.md                 # Arquitetura e estrutura de pastas
│   ├── padroes-codigo.md              # Convenções e padrões de código
│   ├── tema-design-system.md          # Tema, cores, layout e animações
│   ├── empacotamento-windows.md       # Instalador .exe (Inno Setup) e bridge WSL→Windows
│   ├── empacotamento-linux.md         # Runner GTK, .desktop + ícone hicolor e AppImage/Flatpak/Snap
│   └── ci-cd.md                       # CI/CD (GitHub Actions), branches, release e distribuição
├── features/
│   ├── calculadora.md                 # Calculadora (conceito Add2, timeline, keypad)
│   ├── historico.md                   # Histórico de operações (SQLite)
│   └── configuracoes.md              # Configurações (tema, separador, idioma)
└── qualidade/
    └── testes.md                      # Estratégia de testes e TDD
```

## Sobre o Projeto

Decima é uma calculadora elegante e minimalista com design inspirado na One UI (Samsung). Utiliza o conceito **Add2** — entrada automática de 2 casas decimais sem pressionar ponto — com suporte a todas as operações básicas e parênteses. A tela principal funciona como uma **timeline** scrollável de cálculos.

### Funcionalidades Principais

- **Calculadora Add2** — Entrada com 2 casas decimais automáticas, operações completas e parênteses
- **Timeline** — Display em formato de timeline com scroll e prévia de resultado em tempo real
- **Histórico** — Persistência local em SQLite, com carregamento de sessões na timeline
- **Temas** — Claro/escuro com 9 opções de seed color
- **Formato de número** — Separador decimal como ponto ou vírgula
- **Internacionalização** — Suporte multi-idioma via ARB

### Stack Tecnológica

- **Framework**: Flutter (Dart 3)
- **Estado**: ChangeNotifier / ValueNotifier
- **Banco de dados**: SQLite (sqflite)
- **DI**: GetIt
- **Testes**: mocktail, flutter_test
- **Internacionalização**: flutter_localizations + arquivos ARB
