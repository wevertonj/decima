#!/usr/bin/env bash
#
# Gera o instalador Windows (.exe) do Decima a partir do WSL2.
#
# O WSL não compila para Windows: o script sincroniza o repositório para uma
# cópia no filesystem do host, dispara o Flutter e o Inno Setup do Windows via
# interop, e traz o instalador de volta para dist/.
#
# Uso:
#   tool/installer/build_installer.sh                 # clean + build + instalador
#   tool/installer/build_installer.sh --no-clean      # pula o flutter clean
#   tool/installer/build_installer.sh --skip-build    # só reempacota o release atual
#
# Configuração da máquina em tool/installer/local.env (não versionado).
# Veja local.env.example.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/tool/installer"

# shellcheck source=/dev/null
[[ -f "$SCRIPT_DIR/local.env" ]] && source "$SCRIPT_DIR/local.env"

WINBUILD_DIR="${DECIMA_WINBUILD_DIR:-}"
ISCC="${DECIMA_ISCC:-C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe}"
FLUTTER="${DECIMA_FLUTTER:-fvm flutter}"

DO_CLEAN=1
DO_BUILD=1
for arg in "$@"; do
  case "$arg" in
    --no-clean) DO_CLEAN=0 ;;
    --skip-build) DO_BUILD=0; DO_CLEAN=0 ;;
    *) echo "Argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

if [[ -z "$WINBUILD_DIR" ]]; then
  echo "ERRO: defina DECIMA_WINBUILD_DIR (caminho Windows da cópia de build)." >&2
  echo "      Copie tool/installer/local.env.example para local.env e ajuste." >&2
  exit 1
fi

WINBUILD_WSL="$(wslpath -u "$WINBUILD_DIR")"

step() { printf '\n\033[1;33m▶ %s\033[0m\n' "$1"; }

# Executa um comando no host Windows, com cwd na cópia de build.
# O cd para /mnt/c evita o aviso de UNC path do cmd.exe.
run_win() {
  (cd /mnt/c && cmd.exe /c "cd /d $WINBUILD_DIR && $1")
}

# --- Versão (pubspec é a fonte da verdade) -----------------------------------
RAW_VERSION="$(grep -m1 '^version:' "$REPO_ROOT/pubspec.yaml" | tr -d ' \r' | cut -d: -f2)"
APP_VERSION="${RAW_VERSION%%+*}"
BUILD_NUMBER="${RAW_VERSION##*+}"
SETUP_NAME="decima-${APP_VERSION}-windows-x64-setup.exe"
step "Decima ${APP_VERSION} (build ${BUILD_NUMBER})"

# --- Sincronização ------------------------------------------------------------
# Sempre sincroniza, inclusive com --skip-build: o .iss vive no repositório e
# precisa chegar à cópia antes de o ISCC rodar lá.
step "Sincronizando para $WINBUILD_DIR"
mkdir -p "$WINBUILD_WSL"
# .fvmrc e build/ ficam de fora: a cópia tem o próprio pin de SDK e cache.
rsync -a --delete \
  --exclude='.git/' --exclude='build/' --exclude='dist/' \
  --exclude='.dart_tool/' --exclude='.idea/' --exclude='.fvm/' --exclude='.fvmrc' \
  --exclude='windows/flutter/ephemeral/' --exclude='linux/flutter/ephemeral/' \
  --exclude='macos/Flutter/ephemeral/' \
  --exclude='plano/local/' --exclude='node_modules/' \
  "$REPO_ROOT/" "$WINBUILD_WSL/"

# --- Build --------------------------------------------------------------------
if [[ $DO_BUILD -eq 1 ]]; then
  # clean por padrão: sem ele o CMake não copia DLLs novas quando o grafo de
  # plugins/native assets muda, e o Release sai incompleto sem erro visível.
  if [[ $DO_CLEAN -eq 1 ]]; then
    step "flutter clean"
    run_win "$FLUTTER clean"
  fi

  step "flutter build windows --release"
  run_win "$FLUTTER build windows --release"
fi

RELEASE_WSL="$WINBUILD_WSL/build/windows/x64/runner/Release"
[[ -f "$RELEASE_WSL/decima.exe" ]] || {
  echo "ERRO: $RELEASE_WSL/decima.exe não encontrado." >&2
  exit 1
}

# --- Runtime C++ app-local ----------------------------------------------------
# Sem estes DLLs o app exige o "Visual C++ Redistributable" instalado na máquina
# do usuário. Copiados para junto do exe, a instalação não tem pré-requisito.
step "Empacotando runtime C++ (app-local)"
CRT_DIR="$(ls -d /mnt/c/Program\ Files*/Microsoft\ Visual\ Studio/*/*/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT \
  2>/dev/null | sort -V | tail -1)"
if [[ -n "$CRT_DIR" ]]; then
  cp -f "$CRT_DIR"/*.dll "$RELEASE_WSL/"
  echo "  $(basename "$(dirname "$(dirname "$CRT_DIR")")") → $(ls "$CRT_DIR"/*.dll | wc -l) DLLs"
else
  echo "  AVISO: redist do MSVC não encontrado — o instalador vai exigir o VC++ Redistributable." >&2
fi

# --- Instalador ---------------------------------------------------------------
step "Compilando instalador (Inno Setup)"
# A interop do WSL reescreve aspas duplas ao repassar para o cmd.exe, e o
# caminho do ISCC tem espaços. Solução: nenhuma aspa — o diretório entra no
# PATH da própria linha e o exe é chamado pelo nome.
# Sem /Q de propósito: o progresso por arquivo é o que denuncia se a
# compressão travar em um arquivo específico (ver Etapa 14.1 no plano).
run_win "set PATH=%PATH%;${ISCC%\\*}& ${ISCC##*\\} /DAppVersion=$APP_VERSION tool\\installer\\decima.iss"

mkdir -p "$REPO_ROOT/dist"
cp -f "$WINBUILD_WSL/dist/$SETUP_NAME" "$REPO_ROOT/dist/$SETUP_NAME"

# Hash publicado junto do release: o instalador não é assinado, então o SHA-256
# é a única verificação de integridade disponível para quem baixa.
( cd "$REPO_ROOT/dist" && sha256sum "$SETUP_NAME" > "$SETUP_NAME.sha256" )

SIZE="$(du -h "$REPO_ROOT/dist/$SETUP_NAME" | cut -f1)"
step "Pronto: dist/$SETUP_NAME ($SIZE)"
echo "  SHA-256: $(cut -d' ' -f1 "$REPO_ROOT/dist/$SETUP_NAME.sha256")"
echo "  Instalar: powershell.exe -NoProfile -Command \"Start-Process '$(wslpath -w "$REPO_ROOT/dist/$SETUP_NAME")'\""
