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

`vercel.json` build komutu:

```bash
flutter pub get && flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL --base-href=/
```

Output directory:

```text
build/web
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

## Guvenlik Kontrolleri

- Production icin HTTPS API URL kullanin.
- `API_BASE_URL` degeri Vercel env olarak tutulmali.
- `.env` dosyasi commit edilmemeli.
- Token ve kullanici bilgisi loglanmamali.
- Backend CORS allowlist icinde sadece Vercel domainleri yer almali.
