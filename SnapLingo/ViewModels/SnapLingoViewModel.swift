import SwiftUI
import PhotosUI

@Observable
final class SnapLingoViewModel {

    // MARK: - State

    var currentPage: Page = .home
    var selectedLanguage: Language = Language.all[0]
    var capturedImage: UIImage?
    var words: [Word] = []
    var savedWords: [SavedWord] = []
    var history: [LearningRecord] = []
    var isAnalyzing = false
    var analysisStatus: String = "AI 识别中…"
    var errorMessage: String?
    var showError = false
    var showLanguagePicker = false
    var selectedWordIndex: Int = -1

    enum Page { case home, results, wordbook }

    init() {
        savedWords = StorageService.loadSavedWords()
        history = StorageService.loadHistory()
    }

    // MARK: - Image (auto-trigger analysis)

    func setImageAndAnalyze(_ image: UIImage) {
        capturedImage = image
        words = []
        errorMessage = nil
        selectedWordIndex = -1
        analyzeImage()
    }

    func clearImage() {
        capturedImage = nil
        words = []
        errorMessage = nil
        selectedWordIndex = -1
    }

    // MARK: - Streaming Analyze

    func analyzeImage() {
        guard let image = capturedImage, !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        words = []
        selectedWordIndex = -1
        analysisStatus = "正在压缩图片…"

        Task {
            do {
                print("[SnapLingo] Original: \(Int(image.size.width))x\(Int(image.size.height))")
                let data = compressImage(image)

                analysisStatus = "AI 识别中…"
                currentPage = .results  // Show results page immediately

                let result = try await GeminiService.analyzeImageStreaming(
                    imageData: data,
                    mimeType: "image/jpeg",
                    targetLang: selectedLanguage
                ) { [weak self] word in
                    Task { @MainActor in
                        guard let self else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.words.append(word)
                        }
                    }
                }

                isAnalyzing = false

                // Save image to Documents for history
                let imageFileName = saveImageForHistory(image)

                // Save to history
                let record = LearningRecord(lang: selectedLanguage.code, words: result, imageFileName: imageFileName)
                history.insert(record, at: 0)
                StorageService.addRecord(record)
            } catch {
                print("[SnapLingo] ❌ Analysis failed: \(error)")
                errorMessage = error.localizedDescription
                showError = true
                isAnalyzing = false
                currentPage = .home
            }
        }
    }

    /// Save image for history (larger for detail view)
    private func saveImageForHistory(_ image: UIImage) -> String? {
        let fileName = "history_\(UUID().uuidString).jpg"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent(fileName)

        let maxDim: CGFloat = 800  // larger for detail view
        let longer = max(image.size.width, image.size.height)
        var img = image
        if longer > maxDim {
            let scale = maxDim / longer
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            img = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        }

        if let data = img.jpegData(compressionQuality: 0.7) {
            try? data.write(to: fileURL)
            return fileName
        }
        return nil
    }

    /// Load history image by filename
    func loadHistoryImage(_ fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Compress image aggressively for fast mobile upload
    private func compressImage(_ image: UIImage) -> Data {
        let maxBytes = 150 * 1024
        let maxDimension: CGFloat = 512

        var img = image
        let longer = max(image.size.width, image.size.height)
        if longer > maxDimension {
            let scale = maxDimension / longer
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            img = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
            print("[SnapLingo] Resized → \(Int(newSize.width))x\(Int(newSize.height))")
        }

        var quality: CGFloat = 0.5
        var data = img.jpegData(compressionQuality: quality) ?? Data()
        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            data = img.jpegData(compressionQuality: quality) ?? Data()
        }
        print("[SnapLingo] Compressed: q=\(String(format: "%.1f", quality)), \(data.count / 1024)KB")
        return data
    }

    // MARK: - Save / Unsave

    func toggleSave(_ word: Word) {
        let lang = selectedLanguage.code
        if let idx = savedWords.firstIndex(where: { $0.word == word.word && $0.lang == lang }) {
            savedWords.remove(at: idx)
        } else {
            savedWords.insert(SavedWord(from: word, lang: lang), at: 0)
        }
        StorageService.saveSavedWords(savedWords)
    }

    func isSaved(_ word: Word) -> Bool {
        savedWords.contains { $0.word == word.word && $0.lang == selectedLanguage.code }
    }

    func removeSavedWord(word: String, lang: String) {
        savedWords.removeAll { $0.word == word && $0.lang == lang }
        StorageService.saveSavedWords(savedWords)
    }

    // MARK: - Speech

    func speak(_ text: String) {
        SpeechService.speak(text: text, voiceLanguage: selectedLanguage.voiceId)
    }

    func speakWithVoice(_ text: String, voiceId: String) {
        SpeechService.speak(text: text, voiceLanguage: voiceId)
    }

    // MARK: - Navigation

    func goHome() { currentPage = .home }
    func goResults() { currentPage = .results }
    func goWordbook() { currentPage = .wordbook }

    func resetForNewPhoto() {
        capturedImage = nil
        words = []
        errorMessage = nil
        selectedWordIndex = -1
        currentPage = .home
    }

    // MARK: - Language

    func selectLanguage(_ lang: Language) {
        selectedLanguage = lang
        words = []
        showLanguagePicker = false
    }

    // MARK: - Delete history record

    func deleteRecord(_ record: LearningRecord) {
        // Remove image file
        if let fileName = record.imageFileName {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docs.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        // Remove from array and persist
        history.removeAll { $0.id == record.id }
        StorageService.saveHistory(history)
    }

    // MARK: - Load history record

    func loadRecord(_ record: LearningRecord) {
        if let fileName = record.imageFileName {
            capturedImage = loadHistoryImage(fileName)
        }
        words = record.words
        selectedWordIndex = -1
        if let lang = Language.all.first(where: { $0.code == record.lang }) {
            selectedLanguage = lang
        }
        currentPage = .results
    }
}
