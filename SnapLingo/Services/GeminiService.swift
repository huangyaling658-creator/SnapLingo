import Foundation

nonisolated struct GeminiService {

    private static let apiKey = "sk-pipfkpxaarpyclfgctzlhedskgmuejoaybpvdvmzhcfitjzj"
    private static let model = "Pro/Qwen/Qwen2.5-VL-7B-Instruct"
    private static let baseURL = "https://api.siliconflow.cn/v1/chat/completions"

    enum GeminiError: LocalizedError {
        case invalidResponse
        case apiError(String)
        case decodingFailed(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "AI 服务无响应，请重试"
            case .apiError(let msg): return "AI 识别失败：\(msg)"
            case .decodingFailed(let msg): return "结果解析失败：\(msg)"
            case .timeout: return "请求超时，请检查网络后重试"
            }
        }
    }

    // MARK: - Streaming Analysis (words appear one by one)

    /// Streams words from AI — calls `onWord` each time a complete word object is parsed
    static func analyzeImageStreaming(
        imageData: Data,
        mimeType: String,
        targetLang: Language,
        onWord: @Sendable @escaping (Word) -> Void
    ) async throws -> [Word] {
        let base64 = imageData.base64EncodedString()
        let langName = targetLang.englishName
        let dataURI = "data:\(mimeType);base64,\(base64)"

        print("[SnapLingo] 📷 Image: \(imageData.count / 1024)KB → base64: \(base64.count / 1024)KB")

        // Language-specific examples for few-shot
        let example: String
        switch targetLang.code {
        case "ja": example = #"[{"word":"ねこ","phonetic":"/neko/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"おおきい","phonetic":"/oːkiː/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        case "ko": example = #"[{"word":"고양이","phonetic":"/gojaŋi/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"큰","phonetic":"/kʰɯn/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        case "fr": example = #"[{"word":"chat","phonetic":"/ʃa/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"grand","phonetic":"/ɡʁɑ̃/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        case "es": example = #"[{"word":"gato","phonetic":"/ˈɡato/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"grande","phonetic":"/ˈɡɾande/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        case "de": example = #"[{"word":"Katze","phonetic":"/ˈkatsə/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"groß","phonetic":"/ɡʁoːs/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        default:   example = #"[{"word":"cat","phonetic":"/kæt/","translation":"猫","type":"noun","x":0.5,"y":0.3},{"word":"big","phonetic":"/bɪɡ/","translation":"大的","type":"adjective","x":0.2,"y":0.6}]"#
        }

        let userPrompt = """
        Look at this image. Identify objects, scenes, and any text you see.
        For each item, provide the \(langName) word (NOT Chinese, NOT the original text in the image).
        If there is Chinese text in the image, you must TRANSLATE it into \(langName).

        Return 6 words as JSON array. Example format:
        \(example)

        RULES:
        - "word" = \(langName) ONLY. Never Chinese. Never mixed languages.
        - "translation" = Chinese ONLY.
        - x/y = float 0-1, position on image.
        - Output ONLY the JSON array.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": ["url": dataURI]],
                        ["type": "text", "text": userPrompt]
                    ]
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.1,
            "stream": true
        ]

        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("[SnapLingo] 🚀 Streaming request: \((request.httpBody?.count ?? 0) / 1024)KB")

        let startTime = Date()
        var allWords: [Word] = []
        var buffer = ""
        var firstWordTime: TimeInterval?

        let (stream, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (stream, response) = try await URLSession.shared.bytes(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw GeminiError.timeout
        } catch {
            throw GeminiError.apiError("网络错误：\(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw GeminiError.apiError("HTTP \(code)")
        }

        // Read SSE stream line by line
        for try await line in stream.lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("data: ") else { continue }
            let dataStr = String(trimmed.dropFirst(6))
            if dataStr == "[DONE]" { break }

            guard let chunkData = dataStr.data(using: .utf8),
                  let chunk = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any],
                  let choices = chunk["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else { continue }

            buffer += content

            // Try to extract complete word objects from buffer
            while let word = extractNextWord(from: &buffer) {
                if firstWordTime == nil {
                    firstWordTime = Date().timeIntervalSince(startTime)
                    print("[SnapLingo] ⚡ First word in \(String(format: "%.1f", firstWordTime!))s: \(word.word)")
                }
                allWords.append(word)
                onWord(word)
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        print("[SnapLingo] ✅ Stream done: \(allWords.count) words in \(String(format: "%.1f", elapsed))s")

        // If streaming parse failed, try parsing the full buffer
        if allWords.isEmpty && !buffer.isEmpty {
            print("[SnapLingo] 🔧 Fallback: parsing full buffer")
            allWords = parseFullResponse(buffer)
            for w in allWords { onWord(w) }
        }

        return allWords
    }

    // MARK: - Parse helpers

    /// Extract the next complete JSON object {...} from the buffer
    private static func extractNextWord(from buffer: inout String) -> Word? {
        guard let startIdx = buffer.firstIndex(of: "{") else { return nil }
        var depth = 0
        var endIdx: String.Index?
        for i in buffer.indices[startIdx...] {
            if buffer[i] == "{" { depth += 1 }
            if buffer[i] == "}" { depth -= 1 }
            if depth == 0 { endIdx = i; break }
        }
        guard let end = endIdx else { return nil }

        let objectStr = String(buffer[startIdx...end])
        buffer = String(buffer[buffer.index(after: end)...])

        guard let data = objectStr.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(Word.self, from: data)
        } catch {
            print("[SnapLingo] ⚠️ Word decode failed: \(error)")
            print("[SnapLingo] ⚠️ Object: \(objectStr.prefix(200))")
            return nil
        }
    }

    /// Fallback: parse the full response text as JSON array
    private static func parseFullResponse(_ text: String) -> [Word] {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip markdown fences
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        // Find JSON array
        if !cleaned.hasPrefix("[") {
            if let s = cleaned.firstIndex(of: "["), let e = cleaned.lastIndex(of: "]") {
                cleaned = String(cleaned[s...e])
            }
        }
        guard let data = cleaned.data(using: .utf8) else { return [] }

        // Try structured Word objects first
        if let words = try? JSONDecoder().decode([Word].self, from: data), !words.isEmpty {
            return words
        }

        // Fallback: handle simple string array like ["house","tree","sun"]
        if let strings = try? JSONDecoder().decode([String].self, from: data) {
            print("[SnapLingo] 🔧 Converting string array to Word objects")
            return strings.enumerated().map { i, s in
                let angle = (2.0 * Double.pi / Double(max(strings.count, 1))) * Double(i)
                return Word(
                    word: s, phonetic: "", translation: "",
                    type: .noun,
                    x: 0.5 + cos(angle) * 0.35,
                    y: 0.5 + sin(angle) * 0.35
                )
            }
        }

        return []
    }
}
