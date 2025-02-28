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
//    @Environment(\.isActivityFullscreen) var isActivityFullScreen has a bug, when min iOS is 16
//    https://developer.apple.com/forums/thread/763594
    
    /// A start time from the creation of the activity,
    /// this way the progress bar is not jumping back to 0
    private let startTime: Date = .now
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            // Lock screen/banner UI
            let timeInterval = startTime...Date(
                timeInterval: context.state.estimatedTimeLeft,
                since: .now
            )
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(context.state.title)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                            .bold()
                        ProgressView(timerInterval: timeInterval, countsDown: false, label: {
                            Text(context.state.progressDescription)
                                .lineLimit(1)
                                .font(.caption)
                                .tint(.secondary)
                        }, currentValueLabel: {
                            Text(timerInterval: timeInterval)
                                .font(.caption)
                                .tint(.secondary)
                        })
                        .tint(Color.primary)
                    }
                    .padding()
                    KiwixLogo(maxHeight: 50)
                        .padding(.trailing)
                }
            }
            .modifier(WidgetBackgroundModifier())
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Spacer()
                    KiwixLogo(maxHeight: 50)
                    Spacer()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(CircularProgressGaugeStyle(lineWidth: 11.4))
                        .padding(6.0)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.state.title)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                            .bold()
                        Text(context.state.progressDescription)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
                            .tint(.secondary)
                    }
                }
            } compactLeading: {
                KiwixLogo()
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(CircularProgressGaugeStyle(lineWidth: 5.7))
                    .frame(width: 20, height: 20, alignment: .trailing)
                
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(CircularProgressGaugeStyle(lineWidth: 5.7))
                    .frame(width: 24, height: 24)
            }
            .widgetURL(URL(string: "https://www.kiwix.org"))
            .keylineTint(Color.red)
        }.containerBackgroundRemovable()
    }
}

extension DownloadActivityAttributes {
    fileprivate static var preview: DownloadActivityAttributes {
        DownloadActivityAttributes()
    }
}

extension DownloadActivityAttributes.ContentState {
    fileprivate static var midProgress: DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            downloadingTitle: "Downloading...",
            items: [
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "First item",
                    downloaded: 128,
                    total: 256,
                    timeRemaining: 15
                ),
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "2nd item",
                    downloaded: 90,
                    total: 124,
                    timeRemaining: 2
                )
            ]
        )
    }
    
    fileprivate static var completed: DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            downloadingTitle: "Downloading...",
            items: [
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "First item",
                    downloaded: 256,
                    total: 256,
                    timeRemaining: 0
                ),
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "2nd item",
                    downloaded: 110,
                    total: 124,
                    timeRemaining: 2
                )
            ]
        )
    }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: DownloadActivityAttributes.preview) {
    DownloadsLiveActivity()
} contentStates: {
    DownloadActivityAttributes.ContentState.midProgress
    DownloadActivityAttributes.ContentState.completed
}

@available(iOS 18.0, *)
#Preview("Compact", as: .dynamicIsland(.compact), using: DownloadActivityAttributes.preview) {
    DownloadsLiveActivity()
} contentStates: {
    DownloadActivityAttributes.ContentState.midProgress
    DownloadActivityAttributes.ContentState.completed
}

@available(iOS 18.0, *)
#Preview("Minimal", as: .dynamicIsland(.minimal), using: DownloadActivityAttributes.preview) {
    DownloadsLiveActivity()
} contentStates: {
    DownloadActivityAttributes.ContentState.midProgress
    DownloadActivityAttributes.ContentState.completed
}

@available(iOS 18.0, *)
#Preview("Dynamic island", as: .dynamicIsland(.expanded), using: DownloadActivityAttributes.preview) {
    DownloadsLiveActivity()
} contentStates: {
    DownloadActivityAttributes.ContentState.midProgress
    DownloadActivityAttributes.ContentState.completed
}
