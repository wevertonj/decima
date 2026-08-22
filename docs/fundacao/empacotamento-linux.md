# Empacotamento — Linux

> Suporte ao alvo Linux (GTK): runner customizado, integração com o desktop via `.desktop` + tema `hicolor` e referência de empacotamento (AppImage/Flatpak/Snap).

## Artefatos

| Arquivo | Papel |
|---------|-------|
| `linux/CMakeLists.txt` | `BINARY_NAME=decima`, `APPLICATION_ID=com.wevasoft.decima` (vira o `WM_CLASS` via `g_set_prgname`) |
| `linux/runner/my_application.cc` | Runner GTK — título, tamanho inicial e ausência de `GtkHeaderBar` |
| `linux/packaging/com.wevasoft.decima.desktop` | Entrada de menu (nome, ícone, categorias, `StartupWMClass`) |
| `linux/packaging/icons/hicolor/<N>x<N>/apps/com.wevasoft.decima.png` | Ícone do tema, derivado do master pelo `tool/icon` |
| `linux/packaging/install-desktop-entry.sh` | Instala/remove a entrada e os ícones em `~/.local/share` |
| `build/linux/x64/release/bundle/` | Bundle relocável gerado (**não versionado**) |

## Uso

| Comando | Efeito |
|---------|--------|
| `flutter build linux --release` | Gera o bundle em `build/linux/x64/release/bundle/` |
| `./build/linux/x64/release/bundle/decima` | Executa o bundle |
| `linux/packaging/install-desktop-entry.sh [bundle]` | Publica no menu do usuário apontando para o bundle (padrão: o de release) |
| `linux/packaging/install-desktop-entry.sh --uninstall` | Remove a entrada e os ícones |
| `cd tool/icon && npm run render` | Regenera os PNGs do `hicolor` (e os demais derivados) a partir dos SVGs |

### Dependências de build

| Pacote (Debian/Ubuntu) | Papel |
|------------------------|-------|
| `clang`, `cmake` (≥ 3.13), `ninja-build`, `pkg-config` | Toolchain exigido pelo `flutter build linux` |
| `libgtk-3-dev` | `pkg_check_modules(GTK REQUIRED gtk+-3.0)` no `CMakeLists.txt` |

`flutter doctor` valida os cinco de uma vez em "Linux toolchain".

## Runner GTK — desvios do template

| Desvio | Valor | Motivo |
|--------|-------|--------|
| Sem `GtkHeaderBar` | `gtk_window_set_title(window, "Decima")` | O template cria um header bar quando o WM é o GNOME Shell. Com ele, `TitleBarStyle.hidden` só **esconde o widget** e mantém a decoração do lado do cliente (sombra + margem), o que desloca `getPosition`/`setPosition`. Sem ele, o plugin cai em `gtk_window_set_decorated(FALSE)` e a janela fica sem moldura em qualquer WM |
| Título `Decima` | Era `decima` (nome do pacote) | Aparece no alt-tab e no dock antes de o `window_manager` aplicar as `WindowOptions` |
| Tamanho inicial `360x720` | Era `1280x720` | Mesmo valor de `DesktopWindowConfig.windowSize`. **Obrigatório**, não cosmético: `setResizable(false)` faz o GTK reescrever os geometry hints com o tamanho default, sobrescrevendo o `setSize` das `WindowOptions` |
| `#include <gdk/gdkx.h>` removido | — | Só existia para a heurística de header bar em X11 |

## Ajustes de janela por plataforma

O `lib/` é o mesmo das demais plataformas desktop; os dois desvios abaixo são decididos em runtime por `PlatformInfo.isLinux`.

| Ajuste | Onde | Motivo |
|--------|------|--------|
| `setMaximizable(false)` **não** é chamado | `desktop_window_initializer.dart` | No GTK o plugin implementa isso como `GDK_WINDOW_TYPE_HINT_DIALOG` — a janela vira diálogo, some da barra de tarefas e do alt-tab e deixa de ser minimizável em vários WMs. `setResizable(false)` já impede maximizar |
| Posição `(0,0)` não é gravada | `isWindowPositionStorable` (`ui/core/desktop/window_position.dart`) | No Wayland o cliente não conhece a própria posição e `getPosition()` devolve sempre a origem. Gravar isso reabriria a janela no canto superior esquerdo em vez de centralizada |

## Integração com o desktop

| Campo do `.desktop` | Valor | Papel |
|---------------------|-------|-------|
| `Icon` | `com.wevasoft.decima` | Nome lógico resolvido pelo tema `hicolor` — **não** é caminho de arquivo |
| `StartupWMClass` | `com.wevasoft.decima` | Liga a janela (`WM_CLASS`) à entrada; sem isso o dock mostra ícone genérico e uma segunda entrada ao abrir |
| `Exec` | `decima` | Reescrito para o caminho absoluto do binário pelo `install-desktop-entry.sh` (entre aspas quando o caminho tem espaço ou metacaractere, como a spec exige); AppImage/Flatpak/Snap resolvem via `PATH` |
| `Categories` | `Utility;Calculator;` | `Calculator` exige `Utility` junto, pela spec de menus da freedesktop |

O `flutter_launcher_icons` **não tem suporte a Linux** — a chave `linux:` era ignorada em silêncio. A fonte do ícone é o master (`assets/icon/decima_icon_master.svg`, squircle com transparência), rasterizado pelo `tool/icon` em 16/24/32/48/64/128/256/512, porque os ambientes Linux não aplicam máscara própria — mesma razão do `.ico` do Windows.

## Empacotamento (referência — não implementado)

