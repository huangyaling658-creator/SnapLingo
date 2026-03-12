import Foundation

nonisolated struct Language: Identifiable, Equatable, Sendable {
    let code: String
    let label: String
    let flag: String
    let voiceId: String

    var id: String { code }

    /// Full name for Gemini prompt
    var englishName: String {
        switch code {
        case "en": return "English"
        case "ja": return "Japanese"
        case "fr": return "French"
        case "es": return "Spanish"
        case "ko": return "Korean"
        case "de": return "German"
        default: return "English"
        }
    }

    static let all: [Language] = [
        Language(code: "en", label: "英语", flag: "🇬🇧", voiceId: "en-US"),
        Language(code: "ja", label: "日语", flag: "🇯🇵", voiceId: "ja-JP"),
        Language(code: "fr", label: "法语", flag: "🇫🇷", voiceId: "fr-FR"),
        Language(code: "es", label: "西语", flag: "🇪🇸", voiceId: "es-ES"),
        Language(code: "ko", label: "韩语", flag: "🇰🇷", voiceId: "ko-KR"),
        Language(code: "de", label: "德语", flag: "🇩🇪", voiceId: "de-DE"),
    ]
}
