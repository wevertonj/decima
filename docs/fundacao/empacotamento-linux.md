# Empacotamento — Linux

> Suporte ao alvo Linux (GTK): runner customizado, integração com o desktop via `.desktop` + tema `hicolor`, pacote `.deb` (`tool/deb/build_deb.sh`, publicado no GitHub Release pelo CD) e referência dos demais formatos (AppImage/Flatpak/Snap).

## Artefatos

| Arquivo | Papel |
|---------|-------|
| `linux/CMakeLists.txt` | `BINARY_NAME=decima`, `APPLICATION_ID=com.wevasoft.decima` (vira o `WM_CLASS` via `g_set_prgname`) |
| `linux/runner/my_application.cc` | Runner GTK — título, tamanho inicial, ícone da janela e ausência de `GtkHeaderBar` |
| `linux/packaging/com.wevasoft.decima.desktop` | Entrada de menu (nome, ícone, categorias, `StartupWMClass`) |
| `linux/packaging/icons/hicolor/<N>x<N>/apps/com.wevasoft.decima.png` | Ícone do tema, derivado do master pelo `tool/icon` |
| `linux/packaging/install-desktop-entry.sh` | Instala/remove a entrada e os ícones em `~/.local/share` |
| `linux/packaging/com.wevasoft.decima.metainfo.xml` | AppStream (lojas gráficas); `@VERSION@`/`@DATE@` substituídos no empacotamento |
| `tool/deb/build_deb.sh` | Monta o `.deb` a partir do bundle → `dist/decima-<versão>-linux-<arch>.deb` + `.sha256` |
| `build/linux/x64/release/bundle/` | Bundle relocável gerado (**não versionado**) |

## Uso

| Comando | Efeito |
|---------|--------|
| `flutter build linux --release` | Gera o bundle em `build/linux/x64/release/bundle/` |
| `./build/linux/x64/release/bundle/decima` | Executa o bundle |
| `linux/packaging/install-desktop-entry.sh [bundle]` | Publica no menu do usuário apontando para o bundle (padrão: o de release) |
| `linux/packaging/install-desktop-entry.sh --uninstall` | Remove a entrada e os ícones |
| `tool/deb/build_deb.sh` | `flutter build linux --release` + empacota o `.deb` em `dist/` |
| `tool/deb/build_deb.sh --skip-build [--version X.Y.Z]` | Só empacota o bundle existente (é o que o CI usa) |
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
| Ícone da janela definido | `set_application_icon()` | O template não define nenhum, e sem `_NET_WM_ICON` o ambiente cai no ícone genérico. Ver "Como o ícone chega à janela" |
| `#include <gdk/gdkx.h>` removido | — | Só existia para a heurística de header bar em X11 |

## Ajustes de janela por plataforma

O `lib/` é o mesmo das demais plataformas desktop; os dois desvios abaixo são decididos em runtime por `PlatformInfo.isLinux`.

| Ajuste | Onde | Motivo |
|--------|------|--------|
| `setMaximizable(false)` **não** é chamado | `desktop_window_initializer.dart` | No GTK o plugin implementa isso como `GDK_WINDOW_TYPE_HINT_DIALOG` — a janela vira diálogo, some da barra de tarefas e do alt-tab e deixa de ser minimizável em vários WMs. `setResizable(false)` já impede maximizar |
| Posição `(0,0)` não é gravada | `isWindowPositionStorable` (`ui/core/desktop/window_position_validator.dart`) | No Wayland o cliente não conhece a própria posição e `getPosition()` devolve sempre a origem. Gravar isso reabriria a janela no canto superior esquerdo em vez de centralizada |

## Integração com o desktop

| Campo do `.desktop` | Valor | Papel |
|---------------------|-------|-------|
| `Icon` | `com.wevasoft.decima` | Nome lógico resolvido pelo tema `hicolor` — **não** é caminho de arquivo |
| `StartupWMClass` | `com.wevasoft.decima` | Liga a janela (`WM_CLASS`) à entrada; sem isso o dock mostra ícone genérico e uma segunda entrada ao abrir |
| `Exec` | `decima` | Reescrito para o caminho absoluto do binário pelo `install-desktop-entry.sh` (entre aspas quando o caminho tem espaço ou metacaractere, como a spec exige); AppImage/Flatpak/Snap resolvem via `PATH` |
| `Categories` | `Utility;Calculator;` | `Calculator` exige `Utility` junto, pela spec de menus da freedesktop |

