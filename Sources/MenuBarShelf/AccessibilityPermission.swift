import AppKit
import ApplicationServices

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestPrompt() {
        let key = "AXTrustedCheckOptionPrompt"
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
