# I.C.E Out

Ad-free, open-source community safety tool for reporting ICE activity after it occurs. Privacy-first — no accounts, no tracking, no data sold.

## Features

- Anonymous report submission (no personal data collected)
- Community-sourced activity map with color-coded markers
- Report types: raid, checkpoint, surveillance, patrol, transport, other
- Know Your Rights resources & emergency contacts
- ICE facility directory
- OpenFreeMap vector tiles + Leaflet/MapLibre
- Offline-capable (falls back to mock mode when backend is unreachable)
- Self-hostable Supabase backend — users can configure their own

## Privacy

- All reports are anonymous. No account, no IP logging, no tracking.
- Reports expire after 72 hours (enforced server-side).
- Backend is configurable — users can point to their own self-hosted Supabase instance.
- No analytics, no crash reporting, no third-party SDKs.

## Disclaimer

I.C.E Out is a community safety tool for reporting ICE activity after it has occurred. It is not affiliated with any government agency. All reports are anonymous and crowd-sourced. This app does not encourage or facilitate interference with law enforcement operations.

## Build

Requirements: JDK 17, Android SDK 34, Gradle 8.4

    gradle wrapper --gradle-version 8.4
    ./gradlew assembleDebug

APK output: app/build/outputs/apk/debug/app-debug.apk

## Tech Stack

- Android WebView wrapper (single HTML/CSS/JS app)
- Leaflet 1.9.4 + MapLibre GL 4.7.1 (bundled locally)
- IBM Plex Sans + Mono (bundled locally)
- Supabase (configurable backend)
- Zero proprietary dependencies

## Self-Hosting the Backend

The app connects to a community Supabase backend by default. Users can configure their own backend:

1. Self-host Supabase via Docker: https://supabase.com/docs/guides/self-hosting
2. Run the schema in supabase/schema.sql
3. Open the app, go to Info tab, then Backend Configuration
4. Enter your Supabase URL and anon key

## Donate

Bitcoin (on-chain): bc1qtl8dvdtsmev96xqwt5w7lkufhsa0pr9snmtc

Lightning Address: iceout@greenwood.havral.com

## License

MIT
