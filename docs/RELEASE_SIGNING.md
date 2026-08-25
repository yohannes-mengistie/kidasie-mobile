# Android release signing

Every published Android update must be signed with the same private key.

Back up these two ignored files together in at least two secure locations:

- `android/ortholiturgy-release.jks`
- `android/key.properties`

Never commit either file, send them through chat, or regenerate the key after
users install the application. Losing the key or its password prevents future
APK versions from updating existing installations.

Build small release APKs with:

```bash
flutter build apk --release --split-per-abi
```

Before each public release, increase `version` in `pubspec.yaml`.
