import { execFileSync } from "child_process";

/**
 * Re-write text to macOS pasteboard with org.nspasteboard.ConcealedType.
 * Clipboard managers (Raycast, Paste, etc.) auto-expire concealed entries.
 * Uses JXA via execFileSync to avoid shell escaping issues.
 */
export function markConcealed(text: string): void {
  const b64 = Buffer.from(text).toString("base64");
  execFileSync("osascript", [
    "-l", "JavaScript",
    "-e", 'ObjC.import("AppKit")',
    "-e", 'ObjC.import("Foundation")',
    "-e", `var d = $.NSData.alloc.initWithBase64EncodedStringOptions("${b64}", 0)`,
    "-e", "var t = $.NSString.alloc.initWithDataEncoding(d, 4)",
    "-e", "var pb = $.NSPasteboard.generalPasteboard",
    "-e", "pb.clearContents",
    "-e", 'pb.setStringForType(t, "public.utf8-plain-text")',
    "-e", 'pb.setStringForType("", "org.nspasteboard.ConcealedType")',
  ]);
}

/**
 * Clear the clipboard entirely.
 */
export function clearClipboard(): void {
  execFileSync("osascript", [
    "-l", "JavaScript",
    "-e", 'ObjC.import("AppKit")',
    "-e", "$.NSPasteboard.generalPasteboard.clearContents",
  ]);
}
