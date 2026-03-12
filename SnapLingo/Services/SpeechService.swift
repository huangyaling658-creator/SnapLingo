import AVFoundation

@MainActor
final class SpeechService {

    private static let synthesizer = AVSpeechSynthesizer()

    static func speak(text: String, voiceLanguage: String) {
        // Ensure audio session is active
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        utterance.rate = 0.42
        utterance.volume = 1.0
        print("[Speech] Speaking: \"\(text)\" lang=\(voiceLanguage)")
        synthesizer.speak(utterance)
    }

    static func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
