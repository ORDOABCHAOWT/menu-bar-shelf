import Foundation

public enum AppActivationStep: Equatable, Sendable {
    case unhide
    case yieldActivation
    case activate(allWindows: Bool)
    case openBundle(path: String)
}

public struct AppActivationPlan: Equatable, Sendable {
    public let steps: [AppActivationStep]

    public init(steps: [AppActivationStep]) {
        self.steps = steps
    }

    public static func foregroundPlan(for app: AppDescriptor) -> AppActivationPlan {
        var steps: [AppActivationStep] = [
            .unhide,
            .yieldActivation,
            .activate(allWindows: true)
        ]

        if let bundlePath = app.bundlePath, !bundlePath.isEmpty {
            steps.append(.openBundle(path: bundlePath))
        }

        return AppActivationPlan(steps: steps)
    }
}
