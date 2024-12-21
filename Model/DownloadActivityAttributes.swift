import Foundation
import ActivityKit

struct DownloadActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var speed: Double
    }

    var fileID: UUID
    var fileName: String
}
