#!/usr/bin/env bash
#
# Gera o pacote .deb do Decima a partir do bundle Linux.
#
# Layout FHS: o bundle inteiro vai para /usr/lib/decima (ele é relocável e a
# resolução de assets/ícone usa /proc/self/exe), com symlink em /usr/bin.
# O .desktop e os ícones hicolor entram como estão em linux/packaging/ — o
# Exec=decima resolve via PATH, sem reescrita. Caches de menu/ícones/AppStream
# são atualizados pelos dpkg triggers dos pacotes do sistema: nenhum script de
# mantenedor é necessário.
#
# Uso:
#   tool/deb/build_deb.sh                          # build + empacota
#   tool/deb/build_deb.sh --skip-build             # só empacota o bundle atual
#   tool/deb/build_deb.sh --version 1.2.3~dev.4    # sobrescreve a versão
#
# Sem SQLite no Depends de propósito: o bundle embute libsqlite3.so via
# native assets do package:sqlite3 (ver docs/fundacao/empacotamento-linux.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGING_DIR="$REPO_ROOT/linux/packaging"
APP_ID='com.wevasoft.decima'

DO_BUILD=1
VERSION=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) DO_BUILD=0 ;;
    --version)
      shift
      VERSION="${1:-}"
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

step() { printf '\n\033[1;33m▶ %s\033[0m\n' "$1"; }

# --- Versão (pubspec é a fonte da verdade; --version sobrescreve) ------------
if [[ -z "$VERSION" ]]; then
  RAW_VERSION="$(grep -m1 '^version:' "$REPO_ROOT/pubspec.yaml" | tr -d ' \r' | cut -d: -f2)"
  VERSION="${RAW_VERSION%%+*}"
fi
# Versão Debian válida e sem metacaracteres — ela entra no control e em sed.
if [[ ! "$VERSION" =~ ^[0-9][A-Za-z0-9.+~]*$ ]]; then
  echo "ERRO: versão inválida para .deb: '$VERSION'" >&2
  exit 1
fi

# --- Arquitetura --------------------------------------------------------------
case "$(uname -m)" in
  x86_64) FLUTTER_ARCH=x64 DEB_ARCH=amd64 ;;
  aarch64) FLUTTER_ARCH=arm64 DEB_ARCH=arm64 ;;
  *) echo "ERRO: arquitetura sem suporte: $(uname -m)" >&2; exit 1 ;;
esac
BUNDLE_DIR="$REPO_ROOT/build/linux/$FLUTTER_ARCH/release/bundle"
DEB_NAME="decima-${VERSION}-linux-${DEB_ARCH}.deb"
step "Decima ${VERSION} (${DEB_ARCH})"

# --- Build --------------------------------------------------------------------
if [[ $DO_BUILD -eq 1 ]]; then
  FLUTTER="${DECIMA_FLUTTER:-}"
  if [[ -z "$FLUTTER" ]]; then
    if command -v fvm >/dev/null && [[ -f "$REPO_ROOT/.fvmrc" ]]; then
      FLUTTER='fvm flutter'
    else
      FLUTTER='flutter'
    fi
  fi
  step "flutter build linux --release"
  (cd "$REPO_ROOT" && $FLUTTER build linux --release)
fi

[[ -x "$BUNDLE_DIR/decima" ]] || {
  echo "ERRO: bundle não encontrado em $BUNDLE_DIR (rode sem --skip-build)." >&2
  exit 1
}

# --- Staging ------------------------------------------------------------------
step "Montando a árvore do pacote"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
PKG="$STAGING/pkg"

install -d "$PKG/usr/lib/decima" "$PKG/usr/bin" \
  "$PKG/usr/share/applications" "$PKG/usr/share/metainfo" \
  "$PKG/usr/share/doc/decima" "$PKG/DEBIAN"

