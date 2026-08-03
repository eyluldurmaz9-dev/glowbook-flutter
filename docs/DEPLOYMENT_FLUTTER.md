# Flutter Web Deployment

## Hedef

- Platform: Vercel
- Build output: `build/web`
- Routing: SPA rewrite, tum route'lar `index.html` dosyasina duser.

## Environment Variables

Vercel Project Settings > Environment Variables alanina ekleyin:

| Key | Ornek | Not |
| --- | --- | --- |
| `API_BASE_URL` | `https://api.example.com` | Gercek production URL repository'ye yazilmaz. |

## Vercel Build

`vercel.json` Vercel'in Flutter SDK bulunmayan build ortamiyla uyumlu olacak sekilde Node wrapper uzerinden calisir:

```bash
npm run vercel-build
```

Output directory:

```text
build/web
```

`package.json` script'i `scripts/vercel-build.sh` dosyasini calistirir. Script:

- `API_BASE_URL` bos ise build'i durdurur.
- Vercel ortaminda `flutter` bulunmuyorsa Flutter stable SDK'yi `$HOME/flutter` altina kurar.
- `flutter config --enable-web` ve `flutter pub get` calistirir.
- Production web build'i `--release`, `--dart-define=API_BASE_URL=$API_BASE_URL` ve `--base-href=/` ile uretir.

Vercel ayarlari:

```text
Root Directory: flutter_app
Install Command: npm install
Build Command: npm run vercel-build
Output Directory: build/web
```

SPA rewrite:

```json
{
  "source": "/(.*)",
  "destination": "/index.html"
}
```

## Flutter Web Base Href

`web/index.html` icinde base href Flutter placeholder olarak kalir:

```html
<base href="$FLUTTER_BASE_HREF">
```

Vercel root deployment icin build komutunda `--base-href=/` kullanilir.

## Production API URL

Flutter uygulamasi `lib/core/config/api_config.dart` icinde `String.fromEnvironment('API_BASE_URL')` kullanir. Bu nedenle production API adresi build sirasinda verilmelidir:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
```

Vercel'de `API_BASE_URL` degerini Production, Preview ve Development environment'lari icin ayri ayri tanimlayabilirsiniz. Gercek domain repository'ye commit edilmemelidir.

## Guvenlik Kontrolleri

- Production icin HTTPS API URL kullanin.
- `API_BASE_URL` degeri Vercel env olarak tutulmali.
- `.env` dosyasi commit edilmemeli.
- Token ve kullanici bilgisi loglanmamali.
- Backend CORS allowlist icinde sadece Vercel domainleri yer almali.