O `flutter_launcher_icons` **não tem suporte a Linux** — a chave `linux:` era ignorada em silêncio. A fonte do ícone é o master (`assets/icon/decima_icon_master.svg`, squircle com transparência), rasterizado pelo `tool/icon` em 16/24/32/48/64/128/256/512, porque os ambientes Linux não aplicam máscara própria — mesma razão do `.ico` do Windows.

### Como o ícone chega à janela

O template do Flutter não define ícone nenhum, então `set_application_icon()` no runner faz isso. São dois caminhos, e qual vale depende do backend gráfico:

| Backend | Mecanismo | Requer `.desktop` instalado? |
|---------|-----------|------------------------------|
| X11 | `_NET_WM_ICON`, publicado pelo GTK a partir do tema (`gtk_window_set_default_icon_name`) ou, quando o tema não tem o ícone, do `logo.png` que já viaja no bundle | Não — o fallback do bundle cobre o app rodando solto |
| Wayland | O compositor casa o `app_id` do `xdg_toplevel` (= `APPLICATION_ID`) com o `.desktop` de mesmo nome e lê o `Icon=` dali. O GTK3 não tem protocolo para enviar pixels de ícone | **Sim** |

Por isso o nome do arquivo `com.wevasoft.decima.desktop` precisa ser exatamente o `APPLICATION_ID` — em Wayland é esse casamento, e só ele, que dá ícone à janela.

## Pacote `.deb` (`tool/deb/build_deb.sh`)

Formato de distribuição adotado (Etapa 15.1): `.deb` avulso anexado ao GitHub Release — instalável com `dpkg -i`/duplo clique, sem exigir repositório APT. Empacotamento manual via `dpkg-deb` (sem `flutter_distributor`).

### Layout instalado

| Caminho | Conteúdo |
|---------|----------|
| `/usr/lib/decima/` | Bundle inteiro (`decima`, `lib/`, `data/`) — relocável, `RUNPATH=$ORIGIN/lib` |
| `/usr/bin/decima` | Symlink relativo `../lib/decima/decima` (`/proc/self/exe` resolve o real, então `data/` é encontrado) |
| `/usr/share/applications/com.wevasoft.decima.desktop` | Cópia fiel — `Exec=decima` resolve via `PATH`, sem reescrita |
| `/usr/share/icons/hicolor/<N>x<N>/apps/com.wevasoft.decima.png` | Os 8 tamanhos de `linux/packaging/icons/` |
| `/usr/share/metainfo/com.wevasoft.decima.metainfo.xml` | AppStream com versão/data injetadas |
| `/usr/share/doc/decima/copyright` | Copyright mínimo |

### `DEBIAN/control`

| Campo | Valor | Motivo |
|-------|-------|--------|
| `Package` / `Section` / `Priority` | `decima` / `utils` / `optional` | — |
| `Version` | `X.Y.Z` no release; `X.Y.Z~dev.N` / `X.Y.Z~pr.N` no CI | `~` ordena **antes** da versão final (upgrade dev→stable nunca é downgrade); `-dev.N` não é válido como no zip do Windows |
| `Architecture` | `amd64` (ou `arm64`, por `uname -m`) | — |
| `Depends` | `libgtk-3-0 (>= 3.24), libglib2.0-0 (>= 2.66), libstdc++6, libc6, zlib1g, hicolor-icon-theme` | `libgtk-3-0` puxa o resto da pilha (cairo, pango, gdk-pixbuf, epoxy, fontconfig). **Sem SQLite**: o bundle embute `libsqlite3.so` via native assets do `package:sqlite3`. `hicolor-icon-theme` fornece o `index.theme` sem o qual o GTK não resolve os ícones instalados |
| `Installed-Size` | `du -sk` do staging | Calculado a cada build |

