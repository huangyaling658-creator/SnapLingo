import Foundation

struct StorageService {

    private static let fileName = "saved_words.json"

    private static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    static func loadSavedWords() -> [SavedWord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SavedWord].self, from: data)
        } catch {
            print("StorageService load error: \(error)")
            return []
        }
    }

    static func saveSavedWords(_ words: [SavedWord]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(words)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("StorageService save error: \(error)")
        }
    }

    static func addWord(_ word: SavedWord) {
        var words = loadSavedWords()
        words.insert(word, at: 0)
        saveSavedWords(words)
    }

    static func removeWord(word: String, lang: String) {
        var words = loadSavedWords()
        words.removeAll { $0.word == word && $0.lang == lang }
        saveSavedWords(words)
    }

    static func isSaved(word: String, lang: String) -> Bool {
        loadSavedWords().contains { $0.word == word && $0.lang == lang }
    }

    // MARK: - History

    private static let historyFileName = "learning_history.json"

    private static var historyFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(historyFileName)
    }

    static func loadHistory() -> [LearningRecord] {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([LearningRecord].self, from: data)
        } catch {
            print("StorageService history load error: \(error)")
            return []
        }
    }

    static func saveHistory(_ records: [LearningRecord]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("StorageService history save error: \(error)")
        }
    }

    static func addRecord(_ record: LearningRecord) {
        var records = loadHistory()
        records.insert(record, at: 0)
        saveHistory(records)
    }
}
