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

import Foundation
import SwiftUI
import Combine

enum DiagState: Equatable {
    case initial
    case running
    case complete(logs: [String])
}

@MainActor
final class GlobalDiagnosticsModel: ObservableObject {
    @Published var state: DiagState
    @Published var items: [DiagnosticItem]
    private var model: DiagnosticsModel
    private var task: Task<Void, Error>?
    private var cancellable: AnyCancellable?
    
    @MainActor
    static let shared = GlobalDiagnosticsModel()
    
    private init() {
        (model, state, items) = Self.resetState()
    }
    
    func start(using zimFiles: [ZimFile]) {
        switch state {
        case .running:
            // cannot start if it's already running
            return
        case .complete:
            // reset all and start
            cancelTask()
            (model, state, items) = Self.resetState()
        case .initial:
            break
        }
        self.task = Task { @MainActor [weak self]  in
            self?.cancellable =  self?.model.$items.sink { [weak self] newItems in
                if !Task.isCancelled {
                    if self?.state != .running {
                        self?.state = .running
                    }
                    self?.items = newItems
                }
            }
            if let model = self?.model {
                let logs = await model.start(using: zimFiles)
                self?.state = .complete(logs: logs)
            }
        }
    }
    
    func cancel() {
        switch state {
        case .complete, .initial:
            // cannot cancel these states
            return
        case .running:
            cancelTask()
            (model, state, items) = Self.resetState()
        }
    }
    
    private static func resetState() -> (DiagnosticsModel, DiagState, [DiagnosticItem]) {
        let model = DiagnosticsModel()
        return (model, DiagState.initial, model.items)
    }
    
    private func cancelTask() {
        if task?.isCancelled == false {
            task?.cancel()
        }
        task = nil
        cancellable?.cancel()
        cancellable = nil
    }
}

