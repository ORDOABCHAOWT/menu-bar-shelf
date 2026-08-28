import Foundation

public enum ActivationPolicy: Equatable, Sendable {
    case regular
    case accessory
    case prohibited
}

public struct AppDescriptor: Equatable, Sendable {
    public let bundleIdentifier: String?
    public let localizedName: String
    public let bundlePath: String?
    public let activationPolicy: ActivationPolicy
    public let isFinishedLaunching: Bool
    public let processIdentifier: Int32?

    public init(
        bundleIdentifier: String?,
        localizedName: String,
        bundlePath: String?,
        activationPolicy: ActivationPolicy,
        isFinishedLaunching: Bool,
        processIdentifier: Int32? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.bundlePath = bundlePath
        self.activationPolicy = activationPolicy
        self.isFinishedLaunching = isFinishedLaunching
        self.processIdentifier = processIdentifier
    }

    public var deduplicationKey: String {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return "bundle:\(bundleIdentifier)"
        }

        if let bundlePath, !bundlePath.isEmpty {
            return "path:\(bundlePath)"
        }

        if let processIdentifier {
            return "pid:\(processIdentifier)"
        }

        return "name:\(localizedName)"
    }
}

public struct AppListSettings: Equatable, Sendable {
    public let currentBundleIdentifier: String
    public let includeRegularApps: Bool
    public let excludedBundlePrefixes: [String]

    public init(
        currentBundleIdentifier: String,
        includeRegularApps: Bool = false,
        excludedBundlePrefixes: [String] = ["com.apple."]
    ) {
        self.currentBundleIdentifier = currentBundleIdentifier
        self.includeRegularApps = includeRegularApps
        self.excludedBundlePrefixes = excludedBundlePrefixes
    }
}

public struct AppListBuilder: Sendable {
    private let settings: AppListSettings

    public init(settings: AppListSettings) {
        self.settings = settings
    }

    public func visibleApps(from apps: [AppDescriptor]) -> [AppDescriptor] {
        var seen = Set<String>()

        return apps
            .filter(isVisibleCandidate)
            .filter { app in
                let key = app.deduplicationKey
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }
            .filter { app in
                let nameKey = app.localizedName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if seen.contains("name:\(nameKey)") {
                    return false
                }
                seen.insert("name:\(nameKey)")
                return true
            }
            .sorted { lhs, rhs in
                lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
            }
    }

    private func isVisibleCandidate(_ app: AppDescriptor) -> Bool {
        guard app.isFinishedLaunching else {
            return false
        }

        guard isUserFacingApp(app) else {
            return false
        }

        if app.bundleIdentifier == settings.currentBundleIdentifier {
            return false
        }

        if let bundleIdentifier = app.bundleIdentifier,
           settings.excludedBundlePrefixes.contains(where: { bundleIdentifier.hasPrefix($0) }) {
            return false
        }

        switch app.activationPolicy {
        case .accessory, .prohibited:
            return true
        case .regular:
            return settings.includeRegularApps
        }
    }

    private func isUserFacingApp(_ app: AppDescriptor) -> Bool {
        let lowerName = app.localizedName.lowercased()
        let lowerPath = app.bundlePath?.lowercased() ?? ""
        let lowerBundleIdentifier = app.bundleIdentifier?.lowercased() ?? ""

        guard lowerPath.contains(".app") else {
            return false
        }

        let hiddenNameFragments = [
            " helper",
            "helper ",
            "helper (",
            " agent",
            "agent",
            " service",
            "service",
            " extension",
            "extension",
            " renderer",
            "renderer",
            " plugin",
            "plugin",
            "mini program",
            "wxplayer",
            "synchronizer",
            "sync",
            "monitor"
        ]

        if hiddenNameFragments.contains(where: { lowerName.contains($0) }) {
            return false
        }

        if lowerPath.contains("/contents/helpers/")
            || lowerPath.contains("/contents/frameworks/")
            || lowerPath.contains("/contents/plugins/")
            || lowerPath.contains("/contents/plug-ins/")
            || lowerPath.contains("/contents/xpcservices/")
            || lowerPath.contains(".appex")
            || lowerPath.contains("/library/application support/") {
            return false
        }

        if lowerBundleIdentifier.contains(".helper")
            || lowerBundleIdentifier.contains(".agent")
            || lowerBundleIdentifier.contains(".service")
            || lowerBundleIdentifier.contains(".extension") {
            return false
        }

        return true
    }
}
