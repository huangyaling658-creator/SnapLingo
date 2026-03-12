import Foundation

struct Word: Codable, Identifiable, Equatable {
    let word: String
    let phonetic: String
    let translation: String
    let example: String?  // Optional — not always returned
    let type: WordType
    let x: Double?
    let y: Double?

    var id: String { "\(word)-\(type.rawValue)" }

    /// Position for overlay on image (with fallback)
    var posX: Double { x ?? Double.random(in: 0.1...0.9) }
    var posY: Double { y ?? Double.random(in: 0.1...0.9) }

    enum WordType: String, Codable {
        case noun
        case adjective
        case verb
        case adverb
        case preposition
        case pronoun
        case conjunction
        case interjection
        case other

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self).lowercased()
            self = WordType(rawValue: raw) ?? .other
        }
    }
}

struct SavedWord: Codable, Identifiable, Equatable {
    let word: String
    let phonetic: String
    let translation: String
    let example: String?
    let type: Word.WordType
    let lang: String
    let savedAt: Date

    var id: String { "\(word)-\(lang)" }

    init(from w: Word, lang: String) {
        self.word = w.word
        self.phonetic = w.phonetic
        self.translation = w.translation
        self.example = w.example
        self.type = w.type
        self.lang = lang
        self.savedAt = Date()
    }
}

struct LearningRecord: Codable, Identifiable, Equatable {
    let id: String
    let date: Date
    let lang: String
    let wordCount: Int
    let words: [Word]
    let imageFileName: String?

    var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: date)
    }

    init(lang: String, words: [Word], imageFileName: String? = nil) {
        self.id = UUID().uuidString
        self.date = Date()
        self.lang = lang
        self.wordCount = words.count
        self.words = words
        self.imageFileName = imageFileName
    }
}
