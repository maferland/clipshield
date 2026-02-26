import AppKit

protocol ClipboardProvider: AnyObject {
    var changeCount: Int { get }
    func string() -> String?
    func setString(_ string: String)
    func clear()
}

final class SystemClipboardProvider: ClipboardProvider {
    private let pasteboard = NSPasteboard.general

    var changeCount: Int { pasteboard.changeCount }

    func string() -> String? {
        pasteboard.string(forType: .string)
    }

    func setString(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        pasteboard.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
    }

    func clear() {
        pasteboard.clearContents()
    }
}
