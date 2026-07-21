import AVFoundation

@MainActor
final class SpeechAnnouncer {
    static let shared = SpeechAnnouncer()

    private let speaker = AVSpeechSynthesizer()

    private init() { }

    func speak(_ text: String) {
        if speaker.isSpeaking { speaker.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48
        speaker.speak(utterance)
    }
}
