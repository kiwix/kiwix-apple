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
import AVFoundation

@MainActor
final class TextToSpeech {
    
    @Published
    var isStarted: Bool = false
    
    @MainActor
    static let shared = TextToSpeech()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {
    }
    
    func start(for text: String, languageCode: String) {
        guard !isStarted else {
            pause()
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.3
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        isStarted = true
    }
    
    private func pause() {
        synthesizer.stopSpeaking(at: .immediate)
        isStarted = false
    }
}
