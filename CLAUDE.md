# clipshield

Raycast extension that monitors clipboard for sensitive data and auto-clears it.

## Tech
- TypeScript, Raycast API (`@raycast/api`, `@raycast/utils`)
- Vitest for unit tests
- No external dependencies beyond Raycast SDK

## Commands
- `monitor` — Menu bar background command, polls clipboard every 10s
- `scan` — Manual no-view command, instant scan + clear

## Architecture
- `src/detect.ts` — Pure pattern detection (CC with Luhn, SSN, SIN). Fully testable.
- `src/preferences.ts` — Raycast preferences adapter
- `src/monitor.tsx` — Menu bar command (React component)
- `src/scan.ts` — Manual scan command (async function)

## Dev
```sh
npm install
npm run dev        # Raycast hot reload
npm test           # Vitest
```
