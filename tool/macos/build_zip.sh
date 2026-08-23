#!/usr/bin/env bash
#
# Empacota o Decima.app (macOS) no zip de distribuição.
#
# O `ditto` não é preciosismo: um `zip` comum perde symlinks, bits de execução
# e metadados do bundle — e qualquer um deles invalida a assinatura ad-hoc, que
# é o que faz o .app abrir do outro lado. Pelo mesmo motivo o CI sobe o zip
# pronto como artefato: o upload-artifact do GitHub não preserva permissões e
# destruiria um .app cru.
#
# Uso:
#   tool/macos/build_zip.sh                         # build + empacota
#   tool/macos/build_zip.sh --skip-build            # só empacota o bundle atual
#   tool/macos/build_zip.sh --version 1.2.3-dev.4   # sobrescreve a versão
#
# Assinatura ad-hoc (`CODE_SIGN_IDENTITY = "-"`, default do template): sem
# conta paga do Apple Developer Program não há notarização, então o SHA-256
# publicado no release é a verificação de integridade disponível para quem
# baixa — ver docs/fundacao/empacotamento-macos.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# --- Pré-requisito ------------------------------------------------------------
# `ditto`, `codesign` e o próprio build só existem no macOS.
if [[ "$(uname -s)" != 'Darwin' ]]; then
  echo "ERRO: o empacotamento macOS só roda no macOS (uname: $(uname -s))." >&2
  exit 1
fi

# --- Versão (pubspec é a fonte da verdade; --version sobrescreve) ------------
if [[ -z "$VERSION" ]]; then
  RAW_VERSION="$(grep -m1 '^version:' "$REPO_ROOT/pubspec.yaml" | tr -d ' \r' | cut -d: -f2)"
  VERSION="${RAW_VERSION%%+*}"
fi
# A versão vira nome de arquivo — nada de metacaracteres.
if [[ ! "$VERSION" =~ ^[0-9][A-Za-z0-9.+~-]*$ ]]; then
  echo "ERRO: versão inválida para o zip: '$VERSION'" >&2
  exit 1
fi

# --- Bundle -------------------------------------------------------------------
# PRODUCT_NAME é a fonte do nome do .app (`Decima`, capitalizado desde a
# Etapa 16) — lido do xcconfig para não duplicar a constante aqui.
APP_NAME="$(grep -m1 '^PRODUCT_NAME' "$REPO_ROOT/macos/Runner/Configs/AppInfo.xcconfig" | cut -d= -f2 | tr -d ' \r')"
APP="$REPO_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"
ZIP_NAME="decima-${VERSION}-macos.zip"
step "Decima ${VERSION} (${APP_NAME}.app, universal)"

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
  step "flutter build macos --release"
  (cd "$REPO_ROOT" && $FLUTTER build macos --release)
fi

[[ -d "$APP" ]] || {
  echo "ERRO: bundle não encontrado em $APP (rode sem --skip-build)." >&2
  exit 1
}

# --- Assinatura ---------------------------------------------------------------
# Ad-hoc é assinatura de verdade para fins de integridade: qualquer byte
# alterado no bundle quebra a validação. Falhar aqui é falhar cedo.
step "codesign --verify"
codesign --verify --strict "$APP"
codesign -dv "$APP" 2>&1 | grep -E 'Signature|Identifier' || true

# --- Pacote -------------------------------------------------------------------
step "ditto"
mkdir -p "$REPO_ROOT/dist"
rm -f "$REPO_ROOT/dist/$ZIP_NAME" "$REPO_ROOT/dist/$ZIP_NAME.sha256"
ditto -c -k --keepParent "$APP" "$REPO_ROOT/dist/$ZIP_NAME"

# Hash publicado junto do release — mesma política do .deb e do instalador
# Windows: sem certificado pago, o SHA-256 é o que o usuário tem para conferir.
( cd "$REPO_ROOT/dist" && shasum -a 256 "$ZIP_NAME" > "$ZIP_NAME.sha256" )

SIZE="$(du -h "$REPO_ROOT/dist/$ZIP_NAME" | cut -f1)"
step "Pronto: dist/$ZIP_NAME ($SIZE)"
echo "  SHA-256: $(cut -d' ' -f1 "$REPO_ROOT/dist/$ZIP_NAME.sha256")"
echo "  Instalar: ditto -x -k dist/$ZIP_NAME /Applications"
