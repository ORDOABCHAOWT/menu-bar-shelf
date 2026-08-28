import AppKit
import Carbon

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private lazy var shelfMenuController = ShelfMenuController()
    private var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "io.github.ordoabchaowt.menubarshelf"
        item.autosaveName = NSStatusItem.AutosaveName("\(bundleIdentifier).statusItem")
        item.button?.image = MenuBarIcon.statusImage()
        item.button?.image?.isTemplate = true
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "MenuBarShelf"
        item.menu = shelfMenuController.menu
        statusItem = item

        let controller = HotKeyController {
            self.shelfMenuController.showAtMouseLocation()
        }
        hotKeyController = controller
        shelfMenuController.hotKeyStatusProvider = { [weak controller] in
            controller?.installationState ?? .unavailable(OSStatus(eventNotHandledErr))
        }
    }
}

enum MenuBarIcon {
    static func statusImage() -> NSImage {
        if let symbol = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "MenuBarShelf") {
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            let image = symbol.withSymbolConfiguration(config) ?? symbol
            image.isTemplate = true
            return image
        }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.labelColor.setStroke()

        let line = NSBezierPath()
        line.lineWidth = 1.8
        line.lineCapStyle = .round
        line.lineJoinStyle = .round

        line.move(to: NSPoint(x: 4.5, y: 5.5))
        line.line(to: NSPoint(x: 13.5, y: 5.5))
        line.move(to: NSPoint(x: 4.5, y: 9.0))
        line.line(to: NSPoint(x: 13.5, y: 9.0))
        line.move(to: NSPoint(x: 4.5, y: 12.5))
        line.line(to: NSPoint(x: 10.5, y: 12.5))
        line.stroke()

        let dot = NSBezierPath(ovalIn: NSRect(x: 12.2, y: 11.4, width: 2.4, height: 2.4))
        NSColor.labelColor.setFill()
        dot.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
