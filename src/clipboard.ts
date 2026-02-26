import { execSync } from "child_process";

/**
 * Re-write text to macOS pasteboard with org.nspasteboard.ConcealedType.
 * Clipboard managers (Raycast, Paste, etc.) auto-expire concealed entries.
 */
export function markConcealed(text: string): void {
  const escaped = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  execSync(`osascript -e '
    use framework "AppKit"
    set pb to current application\\'s NSPasteboard\\'s generalPasteboard()
    pb\\'s clearContents()
    pb\\'s setString:"${escaped}" forType:"public.utf8-plain-text"
    pb\\'s setString:"" forType:"org.nspasteboard.ConcealedType"
  '`);
}

/**
 * Clear the clipboard entirely.
 */
export function clearClipboard(): void {
  execSync(`osascript -e '
    use framework "AppKit"
    set pb to current application\\'s NSPasteboard\\'s generalPasteboard()
    pb\\'s clearContents()
  '`);
}
