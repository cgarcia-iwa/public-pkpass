# public-pkpass

Página estática (GitHub Pages) que sirve un único archivo `pass.pkpass` para poder abrirlo desde un iPhone y ver su renderizado en Apple Wallet.

## Estructura

- `index.html` — página con el botón "Agregar a Apple Wallet".
- `pass.pkpass` — el pase firmado que se descarga (ver abajo cómo obtenerlo).
- `pass-src/` — fuentes del pase: `pass.json` e imágenes.
- `scripts/build-pkpass.sh` — arma `manifest.json`, firma y comprime en `pass.pkpass`.
- `.nojekyll` — publica los archivos tal cual.

## Obtener `pass.pkpass`

iOS solo acepta pases **firmados** con un certificado *Pass Type ID* de una cuenta Apple Developer. Opciones:

1. **Ya tienes un `.pkpass`**: cópialo a la raíz como `pass.pkpass`.
2. **Generarlo desde `pass-src/`**:
   1. En developer.apple.com crea un *Pass Type ID* (p. ej. `pass.com.tuempresa.demo`) y su certificado; instálalo en Keychain y expórtalo como `.p12`.
   2. Descarga el certificado intermedio *Apple WWDR G4* (`AppleWWDRCAG4.cer`).
   3. Ejecuta:

      ```bash
      PASS_TYPE_IDENTIFIER=pass.com.tuempresa.demo \
      TEAM_IDENTIFIER=ABCDE12345 \
      P12_PATH=certs/pass.p12 P12_PASSWORD=secreto \
      WWDR_PATH=certs/AppleWWDRCAG4.cer \
      ./scripts/build-pkpass.sh
      ```

`certs/` está en `.gitignore`: nunca subas el `.p12` al repositorio.

Luego haz commit y push de `pass.pkpass`; GitHub Pages lo sirve con `Content-Type: application/vnd.apple.pkpass`, que es lo que Safari necesita para abrir Wallet.