cp -a "$BUNDLE_DIR/." "$PKG/usr/lib/decima/"
# build/flutter_assets é staging compartilhado entre debug e release: um build
# debug anterior deixa lá o kernel_blob.bin (JIT, ~53 MB) e o CMake o copia
# para o bundle release, que é AOT e nunca o lê. Fora do pacote, sempre.
rm -f "$PKG/usr/lib/decima/data/flutter_assets/kernel_blob.bin" \
  "$PKG/usr/lib/decima/data/flutter_assets/vm_snapshot_data" \
  "$PKG/usr/lib/decima/data/flutter_assets/isolate_snapshot_data"
# Permissões canônicas: diretórios 755, arquivos 644, binário 755 — o bundle
# de build pode carregar bits herdados do ambiente.
find "$PKG/usr" -type d -exec chmod 755 {} +
find "$PKG/usr" -type f -exec chmod 644 {} +
chmod 755 "$PKG/usr/lib/decima/decima"

ln -s ../lib/decima/decima "$PKG/usr/bin/decima"

cp "$PACKAGING_DIR/$APP_ID.desktop" "$PKG/usr/share/applications/"
cp -a "$PACKAGING_DIR/icons" "$PKG/usr/share/"
find "$PKG/usr/share/icons" -type d -exec chmod 755 {} +
find "$PKG/usr/share/icons" -type f -exec chmod 644 {} +

sed -e "s/@VERSION@/$VERSION/" -e "s/@DATE@/$(date -u +%F)/" \
  "$PACKAGING_DIR/$APP_ID.metainfo.xml" \
  > "$PKG/usr/share/metainfo/$APP_ID.metainfo.xml"

cat > "$PKG/usr/share/doc/decima/copyright" <<EOF
Decima — Add2 calculator
Copyright (c) $(date -u +%Y) Wevasoft (Weverton J. da Silva)

All rights reserved. Distributed as a convenience package; source available
at https://github.com/wevertonj/decima under the repository's terms.
EOF
chmod 644 "$PKG/usr/share/doc/decima/copyright"

# --- control ------------------------------------------------------------------
# Depends mínimo: libgtk-3-0 puxa o resto da pilha (cairo, pango, gdk-pixbuf,
# epoxy, fontconfig...). Nos sistemas t64 (Ubuntu 24.04+) os nomes antigos
# resolvem pelos Provides: versionados dos pacotes renomeados.
INSTALLED_SIZE="$(du -sk --exclude=DEBIAN "$PKG" | cut -f1)"
cat > "$PKG/DEBIAN/control" <<EOF
Package: decima
Version: $VERSION
Architecture: $DEB_ARCH
Maintainer: Wevasoft <19512397+wevertonj@users.noreply.github.com>
Installed-Size: $INSTALLED_SIZE
Depends: libgtk-3-0 (>= 3.24), libglib2.0-0 (>= 2.66), libstdc++6, libc6, zlib1g, hicolor-icon-theme
Section: utils
Priority: optional
Homepage: https://github.com/wevertonj/decima
Description: Add2 calculator - two decimal places typed automatically
 Decima is an Add2 calculator: every digit typed flows into a fixed
 two-decimal display, the way desktop adding machines work. It keeps a
 session timeline, a persistent history with favorites, literal
 percentages, nested parentheses and full physical-keyboard support.
EOF

# --- Pacote -------------------------------------------------------------------
step "dpkg-deb"
mkdir -p "$REPO_ROOT/dist"
dpkg-deb --build --root-owner-group -Zxz "$PKG" "$REPO_ROOT/dist/$DEB_NAME"

# Hash publicado junto do release: o pacote não é assinado, então o SHA-256 é
# a verificação de integridade disponível para quem baixa — como no Windows.
( cd "$REPO_ROOT/dist" && sha256sum "$DEB_NAME" > "$DEB_NAME.sha256" )

SIZE="$(du -h "$REPO_ROOT/dist/$DEB_NAME" | cut -f1)"
step "Pronto: dist/$DEB_NAME ($SIZE)"
echo "  SHA-256: $(cut -d' ' -f1 "$REPO_ROOT/dist/$DEB_NAME.sha256")"
echo "  Instalar: sudo dpkg -i dist/$DEB_NAME"
