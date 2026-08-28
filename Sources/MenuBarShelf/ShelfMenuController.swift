import AppKit
import MenuBarShelfCore

@MainActor
final class ShelfMenuController: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    var hotKeyStatusProvider: (() -> HotKeyController.InstallationState)?

    private let provider = RunningAppsProvider()
    private let accessibilityEnhancementAvailable = false
    private var iconCache: [String: NSImage] = [:]
    private var includeRegularApps: Bool {
        get { UserDefaults.standard.bool(forKey: "includeRegularApps") }
        set { UserDefaults.standard.set(newValue, forKey: "includeRegularApps") }
    }

    override init() {
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    func showAtMouseLocation() {
        rebuildMenu()
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        addHeader()
        addControls()
        menu.addItem(.separator())
        addAppItems()
        menu.addItem(.separator())
        addAccessibilityItems()
        menu.addItem(.separator())
        addQuitItem()
    }

    private func addHeader() {
        let title = NSMenuItem(title: "MenuBarShelf", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        let subtitle = NSMenuItem(title: "轻量菜单栏收纳", action: nil, keyEquivalent: "")
        subtitle.isEnabled = false
        menu.addItem(subtitle)
    }

    private func addControls() {
        let modeTitle = includeRegularApps ? "显示：全部应用" : "显示：菜单栏类"
        let toggle = NSMenuItem(title: modeTitle, action: #selector(toggleMode), keyEquivalent: "")
        toggle.target = self
        toggle.image = NSImage(systemSymbolName: includeRegularApps ? "square.grid.2x2" : "menubar.rectangle", accessibilityDescription: nil)
        menu.addItem(toggle)

        let refresh = NSMenuItem(title: "刷新列表", action: #selector(refreshMenu), keyEquivalent: "r")
        refresh.target = self
        refresh.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        menu.addItem(refresh)

        let hotKeyStatus = hotKeyStatusProvider?() ?? .available
        let hotKeyTitle: String
        let hotKeySymbol: String
        switch hotKeyStatus {
        case .available:
            hotKeyTitle = "快捷键：⌃⌥⌘M"
            hotKeySymbol = "keyboard"
        case .unavailable(let status):
            hotKeyTitle = "快捷键不可用（\(status)）"
            hotKeySymbol = "exclamationmark.triangle"
        }

        let hotKey = NSMenuItem(title: hotKeyTitle, action: nil, keyEquivalent: "")
        hotKey.isEnabled = false
        hotKey.image = NSImage(systemSymbolName: hotKeySymbol, accessibilityDescription: nil)
        menu.addItem(hotKey)
    }

    private func addAppItems() {
        let entries = visibleEntries()
        pruneIconCache(for: entries)

        if entries.isEmpty {
            let empty = NSMenuItem(title: includeRegularApps ? "未发现运行中的应用" : "未发现菜单栏类应用", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }

        for entry in entries {
            let item = NSMenuItem(title: entry.descriptor.localizedName, action: #selector(openApp(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = AppMenuPayload(entry: entry)
            item.toolTip = entry.descriptor.bundleIdentifier ?? entry.descriptor.bundlePath
            item.image = icon(for: entry)
            menu.addItem(item)
        }
    }

    private func addAccessibilityItems() {
        for item in AccessibilityMenuPolicy.items(for: accessibilityPermissionState()) {
            switch item {
            case .status(let title, let symbolName):
                let status = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                status.isEnabled = false
                status.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
                menu.addItem(status)
            case .requestPermission(let title, let symbolName):
                let request = NSMenuItem(title: title, action: #selector(requestAccessibility), keyEquivalent: "")
                request.target = self
                request.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
                menu.addItem(request)
            case .openSettings(let title, let symbolName):
                let settings = NSMenuItem(title: title, action: #selector(openAccessibilitySettings), keyEquivalent: "")
                settings.target = self
                settings.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
                menu.addItem(settings)
            }
        }
    }

    private func accessibilityPermissionState() -> AccessibilityPermissionState {
        guard accessibilityEnhancementAvailable else {
            return .unavailable
        }

        return AccessibilityPermission.isTrusted ? .trusted : .untrusted
    }

    private func addQuitItem() {
        let quit = NSMenuItem(title: "退出 MenuBarShelf", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        quit.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quit)
    }

    private func visibleEntries() -> [RunningAppEntry] {
        let currentBundleIdentifier = Bundle.main.bundleIdentifier ?? "io.github.ordoabchaowt.menubarshelf"
        let builder = AppListBuilder(
            settings: AppListSettings(
                currentBundleIdentifier: currentBundleIdentifier,
                includeRegularApps: includeRegularApps
            )
        )

        let allEntries = provider.entries()
        let entriesByKey = Dictionary(grouping: allEntries, by: \.descriptor.deduplicationKey)
        let visibleDescriptors = builder.visibleApps(from: allEntries.map(\.descriptor))
        return visibleDescriptors.compactMap { descriptor in
            entriesByKey[descriptor.deduplicationKey]?.first
        }
    }

    private func icon(for entry: RunningAppEntry) -> NSImage? {
        if let url = entry.runningApplication.bundleURL {
            let path = url.path
            if let cachedImage = iconCache[path] {
                return cachedImage
            }

            let image = NSWorkspace.shared.icon(forFile: path)
            image.size = NSSize(width: 18, height: 18)
            iconCache[path] = image
            return image
        }
        return NSImage(systemSymbolName: "app", accessibilityDescription: nil)
    }

    private func pruneIconCache(for entries: [RunningAppEntry]) {
        let visiblePaths = Set(entries.compactMap { $0.runningApplication.bundleURL?.path })
        iconCache = iconCache.filter { visiblePaths.contains($0.key) }
    }

    @objc private func toggleMode() {
        includeRegularApps.toggle()
        rebuildMenu()
    }

    @objc private func refreshMenu() {
        rebuildMenu()
    }

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? AppMenuPayload else {
            return
        }

        runActivationPlan(AppActivationPlan.foregroundPlan(for: payload.descriptor), app: payload.runningApplication)
    }

    private func runActivationPlan(_ plan: AppActivationPlan, app: NSRunningApplication) {
        var didActivate = false

        for step in plan.steps {
            switch step {
            case .unhide:
                app.unhide()
            case .yieldActivation:
                NSApp.yieldActivation(to: app)
            case .activate(let allWindows):
                var options: NSApplication.ActivationOptions = []
                if allWindows {
                    options.insert(.activateAllWindows)
                }
                didActivate = app.activate(from: NSRunningApplication.current, options: options)
            case .openBundle(let path):
                guard !didActivate else {
                    continue
                }
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: path),
                    configuration: configuration,
                    completionHandler: nil
                )
            }
        }
    }

    @objc private func requestAccessibility() {
        AccessibilityPermission.requestPrompt()
        rebuildMenu()
    }

    @objc private func openAccessibilitySettings() {
        AccessibilityPermission.openPrivacySettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
