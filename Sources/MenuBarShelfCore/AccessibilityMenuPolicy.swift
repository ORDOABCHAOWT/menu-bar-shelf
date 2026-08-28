import Foundation

public enum AccessibilityPermissionState: Equatable, Sendable {
    case unavailable
    case untrusted
    case trusted
}

public enum AccessibilityMenuItem: Equatable, Sendable {
    case status(title: String, symbolName: String)
    case requestPermission(title: String, symbolName: String)
    case openSettings(title: String, symbolName: String)
}

public enum AccessibilityMenuPolicy {
    public static func items(for state: AccessibilityPermissionState) -> [AccessibilityMenuItem] {
        switch state {
        case .unavailable:
            return [
                .status(title: "辅助功能增强：未启用", symbolName: "shield.slash")
            ]
        case .untrusted:
            return [
                .status(title: "辅助功能增强：关", symbolName: "shield"),
                .requestPermission(title: "请求辅助功能权限", symbolName: "hand.raised"),
                .openSettings(title: "打开系统设置", symbolName: "gearshape")
            ]
        case .trusted:
            return [
                .status(title: "辅助功能增强：开", symbolName: "checkmark.shield"),
                .openSettings(title: "打开系统设置", symbolName: "gearshape")
            ]
        }
    }
}
