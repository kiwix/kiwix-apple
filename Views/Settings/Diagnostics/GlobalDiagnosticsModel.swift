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

enum DiagState {
    case initial(items: [DiagnosticItem])
    case running(items: [DiagnosticItem])
    case complete(logs: [String])
}

@MainActor
final class GlobalDiagnosticsModel {
    @Published var state: DiagState
    private var model: DiagnosticsModel
    private var task: Task<Void, Error>?
    private var cancellable: AnyCancellable?
    
    @MainActor
    static let shared = GlobalDiagnosticsModel()
    
    private init() {
        (model, state) = Self.resetState()
    }
    
    func start(using zimFiles: [ZimFile]) {
        switch state {
        case .running:
            return
        case .complete:
            cancelTask()
            (model, state) = Self.resetState()
        case .initial:
            break
        }
        self.task = Task { @MainActor [weak self]  in
            self?.cancellable =  self?.model.$items.sink { [weak self] newItems in
                if !Task.isCancelled {
                    self?.state = .running(items: newItems)
                }
            }
            if let logs = await self?.model.start(using: zimFiles) {
                self?.state = .complete(logs: logs)
            }
        }
    }
    
    private func cancel() {
        switch state {
        case .complete, .initial:
            return
        case .running:
            cancelTask()
            (model, state) = Self.resetState()
        }
    }
    
    private static func resetState() -> (DiagnosticsModel, DiagState) {
        let model = DiagnosticsModel()
        return (model, DiagState.initial(items: model.items))
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