- **Sem scripts de mantenedor**: caches de `.desktop` (`desktop-file-utils`), ícones (`gtk-update-icon-cache`) e AppStream são atualizados por dpkg triggers dos próprios pacotes do sistema
- **Sistemas t64** (Ubuntu 24.04+): os pacotes renomeados (`libgtk-3-0t64` etc.) publicam `Provides: libgtk-3-0 (= versão)` — o `Depends` com os nomes antigos instala em Debian 12, Ubuntu 22.04 **e** 24.04+
- `dpkg-deb --root-owner-group` dispensa `fakeroot`; permissões normalizadas no staging (755 dirs/binário, 644 arquivos)
- A remoção (`dpkg -r decima`) **preserva** `~/.local/share/com.wevasoft.decima` — dado do usuário nunca entra no pacote

## Demais formatos (referência — não implementado)

| Formato | Ponto de partida | Observações |
|---------|------------------|-------------|
| AppImage | `appimagetool` sobre um `AppDir` com o bundle em `usr/bin/`, o `.desktop` e o `icons/hicolor` na raiz do `AppDir` | Menor atrito: arquivo único, sem instalação. Exige `AppRun` apontando para `usr/bin/decima` |
| Flatpak | Manifesto `com.wevasoft.decima.yml` com `org.freedesktop.Platform` + `org.gnome.Sdk` | Sandbox por padrão; o banco cai em `~/.var/app/com.wevasoft.decima/data`. Publicação no Flathub exige AppStream — o `metainfo.xml` já existe |
| Snap | `snapcraft.yaml` com `base: core22` e a extensão `gnome` | A extensão já traz GTK e temas; `confinement: strict` basta (o app não acessa rede nem arquivos do usuário) |
| `.rpm` | Empacotamento manual (`rpmbuild`) espelhando o layout do `.deb` | Mesma árvore FHS; só muda o metadado |

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
| Injeção via `--version` no `build_deb.sh` | Valor entra no `DEBIAN/control` e em `sed` | Validado contra `^[0-9][A-Za-z0-9.+~]*$` antes de qualquer uso; fora disso o script aborta |
| Escalonamento na instalação do `.deb` | Pacote instala em `/usr` como root | Sem scripts de mantenedor (nenhum código roda no `dpkg -i` além do dpkg); conteúdo é só o bundle + arquivos de integração |

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
| Ícone genérico em Wayland sem a entrada instalada | Não há como o GTK3 enviar o ícone pelo protocolo — só o casamento `app_id` ↔ `.desktop` resolve | Rodar `install-desktop-entry.sh` (ou empacotar em AppImage/Flatpak/Snap, que instalam a entrada) |
| `WSLg` mostra o Tux no lugar do ícone | Sob Wayland o Weston do WSLg não faz o lookup `app_id` → `.desktop`; sob X11 ele **compõe** um selo do Tux sobre o ícone real | Em X11 o ícone aparece (com o selo, comportamento do WSLg); conferir o que a janela publica com `xprop -id <id> _NET_WM_ICON` antes de suspeitar do app |
| `libEGL warning: DRI3 error` / `failed to get driver name` no WSL | Ruído no stderr, render cai para software | Esperado sem GPU passthrough; não ocorre em desktop com driver nativo |
| `WSLg` não aplica a escala de DPI do Windows ao GTK | A janela (360×720 lógicos) parece menor que o build Windows na mesma tela — o Windows honra os 125/150% do monitor, o Weston do WSLg renderiza a 100% | Quirk do ambiente, não do app; em desktop Linux real o compositor aplica a escala do display. Ajuste opcional no WSLg via `%USERPROFILE%\.wslgconfig` |
| `build/flutter_assets` é staging compartilhado entre debug e release | Um `flutter run` (debug) deixa `kernel_blob.bin` (~53 MB, JIT) lá e o CMake o copia para o bundle release (AOT, que nunca o lê) — o `.deb` saltava de 8 para 19 MB | `build_deb.sh` remove `kernel_blob.bin`/`*_snapshot_data` no staging; no CI (checkout limpo) o problema não existe |
| Versão com `-dev.N` no `.deb` | `dpkg` rejeita — hífen separa a *Debian revision* | CI usa `~dev.N`/`~pr.N` (`~` ordena antes da final; upgrade para stable nunca é downgrade) |
