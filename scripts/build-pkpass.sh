#!/usr/bin/env bash
# Arma y firma pass.pkpass a partir de pass-src/.
#
# Uso:
#   PASS_TYPE_IDENTIFIER=pass.com.ejemplo.demo \
#   TEAM_IDENTIFIER=ABCDE12345 \
#   P12_PATH=certs/pass.p12 P12_PASSWORD=secreto \
#   WWDR_PATH=certs/AppleWWDRCAG4.cer \
#   ./scripts/build-pkpass.sh
set -euo pipefail

: "${PASS_TYPE_IDENTIFIER:?Falta PASS_TYPE_IDENTIFIER}"
: "${TEAM_IDENTIFIER:?Falta TEAM_IDENTIFIER}"
: "${P12_PATH:?Falta P12_PATH (certificado Pass Type ID exportado como .p12)}"
: "${WWDR_PATH:?Falta WWDR_PATH (Apple WWDR G4, .cer)}"
P12_PASSWORD="${P12_PASSWORD:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/pass.pkpass"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/pass" "$WORK/keys"
cp "$ROOT"/pass-src/* "$WORK/pass/"
sed -i '' \
  -e "s/__PASS_TYPE_IDENTIFIER__/$PASS_TYPE_IDENTIFIER/" \
  -e "s/__TEAM_IDENTIFIER__/$TEAM_IDENTIFIER/" \
  "$WORK/pass/pass.json"

# manifest.json: SHA-1 de cada archivo del pase
(
  cd "$WORK/pass"
  printf '{'
  first=1
  for f in *; do
    [ "$f" = manifest.json ] && continue
    [ $first -eq 0 ] && printf ','
    printf '"%s":"%s"' "$f" "$(shasum -a 1 "$f" | cut -d' ' -f1)"
    first=0
  done
  printf '}'
) > "$WORK/manifest.json"
mv "$WORK/manifest.json" "$WORK/pass/manifest.json"

# Extrae certificado y llave del .p12 (-legacy para .p12 exportados desde Keychain con OpenSSL 3)
LEGACY=""
openssl pkcs12 -help 2>&1 | grep -q -- '-legacy' && LEGACY="-legacy"
openssl pkcs12 $LEGACY -in "$P12_PATH" -clcerts -nokeys -out "$WORK/keys/cert.pem" -passin "pass:$P12_PASSWORD"
openssl pkcs12 $LEGACY -in "$P12_PATH" -nocerts -nodes -out "$WORK/keys/key.pem" -passin "pass:$P12_PASSWORD"
openssl x509 -inform DER -in "$WWDR_PATH" -out "$WORK/keys/wwdr.pem" 2>/dev/null \
  || openssl x509 -in "$WWDR_PATH" -out "$WORK/keys/wwdr.pem"

openssl smime -binary -sign \
  -certfile "$WORK/keys/wwdr.pem" \
  -signer "$WORK/keys/cert.pem" \
  -inkey "$WORK/keys/key.pem" \
  -in "$WORK/pass/manifest.json" \
  -out "$WORK/pass/signature" \
  -outform DER

rm -f "$OUT"
(cd "$WORK/pass" && zip -q -X -r "$OUT" .)
echo "Generado: $OUT"
