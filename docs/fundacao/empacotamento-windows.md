# Empacotamento — Windows

> Geração do instalador `.exe` do Decima para Windows x64 com Inno Setup, a partir do WSL2 via toolchain do host.

## Artefatos

| Arquivo | Papel |
|---------|-------|
| `tool/installer/decima.iss` | Script do Inno Setup — metadados, layout de instalação, atalhos, idiomas |
| `tool/installer/build_installer.sh` | Orquestra sync → build → runtime C++ → `ISCC.exe` → `dist/` |
| `tool/installer/local.env.example` | Modelo de configuração da máquina |
| `tool/installer/local.env` | Configuração real (**não versionado**) |
| `dist/decima-<versão>-windows-x64-setup.exe` | Instalador gerado (**não versionado**) |

## Uso

| Comando | Efeito |
|---------|--------|
| `tool/installer/build_installer.sh` | `flutter clean` + build release + instalador (fluxo canônico) |
| `tool/installer/build_installer.sh --no-clean` | Pula o `clean` — iteração rápida quando o grafo de plugins não mudou |
| `tool/installer/build_installer.sh --skip-build` | Só reempacota o `Release` já existente |

A versão vem do `pubspec.yaml` (`version: 0.5.0+5` → instalador `0.5.0`) e é injetada no `.iss` via `/DAppVersion`.

## Configuração (`local.env`)

| Variável | Valor esperado |
|----------|----------------|
| `DECIMA_WINBUILD_DIR` | Caminho **Windows** da cópia de build (ex.: `C:\Users\<user>\decima-winbuild`) |
| `DECIMA_ISCC` | Caminho do `ISCC.exe` (Inno Setup 6.3+; recomendada a última 6.x via `winget`) |
| `DECIMA_FLUTTER` | `fvm flutter` ou `flutter`, conforme o SDK do host |

## Decisões de instalação

| Decisão | Valor | Motivo |
|---------|-------|--------|
| Escopo | Por usuário (`PrivilegesRequired=lowest`) | Instala em `%LOCALAPPDATA%\Programs\Decima` sem prompt de UAC. `PrivilegesRequiredOverridesAllowed=commandline` mantém `/ALLUSERS` disponível **sem** impor a tela de escolha de modo (que o valor `dialog` traria) |
| Runtime C++ | DLLs app-local ao lado do `decima.exe` | Elimina o pré-requisito "Visual C++ Redistributable" na máquina do usuário |
| Wizard | Welcome/Ready/Group desabilitados | Menor atrito: idioma (só se o sistema não casar) → tarefas → instalar → concluir |
| Idiomas | `BrazilianPortuguese` + `Default` (inglês) | Segue o locale do sistema |
| Atalho de desktop | Tarefa opcional, desmarcada | Menu Iniciar é sempre criado |
| Upgrade | `AppId` fixo + `CloseApplications=yes` | Reinstalar substitui in-place; o app aberto é fechado antes de sobrescrever |
| Dados do usuário | Preservados na desinstalação | `%APPDATA%\Wevasoft\Decima` (banco + preferências) sobrevive a reinstalações |
| Arquitetura | `x64compatible`, `MinVersion=10.0` | Alvo x64 do Flutter desktop; instala também em Windows ARM64 com emulação x64 (`x64` puro está deprecado no Inno 6.3+) |
| Compressão | `lzma2/normal` + `LZMANumBlockThreads=4` + `LZMAUseSeparateProcess=yes` | Blocos comprimidos em paralelo pelo `islzma64.exe`, fora do processo 32-bit do compilador — 33 MB → 12 MB em ~3 s |

## Conteúdo do bundle

