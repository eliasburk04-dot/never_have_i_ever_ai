# Deploy to Vercel (Flutter Web)

This project is configured for static Flutter Web deployment on Vercel with SPA rewrites.

## 1. Required environment variables (Vercel Project Settings)

Set these in **Vercel -> Project -> Settings -> Environment Variables**:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not hardcode these values in source code.

## 2. Build command

Use this production build command:

```bash
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

In Vercel, `vercel.json` already uses environment variables:

```bash
flutter build web --release --dart-define=SUPABASE_URL=${SUPABASE_URL} --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
```

## 3. Output directory

Vercel serves the Flutter static build from:

- `build/web`

This is already configured in `vercel.json`.

## 4. SPA routing rewrite

All routes are rewritten to `index.html`:

- `/(.*)` -> `/index.html`

This enables `go_router` client-side routes (e.g. `/join`, `/game/:lobbyId`) to work on refresh/direct navigation.

## 5. Deploy

### Option A: Vercel Git integration (recommended)

1. Push repo to GitHub/GitLab/Bitbucket.
2. Import project in Vercel.
3. Confirm env vars are set.
4. Trigger deploy.

### Option B: Vercel CLI

```bash
npm i -g vercel
vercel
vercel --prod
```

## 6. Local verification (optional)

```bash
flutter pub get
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Then test the generated app from `build/web` with any static server.
