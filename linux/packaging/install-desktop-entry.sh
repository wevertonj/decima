#!/usr/bin/env bash
# Instala o Decima no menu de aplicativos do usuário atual (sem root),
# apontando para um bundle já compilado por `flutter build linux`.
#
#   ./linux/packaging/install-desktop-entry.sh [caminho-do-bundle]
#   ./linux/packaging/install-desktop-entry.sh --uninstall
#
# O bundle é relocável, então nada é copiado: a entrada guarda o caminho
# absoluto do binário. Mover o bundle exige rodar o script de novo.
set -euo pipefail

APP_ID="com.wevasoft.decima"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SOURCE_DIR/../.." && pwd)"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_FILE="$DATA_HOME/applications/$APP_ID.desktop"
ICON_ROOT="$DATA_HOME/icons/hicolor"

refresh_caches() {
  # Falhar aqui não invalida a instalação: sem os caches o ambiente ainda
  # encontra a entrada, só demora mais a atualizar o menu.
  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$DATA_HOME/applications" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 &&
    gtk-update-icon-cache --force --quiet "$ICON_ROOT" || true
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$DESKTOP_FILE"
  find "$ICON_ROOT" -name "$APP_ID.png" -delete 2>/dev/null || true
  refresh_caches
  echo "removido: $DESKTOP_FILE"
  exit 0
fi

BUNDLE_DIR="${1:-$PROJECT_ROOT/build/linux/x64/release/bundle}"
BINARY="$BUNDLE_DIR/decima"

if [[ ! -x "$BINARY" ]]; then
  echo "binário não encontrado em $BINARY" >&2
  echo "compile antes com: flutter build linux --release" >&2
  exit 1
fi

# A spec do Desktop Entry exige aspas duplas em argumento com espaço, e
# escape de `"`, `$`, backtick e barra invertida dentro delas. Sem isso um
# caminho com espaço faria o ambiente quebrar o Exec em vários argumentos.
exec_value="$BINARY"
if [[ "$exec_value" == *[[:space:]\"\$\`\\]* ]]; then
  escaped="${exec_value//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  escaped="${escaped//\$/\\\$}"
  escaped="${escaped//\`/\\\`}"
  exec_value="\"$escaped\""
fi

mkdir -p "$(dirname "$DESKTOP_FILE")"
# `awk` em vez de `sed`: o valor entra por variável, sem virar parte do
# programa — caminho com `|`, `&` ou `\1` não é reinterpretado.
awk -v value="$exec_value" \
  '$0 == "Exec=decima" { print "Exec=" value; next } { print }' \
  "$SOURCE_DIR/$APP_ID.desktop" >"$DESKTOP_FILE"
chmod 644 "$DESKTOP_FILE"

while IFS= read -r icon; do
  size_dir="$(basename "$(dirname "$(dirname "$icon")")")"
  install -Dm644 "$icon" "$ICON_ROOT/$size_dir/apps/$APP_ID.png"
done < <(find "$SOURCE_DIR/icons/hicolor" -name "$APP_ID.png")

refresh_caches

echo "instalado: $DESKTOP_FILE"
echo "binário:   $BINARY"
