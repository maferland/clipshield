<div align="center">

<img src="assets/shield-icon.png" width="128" height="128" alt="ClipShield Icon">

<h1>ClipShield</h1>

<p>Raycast extension that watches your clipboard for sensitive data</p>
</div>

---

Silently detects credit card numbers, SSNs, and SINs in your clipboard and auto-clears them after a configurable countdown.

## Install

```sh
# Raycast Store (once published)
# Search "ClipShield" in Raycast

# From source
git clone https://github.com/maferland/clipshield.git
cd clipshield
bun install
bun run dev
```

## Usage

| Command | Mode | Description |
|---------|------|-------------|
| Monitor Clipboard | Menu bar | Background monitor — auto-clears after delay |
| Scan Clipboard Now | No-view | Instant scan + clear |

### Preferences

| Setting | Default | Description |
|---------|---------|-------------|
| Clear Delay | 30s | Seconds before auto-clearing |
| Detect Credit Cards | On | Visa, Mastercard, Amex (Luhn-validated) |
| Detect SSN (US) | On | `###-##-####` format |
| Detect SIN (CA) | On | `### ### ###` or `###-###-###` format |
| Show Notification | On | HUD notification on clear |

### How it works

1. Shield icon in menu bar turns red when sensitive data is detected
2. Countdown starts (default 30s)
3. Copy something else → countdown cancels
4. Countdown expires → clipboard wiped

## License

[MIT](LICENSE)
