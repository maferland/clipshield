# clipshield — Raycast Clipboard Sanitizer

## Overview
Raycast extension that monitors clipboard for sensitive data (CC numbers, SSN/SIN) and silently clears it after a configurable delay.

## Commands
1. **Menu Bar Command** (`monitor`) — Background clipboard monitor. Polls every 2s. Shield icon in menu bar. Shows last detection time + count in dropdown.
2. **Regular Command** (`scan`) — Manual "scan now" that checks current clipboard and clears if sensitive.

## Detection Patterns (configurable via Raycast preferences)
| Pattern | Regex | Default |
|---------|-------|---------|
| Credit Card | `\b(?:\d[ -]*?){13,19}\b` + Luhn validation | On |
| Amex | `\b3[47]\d{2}[ -]?\d{6}[ -]?\d{5}\b` | On |
| SSN (US) | `\b\d{3}-\d{2}-\d{4}\b` | On |
| SIN (CA) | `\b\d{3}[ -]\d{3}[ -]\d{3}\b` | On |

## Behavior
1. Clipboard polled every 2s
2. On match → start countdown (default 30s, configurable)
3. If clipboard changes before countdown → cancel
4. If countdown expires and clipboard still matches → clear + HUD notification
5. Menu bar icon: normal shield = monitoring, red shield = counting down

## Preferences
- `clearDelay`: number (seconds, default 30)
- `enableCC`: boolean (default true)
- `enableSSN`: boolean (default true)
- `enableSIN`: boolean (default true)
- `showNotification`: boolean (default true)

## Tech
- TypeScript, Raycast API (`@raycast/api`)
- No external dependencies
- Jest for pattern detection unit tests
