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

import SwiftUI
import UserNotifications
import Combine
import Defaults
import CoreKiwix

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct Kiwix: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow
    @StateObject private var libraryRefreshViewModel = LibraryViewModel()
    private let notificationCenterDelegate = NotificationCenterDelegate()
    private var amountSelected = PassthroughSubject<SelectedAmount?, Never>()
    @State private var selectedAmount: SelectedAmount?
    @StateObject var formReset = FormReset()
    @FocusState private var isSearchFocused: Bool
    @FocusedValue(\.browserURL) var browserURL
    @StateObject private var colorSchemeStore = UserColorSchemeStore()

    init() {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        if FeatureFlags.hasLibrary {
            LibraryViewModel().start(isUserInitiated: false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(isSearchFocused: $isSearchFocused)
                .environment(\.managedObjectContext, Database.shared.viewContext)
                .environmentObject(libraryRefreshViewModel)
                .task {
                    colorSchemeStore.update()
                }
        }.commands {
            SidebarCommands()
            CommandGroup(replacing: .importExport) {
                OpenFileButton(context: .command) { Text(LocalString.app_macos_commands_open_file) }
            }
            CommandGroup(replacing: .newItem) {
                Button(LocalString.app_macos_commands_new) {
                    guard let currentWindow = NSApp.keyWindow,
                          let controller = currentWindow.windowController else { return }
                    controller.newWindowForTab(nil)
                    guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
                    currentWindow.addTabbedWindow(newWindow, ordered: .above)
                }.keyboardShortcut("t")
                Divider()
            }
            CommandGroup(after: .toolbar) {
                NavigationCommands(goBack: {
                    NotificationCenter.default.post(name: .goBack, object: nil)
                }, goForward: {
                    NotificationCenter.default.post(name: .goForward, object: nil)
                })
                Divider()
                PageZoomCommands()
                Divider()
                SidebarNavigationCommands()
                Divider()
            }
            CommandGroup(after: .pasteboard) {
                Button(LocalString.library_zim_file_context_copy_url) {
                    if let browserURL {
                        CopyPasteMenu.copyToPasteBoard(url: browserURL)
                    }
                }
                .disabled(browserURL == nil)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                    
            }
            CommandGroup(after: .textEditing) {
                Button(LocalString.common_search) {
                    isSearchFocused = true
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
            CommandGroup(replacing: .help) {}
        }

        Settings {
            TabView {
                ReadingSettings()
                    .environmentObject(colorSchemeStore)
                if FeatureFlags.hasLibrary {
                    LibrarySettings()
                        .environmentObject(libraryRefreshViewModel)
                    HotspotSettings()
                }
                About()
            }
            .frame(width: 550, height: 400)
        }
        .handlesExternalEvents(matching: [])
        
        Window(LocalString.payment_donate_title, id: "donation") {
            Group {
                if let selectedAmount {
                    PaymentSummary(selectedAmount: selectedAmount, onComplete: {
                        closeDonation()
                        switch Payment.showResult() {
                        case .none: break
                        case .thankYou:
                            openWindow(id: "donation-thank-you")
                        case .error:
                            openWindow(id: "donation-error")
                        }
                    })
                } else {
                    PaymentForm(amountSelected: amountSelected)
                        .frame(width: 320, height: 320)
                }
            }
            .onReceive(amountSelected) { amount in
                selectedAmount = amount
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow,
                   window.identifier?.rawValue == "donation" {
                    formReset.reset()
                    selectedAmount = nil
                }
            }
            .environmentObject(formReset)
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .commandsRemoved()
        .defaultSize(width: 320, height: 400)
        .restorationBehaviourDisabled()
        .handlesExternalEvents(matching: [])

        Window("", id: "donation-thank-you") {
            PaymentResultPopUp(state: .thankYou)
                .padding()
        }
        .windowResizability(.contentMinSize)
        .commandsRemoved()
        .defaultSize(width: 320, height: 198)
        .restorationBehaviourDisabled()
        .handlesExternalEvents(matching: [])

        Window("", id: "donation-error") {
            PaymentResultPopUp(state: .error)
                .padding()
        }
        .windowResizability(.contentMinSize)
        .commandsRemoved()
        .defaultSize(width: 320, height: 198)
        .restorationBehaviourDisabled()
        .handlesExternalEvents(matching: [])
    }

    private func closeDonation() {
        // after upgrading to macOS 14, use:
        // @Environment(\.dismissWindow) var dismissWindow
        // and call:
        // dismissWindow(id: "donation")
        NSApplication.shared.windows.first { window in
            window.identifier?.rawValue == "donation"
        }?.close()
    }
}

#endif
