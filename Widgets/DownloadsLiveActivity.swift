// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import ActivityKit
import WidgetKit
import SwiftUI

struct DownloadsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                ForEach(context.state.items, id: \.uuid) { item in
                    ZStack {
                        AccessoryWidgetBackground()
                        ProgressView(inter)
                        ProgressView(value: item.progress)
                            .progressViewStyle(.circular)
                    }
                }
            }
            .activityBackgroundTint(.clear)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        ForEach(context.state.items, id: \.uuid) { item in
                            Text(item.description)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ProgressView(value: context.state.totalProgress)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.totalProgress)
                }
            } compactLeading: {
                ProgressView(value: context.state.totalProgress)
            } compactTrailing: {
                ProgressView(value: context.state.totalProgress)
            } minimal: {
                ProgressView(value: context.state.totalProgress)
            }
            .widgetURL(URL(string: "https://www.kiwix.org"))
            .keylineTint(Color.red)
        }
    }
}

extension DownloadActivityAttributes {
    fileprivate static var preview: DownloadActivityAttributes {
        DownloadActivityAttributes(title: "Downloads")
    }
}

extension DownloadActivityAttributes.ContentState {
    fileprivate static var midProgress: DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(items: [
            DownloadActivityAttributes.DownloadItem(uuid: UUID(), description: "First item", progress: 0.5),
            DownloadActivityAttributes.DownloadItem(uuid: UUID(), description: "2nd item", progress: 0.9)
        ])
     }
     
     fileprivate static var completed: DownloadActivityAttributes.ContentState {
         DownloadActivityAttributes.ContentState(items: [
            DownloadActivityAttributes.DownloadItem(uuid: UUID(), description: "First item", progress: 1.0),
             DownloadActivityAttributes.DownloadItem(uuid: UUID(), description: "2nd item", progress: 0.8)
         ])
     }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: DownloadActivityAttributes.preview) {
    DownloadsLiveActivity()
} contentStates: {
    DownloadActivityAttributes.ContentState.midProgress
    DownloadActivityAttributes.ContentState.completed
}
