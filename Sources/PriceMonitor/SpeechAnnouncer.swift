import AVFoundation
import UserNotifications

enum AnnouncementCategory {
    case product
    case balance
}

struct SpeechVoiceChoice: Identifiable {
    let id: String
    let name: String
    let language: String
    let style: String?

    var displayName: String {
        style.map { "\(name) · \($0)" } ?? "\(name) · \(language)"
    }
}

@MainActor
final class SpeechAnnouncer {
    static let shared = SpeechAnnouncer()

    private let speaker = AVSpeechSynthesizer()

    private init() { }

    private static let recommendedStyles: [String: (order: Int, style: String)] = [
        "Tingting": (0, "自然女声"),
        "Flo": (1, "轻柔女声"),
        "Sandy": (2, "明亮女声"),
        "Shelley": (3, "柔和女声"),
        "Reed": (4, "沉稳男声"),
        "Eddy": (5, "活力男声")
    ]

    private static let installedChineseVoices = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language.hasPrefix("zh") }

    static let recommendedVoiceChoices: [SpeechVoiceChoice] = installedChineseVoices
        .filter { $0.language == "zh-CN" && recommendedStyles[$0.name] != nil }
        .map {
            SpeechVoiceChoice(
                id: $0.identifier,
                name: $0.name,
                language: $0.language,
                style: recommendedStyles[$0.name]?.style
            )
        }
        .sorted { (recommendedStyles[$0.name]?.order ?? 99) < (recommendedStyles[$1.name]?.order ?? 99) }

    static let otherVoiceChoices: [SpeechVoiceChoice] = installedChineseVoices
        .filter { voice in !recommendedVoiceChoices.contains(where: { $0.id == voice.identifier }) }
        .map { SpeechVoiceChoice(id: $0.identifier, name: $0.name, language: $0.language, style: nil) }
        .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }

    func alert(title: String, body: String, category: AnnouncementCategory, spokenBody: String? = nil) {
        if MonitorPreference.bool(MonitorPreference.notificationsEnabled) {
            sendNotification(title: title, body: body)
        }

        let categoryEnabled = switch category {
        case .product: MonitorPreference.bool(MonitorPreference.speakProductUpdates)
        case .balance: MonitorPreference.bool(MonitorPreference.speakBalanceUpdates)
        }
        guard MonitorPreference.bool(MonitorPreference.speechEnabled, default: false), categoryEnabled else { return }

        let text = spokenBody ?? body
        guard !text.isEmpty else { return }
        speak("\(title)。\(text)")
    }

    func preview() {
        speak("这是价格监控语音试听。商品上架时，可以播报店铺、商品名称和价格。")
    }

    private func speak(_ text: String) {
        if speaker.isSpeaking { speaker.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        let identifier = UserDefaults.standard.string(forKey: MonitorPreference.speechVoiceIdentifier) ?? ""
        utterance.voice = identifier.isEmpty
            ? AVSpeechSynthesisVoice(language: "zh-CN")
            : AVSpeechSynthesisVoice(identifier: identifier)
        utterance.rate = 0.48
        speaker.speak(utterance)
    }

    private func sendNotification(title: String, body: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            let granted: Bool
            switch settings.authorizationStatus {
            case .notDetermined:
                granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            case .authorized, .provisional, .ephemeral:
                granted = true
            default:
                granted = false
            }
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            // 系统通知保持静默；是否语音播报由独立设置控制。
            content.sound = nil
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            try? await center.add(request)
        }
    }
}
