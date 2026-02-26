# ClipShield

Raycast extension that watches your clipboard for sensitive data and silently clears it.

Detects credit card numbers (with Luhn validation), US Social Security Numbers, and Canadian Social Insurance Numbers. When a match is found, a configurable countdown starts — if the clipboard still contains the sensitive data when it expires, it's wiped and you get a subtle notification.

## Install

```sh
# From Raycast Store (once published)
# Search "ClipShield" in Raycast

# From source
git clone https://github.com/maferland/clipshield.git
cd clipshield
npm install
npm run dev
```

## Commands

| Command | Mode | Description |
|---------|------|-------------|
| Monitor Clipboard | Menu bar | Background monitor — polls clipboard, auto-clears after delay |
| Scan Clipboard Now | No-view | Instant scan + clear of current clipboard |

## Preferences

| Setting | Default | Description |
|---------|---------|-------------|
| Clear Delay | 30s | Seconds before auto-clearing detected data |
| Detect Credit Cards | On | Visa, Mastercard, Amex (Luhn-validated) |
| Detect SSN (US) | On | `###-##-####` format |
| Detect SIN (CA) | On | `### ### ###` or `###-###-###` format |
| Show Notification | On | HUD notification on clear |

## How it works

1. Menu bar shield icon turns red when sensitive data is detected
2. Countdown starts (default 30s)
3. If you copy something else, countdown cancels
4. If countdown expires, clipboard is wiped

## Development

```sh
npm install
npm run dev        # Raycast hot reload
npm test           # Run tests
npm run lint       # ESLint
```

## License

MIT
