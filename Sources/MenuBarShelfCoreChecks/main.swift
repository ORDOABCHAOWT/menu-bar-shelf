import Foundation
import MenuBarShelfCore

@discardableResult
func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) -> Bool {
    if actual == expected {
        return true
    }

    print("FAIL: \(message)")
    print("  expected: \(expected)")
    print("  actual:   \(actual)")
    exit(1)
}

func testKeepsAccessoryAndProhibitedAppsByDefault() {
    let apps = [
            AppDescriptor(
                bundleIdentifier: "com.example.menu",
                localizedName: "Menu Utility",
                bundlePath: "/Applications/Menu Utility.app",
                activationPolicy: .accessory,
                isFinishedLaunching: true
            ),
            AppDescriptor(
                bundleIdentifier: "com.example.tray",
                localizedName: "Tray Companion",
                bundlePath: "/Applications/Tray Companion.app",
                activationPolicy: .prohibited,
                isFinishedLaunching: true
            ),
        AppDescriptor(
            bundleIdentifier: "com.example.regular",
            localizedName: "Regular App",
            bundlePath: "/Applications/Regular App.app",
            activationPolicy: .regular,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(settings: .init(currentBundleIdentifier: "com.example.shelf"))
        .visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Menu Utility", "Tray Companion"], "keeps menu-bar-like apps")
}

func testCanIncludeRegularAppsWhenRequested() {
    let apps = [
        AppDescriptor(
            bundleIdentifier: "com.example.regular",
            localizedName: "Regular App",
            bundlePath: "/Applications/Regular App.app",
            activationPolicy: .regular,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(
        settings: .init(
            currentBundleIdentifier: "com.example.shelf",
            includeRegularApps: true
        )
    ).visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Regular App"], "includes regular apps when requested")
}

func testExcludesItselfAndUnfinishedApps() {
    let apps = [
        AppDescriptor(
            bundleIdentifier: "com.example.shelf",
            localizedName: "MenuBarShelf",
            bundlePath: "/Applications/MenuBarShelf.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.loading",
            localizedName: "Loading",
            bundlePath: "/Applications/Loading.app",
            activationPolicy: .accessory,
            isFinishedLaunching: false
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.ready",
            localizedName: "Ready",
            bundlePath: "/Applications/Ready.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(settings: .init(currentBundleIdentifier: "com.example.shelf"))
        .visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Ready"], "excludes self and unfinished apps")
}

func testDeduplicatesByBundleIdentifierAndSortsLocalizedNames() {
    let apps = [
        AppDescriptor(
            bundleIdentifier: "com.example.b",
            localizedName: "Beta",
            bundlePath: "/Applications/Beta.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.a",
            localizedName: "Alpha",
            bundlePath: "/Applications/Alpha.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.a",
            localizedName: "Alpha Duplicate",
            bundlePath: "/Applications/Alpha.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(settings: .init(currentBundleIdentifier: "com.example.shelf"))
        .visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Alpha", "Beta"], "deduplicates and sorts")
}

func testHidesHelperAgentServiceAndExtensionProcesses() {
    let apps = [
        AppDescriptor(
            bundleIdentifier: "com.adobe.AdobeCreativeCloud",
            localizedName: "Creative Cloud",
            bundlePath: "/Applications/Adobe Creative Cloud/Adobe Creative Cloud.app",
            activationPolicy: .regular,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.adobe.AdobeCreativeCloud.helper",
            localizedName: "Creative Cloud Helper",
            bundlePath: "/Applications/Adobe Creative Cloud/Adobe Creative Cloud.app/Contents/Helpers/Creative Cloud Helper.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.figma.agent",
            localizedName: "FigmaAgent",
            bundlePath: "/Library/Application Support/Figma/FigmaAgent.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.extension",
            localizedName: "Example Finder Extension",
            bundlePath: "/Applications/Example.app/Contents/PlugIns/Example Finder Extension.appex",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.typeless",
            localizedName: "Typeless",
            bundlePath: "/Applications/Typeless.app",
            activationPolicy: .regular,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: nil,
            localizedName: "osascript",
            bundlePath: "/usr/bin/osascript",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.google.Chrome.helper",
            localizedName: "Google Chrome Helper",
            bundlePath: "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Helper.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(
        settings: .init(
            currentBundleIdentifier: "com.example.shelf",
            includeRegularApps: true
        )
    ).visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Creative Cloud", "Typeless"], "hides helper, agent, service, and extension processes")
}

func testHidesBackgroundSynchronizersAndDeduplicatesByDisplayName() {
    let apps = [
        AppDescriptor(
            bundleIdentifier: "com.tencent.xinWeChat",
            localizedName: "WeChat",
            bundlePath: "/Applications/WeChat.app",
            activationPolicy: .regular,
            isFinishedLaunching: true,
            processIdentifier: 100
        ),
        AppDescriptor(
            bundleIdentifier: "com.tencent.xinWeChat.mini",
            localizedName: "WeChat",
            bundlePath: "/Applications/WeChat.app/Contents/Frameworks/Mini Program.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true,
            processIdentifier: 101
        ),
        AppDescriptor(
            bundleIdentifier: "com.adobe.acc.AdobeContentSynchronizer",
            localizedName: "Adobe Content Synchronizer",
            bundlePath: "/Applications/Utilities/Adobe Sync/CoreSync/Core Sync.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.example.bare-modifier-monitor",
            localizedName: "bare-modifier-monitor",
            bundlePath: "/Applications/bare-modifier-monitor.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        ),
        AppDescriptor(
            bundleIdentifier: "com.raycast.macos",
            localizedName: "Raycast",
            bundlePath: "/Applications/Raycast.app",
            activationPolicy: .accessory,
            isFinishedLaunching: true
        )
    ]

    let result = AppListBuilder(
        settings: .init(
            currentBundleIdentifier: "com.example.shelf",
            includeRegularApps: true
        )
    ).visibleApps(from: apps)

    expectEqual(result.map(\.localizedName), ["Raycast", "WeChat"], "hides synchronizers and deduplicates by display name")
}

func testActivationPlanBringsAppToFrontAndFallsBackToBundleOpen() {
    let app = AppDescriptor(
        bundleIdentifier: "com.example.editor",
        localizedName: "Editor",
        bundlePath: "/Applications/Editor.app",
        activationPolicy: .regular,
        isFinishedLaunching: true
    )

    let plan = AppActivationPlan.foregroundPlan(for: app)

    expectEqual(
        plan.steps,
        [
            .unhide,
            .yieldActivation,
            .activate(allWindows: true),
            .openBundle(path: "/Applications/Editor.app")
        ],
        "uses cooperative foreground activation with bundle-open fallback"
    )
}

func testAccessibilityMenuHidesPermissionActionsWhenEnhancementUnavailable() {
    let items = AccessibilityMenuPolicy.items(for: .unavailable)

    expectEqual(
        items,
        [
            .status(title: "辅助功能增强：未启用", symbolName: "shield.slash")
        ],
        "hides permission request actions while accessibility enhancement is unavailable"
    )
}

testKeepsAccessoryAndProhibitedAppsByDefault()
testCanIncludeRegularAppsWhenRequested()
testExcludesItselfAndUnfinishedApps()
testDeduplicatesByBundleIdentifierAndSortsLocalizedNames()
testHidesHelperAgentServiceAndExtensionProcesses()
testHidesBackgroundSynchronizersAndDeduplicatesByDisplayName()
testActivationPlanBringsAppToFrontAndFallsBackToBundleOpen()
testAccessibilityMenuHidesPermissionActionsWhenEnhancementUnavailable()

print("MenuBarShelfCoreChecks: 8 checks passed")