| Formato | Ponto de partida | Observações |
|---------|------------------|-------------|
| AppImage | `appimagetool` sobre um `AppDir` com o bundle em `usr/bin/`, o `.desktop` e o `icons/hicolor` na raiz do `AppDir` | Menor atrito: arquivo único, sem instalação. Exige `AppRun` apontando para `usr/bin/decima` |
| Flatpak | Manifesto `com.wevasoft.decima.yml` com `org.freedesktop.Platform` + `org.gnome.Sdk` | Sandbox por padrão; o banco cai em `~/.var/app/com.wevasoft.decima/data`. Publicação no Flathub exige AppStream (`metainfo.xml`) |
| Snap | `snapcraft.yaml` com `base: core22` e a extensão `gnome` | A extensão já traz GTK e temas; `confinement: strict` basta (o app não acessa rede nem arquivos do usuário) |
| `.deb`/`.rpm` | `flutter_distributor` ou empacotamento manual | Só compensa com repositório próprio; o bundle já é relocável |

Nos três primeiros o `.desktop` e o `icons/hicolor` de `linux/packaging/` entram como estão, trocando apenas o `Exec`.

## Dados do usuário em runtime

| Caminho | Conteúdo |
|---------|----------|
| `~/.local/share/com.wevasoft.decima/decima.db` | Histórico (SQLite via `sqflite_common_ffi`) |
| `~/.local/share/com.wevasoft.decima/shared_preferences.json` | Tema, separador decimal, idioma e posição da janela |

O diretório vem de `getApplicationSupportDirectory()`: o `path_provider_linux` lê `g_application_get_application_id()`, ou seja o `APPLICATION_ID` do `CMakeLists.txt` — por isso ele é o mesmo nome do `.desktop` e do ícone. Sem esse id ele cairia no nome do executável (`decima`). Sob Flatpak/Snap o caminho muda para o sandbox do formato.

## Segurança e Cibersegurança

| Vetor | Risco | Mitigação adotada |
|-------|-------|-------------------|
| Adulteração do artefato em trânsito (OWASP A08) | Bundle substituído em download não-oficial | Distribuir só via GitHub Releases e publicar o SHA-256, como já é feito no Windows |
| Escalonamento de privilégio (OWASP A01) | Instalação em `/usr` exige root e amplia superfície | `install-desktop-entry.sh` escreve apenas em `$XDG_DATA_HOME`; nunca pede `sudo` |
| Execução de binário arbitrário via `.desktop` | Entrada apontando para caminho gravável por terceiros | O `Exec` é reescrito para o caminho absoluto do bundle escolhido pelo usuário; o script recusa caminho sem binário executável |
| Vazamento de dados na remoção | Histórico permanece após desinstalar | Intencional e documentado; remoção manual em `~/.local/share/com.wevasoft.decima` |
| Injeção de caminho no script de instalação | Caminho com `\|`, `&` ou `\1` seria reinterpretado por um `sed`; espaço quebraria o `Exec` em vários argumentos | `set -euo pipefail` + toda expansão entre aspas; a substituição usa `awk` com o valor passado por variável (nunca como parte do programa) e aplica as aspas/escapes que a spec do Desktop Entry exige |
| Sandbox ausente no bundle solto | App roda com todas as permissões do usuário | Aceito para uso local; Flatpak/Snap são o caminho quando isolamento importar |

## Desenvolvimento & Gotchas

| Gotcha | Impacto | Ação |
|--------|---------|------|
| `setResizable(false)` sobrescreve o `setSize` | Janela abre no tamanho default do runner (era 1280x720) e trava nele — `WM_NORMAL_HINTS` vira min=max=default | Manter `gtk_window_set_default_size` em 360x720, espelhando `DesktopWindowConfig.windowSize` |
| `setMaximizable(false)` no GTK | Vira `_NET_WM_WINDOW_TYPE_DIALOG`: sem barra de tarefas, sem alt-tab, sem minimizar | Já desviado por `PlatformInfo.isLinux`; conferir com `xprop -id <id> _NET_WM_WINDOW_TYPE` |
| `getPosition()` no Wayland | Devolve `(0,0)` sempre — o protocolo não expõe coordenadas globais | A memória de posição só funciona em X11; a origem é descartada na gravação |
| `WSLg` (Weston/XWayland) não move janela por `_NET_WM_MOVERESIZE` | `DragToMoveArea` parece quebrado ao testar sob `GDK_BACKEND=x11` no WSL | Limitação do ambiente, não do app — um GTK puro chamando `gtk_window_begin_move_drag` falha igual. Validar o drag com `GDK_BACKEND=wayland` |
| `WSLg` reporta `_NET_FRAME_EXTENTS` não-zero para janela sem decoração | A posição salva "anda" ~(38,59) para cima/esquerda a cada ciclo fechar-abrir | Quirk do XWayland do Weston; WMs conformes (mutter/kwin) reportam extents zerados quando `_MOTIF_WM_HINTS` desliga a decoração |
| `flutter create --platforms=linux .` num projeto existente | Reescreve `.metadata` derrubando as outras plataformas da lista de migração e mexe no `pubspec.lock` | Conferir `git diff` depois e reverter o que não for do Linux |
| `gtk-update-icon-cache: No theme index file` | Aviso ao instalar em `~/.local/share/icons/hicolor` (sem `index.theme` próprio) | Inofensivo — o GTK mescla o diretório do usuário com o tema do sistema; o script ignora a falha |
| Ícone genérico no dock | `StartupWMClass` fora de sincronia com o `APPLICATION_ID` | Os dois precisam ser `com.wevasoft.decima`; conferir com `xprop -id <id> WM_CLASS` |
| `libEGL warning: DRI3 error` / `failed to get driver name` no WSL | Ruído no stderr, render cai para software | Esperado sem GPU passthrough; não ocorre em desktop com driver nativo |
