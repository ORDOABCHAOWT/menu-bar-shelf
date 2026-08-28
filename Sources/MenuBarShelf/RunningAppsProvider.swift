import AppKit
import MenuBarShelfCore

struct RunningAppEntry {
    let descriptor: AppDescriptor
    let runningApplication: NSRunningApplication
}

final class AppMenuPayload: NSObject {
    let descriptor: AppDescriptor
    let runningApplication: NSRunningApplication

    init(entry: RunningAppEntry) {
        self.descriptor = entry.descriptor
        self.runningApplication = entry.runningApplication
    }
}

struct RunningAppsProvider {
    func entries() -> [RunningAppEntry] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard let name = app.localizedName, !name.isEmpty else {
                return nil
            }

            return RunningAppEntry(
                descriptor: AppDescriptor(
                    bundleIdentifier: app.bundleIdentifier,
                    localizedName: name,
                    bundlePath: app.bundleURL?.path,
                    activationPolicy: app.activationPolicy.asCorePolicy,
                    isFinishedLaunching: app.isFinishedLaunching,
                    processIdentifier: app.processIdentifier
                ),
                runningApplication: app
            )
        }
    }
}

private extension NSApplication.ActivationPolicy {
    var asCorePolicy: ActivationPolicy {
        switch self {
        case .regular:
            return .regular
        case .accessory:
            return .accessory
        case .prohibited:
            return .prohibited
        @unknown default:
            return .prohibited
        }
    }
}
