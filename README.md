# MediaToolbox

App Flutter Android avec 3 fonctionnalités :

1. **Compresseur vidéo** — choix de la résolution (144p → 2K), du format (MP4/MKV/WEBM/AVI) et de la qualité (CRF).
2. **Convertisseur M3U8 → MP4** — scan récursif d'un dossier, détection des `.m3u8`, conversion en `.mp4` dans `Download/m3u8/`.
3. **Reformulateur de phrases** — reformule une phrase selon 6 tons (Arrogant/Escanor, Impoli, Business, Professionnel, Poli, Commerçant) via l'API Gemini.

## ⚠️ Configuration avant utilisation

Avant de build, ouvre `lib/services/reformulator_service.dart` et remplace :

```dart
static const String _apiKey = 'TA_CLE_API_GEMINI_ICI';
```

par ta propre clé API Gemini, obtenue gratuitement sur https://aistudio.google.com/app/apikey

## 🚀 Récupérer l'APK sans build local (recommandé pour toi, Francois)

Ce repo contient un workflow **GitHub Actions** (`.github/workflows/build-apk.yml`) qui build l'APK automatiquement dans le cloud à chaque push sur `main` — ton PC n'a rien à faire.

Pour récupérer l'APK :
1. Va dans l'onglet **Actions** de ce repo sur GitHub
2. Clique sur le dernier run du workflow "Build APK"
3. Descends jusqu'à la section **Artifacts** en bas de page
4. Télécharge `mediatoolbox-apk` (contient `app-release.apk`)

Tu peux aussi déclencher un build manuellement depuis l'onglet Actions → "Build APK" → "Run workflow", sans avoir à pusher de code.

## Build local (si besoin)

```bash
flutter pub get
flutter build apk --release
```

L'APK sera dans `build/app/outputs/flutter-apk/app-release.apk`.