| Item | Origem |
|------|--------|
| `decima.exe` | Runner nativo (`windows/runner`, nome em `BINARY_NAME`) |
| `flutter_windows.dll` | Engine |
| `window_manager_plugin.dll`, `screen_retriever_windows_plugin.dll` | Plugins de janela (Etapa 14) |
| `sqlite3.dll`, `dartjni.dll` | Native assets resolvidos no build |
| `data\` | `icudtl.dat`, `flutter_assets\` (branding, ARBs compilados), `app.so` (AOT) |
| `msvcp140*.dll`, `vcruntime140*.dll` | Redist do MSVC copiado pelo `build_installer.sh` |

## Segurança e Cibersegurança

| Vetor | Risco | Mitigação adotada |
|-------|-------|-------------------|
| Binário não assinado | SmartScreen exibe "O Windows protegeu o seu PC"; usuário precisa de "Mais informações → Executar assim mesmo" | Sem solução gratuita — certificado OV de code signing exige token HSM. Documentar o aviso no README e publicar hash SHA-256 junto do release |
| Adulteração do artefato em trânsito | Instalador substituído em download não-oficial | Distribuir apenas via GitHub Releases e divulgar o SHA-256 do `.exe` |
| Escalonamento de privilégio (OWASP A01) | Instalador escrevendo em `Program Files` exige admin e amplia superfície | Instalação por usuário como padrão — menor privilégio, sem UAC |
| DLL hijacking | DLL maliciosa em diretório gravável carregada antes da legítima | Todas as DLLs ficam ao lado do exe em diretório do próprio usuário; **nunca** adicionar o diretório de instalação ao `PATH` |
| Vazamento de dados na desinstalação | Histórico de cálculos permanece após remover o app | Comportamento intencional e documentado; remoção manual em `%APPDATA%\Wevasoft\Decima` |
| Segredos no repositório | Caminhos/credenciais de máquina versionados | `local.env` e `dist/` no `.gitignore`; apenas `local.env.example` é versionado |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| Aspas duplas na interop WSL→`cmd.exe` | Argumentos com espaço chegam escapados (`\"C:\...\"`) e o cmd não reconhece o comando | Não usar aspas: o script põe o diretório do `ISCC.exe` no `PATH` da própria linha |
| Build direto em `\\wsl.localhost\...` | Quebra nos symlinks de plugin e contamina o `.dart_tool` do WSL | Sempre buildar na cópia em `DECIMA_WINBUILD_DIR` |
| CMake stale após mudança no grafo de plugins/native assets | `Release` sai sem as DLLs novas, sem erro visível (o Debug funciona e confunde o diagnóstico) | `flutter clean` — é o padrão do script; `--no-clean` só quando nada mudou nas dependências |
| Ausência do redist do MSVC no host | Script avisa e segue; o instalador passa a exigir o VC++ Redistributable do usuário | Instalar o workload C++ do Visual Studio 2022 |
| Inno Setup 6.2.2 crashava em toda compilação (`ISPP.dll`, `0xc0000005`, "Runtime error 216") | O erro abre um **diálogo modal invisível** quando o ISCC roda via interop; no pipe do console o processo degenera em spin de 100% de CPU — parece compressão infinita, mas nunca leu um byte do payload | Atualizar o Inno (`winget upgrade JRSoftware.InnoSetup`); com 6.7.3 os 33 MB compilam em ~3 s |
| ISCC silencioso após o banner | Indistinguível de compressão longa quando se usa `/Q` | O script chama o ISCC **sem `/Q`** — o `Compressing: <arquivo>` por item denuncia travamento. Se silenciar: checar I/O do processo (`Win32_Process.ReadTransferCount`), `MainWindowTitle` (diálogo oculto) e o log `Application Error` do Windows |
| `AppId` alterado | Novas versões instalam lado a lado em vez de atualizar | O GUID em `decima.iss` é imutável |
| `.fvmrc` sincronizado por engano | Sobrescreve o pin de SDK da cópia de build | Excluído no `rsync` (junto de `build/`, `.dart_tool/`, `dist/`, `plano/local/`) |
| Versão do Inno < 6.3 | `x64compatible` e diretivas modernas falham | Requer 6.3+; na dúvida, última 6.x via `winget` |
