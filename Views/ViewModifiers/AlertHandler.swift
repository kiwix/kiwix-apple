import SwiftUI
import ActivityKit

struct AlertHandler: ViewModifier {
    @State private var activeAlert: ActiveAlert?

    private let alert = NotificationCenter.default.publisher(for: .alert)

    func body(content: Content) -> some View {
        content.onReceive(alert) { notification in
            guard let rawValue = notification.userInfo?["rawValue"] as? String else { return }
            activeAlert = ActiveAlert(rawValue: rawValue)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .articleFailedToLoad:
                return Alert(title: Text("alert_handler.alert.failed.title".localized))
            case .downloadFailed:
                return Alert(title: Text("download_service.failed.description".localized))
            }
        }
        .onAppear {
            // Handle Live Activities alerts
            Task {
                for activity in Activity<DownloadActivityAttributes>.activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
}
