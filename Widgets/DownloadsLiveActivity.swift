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
                        titleFor(context.state.title)
                        progressFor(state: context.state, timeInterval: timeInterval)
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
                    let timeInterval = startTime...Date(
                        timeInterval: context.state.estimatedTimeLeft,
                        since: .now
                    )
                    
                    VStack(alignment: .leading) {
                        titleFor(context.state.title)
                        progressFor(state: context.state, timeInterval: timeInterval)
                        Spacer()
                    }
                    .padding()
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    KiwixLogo(maxHeight: 50)
                        .padding()
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
    
    @ViewBuilder
    private func titleFor(_ title: String) -> some View {
        Text(title)
            .lineLimit(1)
            .frame(minWidth: 150, alignment: .leading)
            .font(.headline)
            .bold()
    }
    
    @ViewBuilder
    private func progressText(_ description: String) -> some View {
        Text(description)
            .lineLimit(1)
            .font(.caption)
            .tint(.secondary)
    }
    
    @ViewBuilder
    private func progressFor(
        state: DownloadActivityAttributes.ContentState,
        timeInterval: ClosedRange<Date>
    ) -> some View {
        if !state.isAllPaused {
            ProgressView(timerInterval: timeInterval, countsDown: false, label: {
                progressText(state.progressDescription)
            }, currentValueLabel: {
                Text(timerInterval: timeInterval)
                    .font(.caption)
                    .tint(.secondary)
            })
            .tint(Color.primary)
        } else {
            ProgressView(value: state.progress, label: {
                progressText(state.progressDescription)
            }, currentValueLabel: {
                Label("", systemImage: "pause.fill")
                    .font(.caption)
                    .tint(.secondary)
            })
            .tint(Color.primary)
        }
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
                    timeRemaining: 15,
                    isPaused: true
                ),
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "2nd item",
                    downloaded: 90,
                    total: 124,
                    timeRemaining: 2,
                    isPaused: true
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
                    timeRemaining: 0,
                    isPaused: false
                ),
                DownloadActivityAttributes.DownloadItem(
                    uuid: UUID(),
                    description: "2nd item",
                    downloaded: 110,
                    total: 124,
                    timeRemaining: 2,
                    isPaused: false
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
