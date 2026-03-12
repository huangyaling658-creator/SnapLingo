import SwiftUI

struct WordbookView: View {
    @Bindable var viewModel: SnapLingoViewModel
    @State private var searchText = ""
    @State private var filterLang = "all"

    private var availableLanguages: [String] {
        Array(Set(viewModel.savedWords.map(\.lang))).sorted()
    }

    private var filteredWords: [SavedWord] {
        viewModel.savedWords.filter { word in
            let langMatch = filterLang == "all" || word.lang == filterLang
            let searchMatch = searchText.isEmpty
                || word.word.localizedCaseInsensitiveContains(searchText)
                || word.translation.contains(searchText)
            return langMatch && searchMatch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Language filter
                if availableLanguages.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterButton(code: "all", label: "全部")
                            ForEach(availableLanguages, id: \.self) { code in
                                if let lang = Language.all.first(where: { $0.code == code }) {
                                    filterButton(code: code, label: "\(lang.flag) \(lang.label)")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }

                // Word list
                ScrollView {
                    if filteredWords.isEmpty {
                        emptyState
                            .padding(.top, 70)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                                WordbookRow(
                                    word: word,
                                    onSpeak: {
                                        if let lang = Language.all.first(where: { $0.code == word.lang }) {
                                            viewModel.speakWithVoice(word.word, voiceId: lang.voiceId)
                                        }
                                    },
                                    onDelete: {
                                        viewModel.removeSavedWord(word: word.word, lang: word.lang)
                                    }
                                )
                                .modifier(AppearAnimationModifier(delay: Double(index) * 0.04))
                            }
                        }
                        .padding(16)
                    }
                }
                .background(Color.bg)
            }
            .navigationTitle("单词本")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索单词或中文…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(viewModel.savedWords.count) 词")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.subtle)
                }
            }
        }
    }

    // MARK: - Filter Button

    private func filterButton(code: String, label: String) -> some View {
        Button {
            filterLang = code
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(filterLang == code ? .white : Color.accentSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(filterLang == code ? Color.textPrimary : Color.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.border, lineWidth: 1))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: viewModel.savedWords.isEmpty ? "bookmark" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.subtle)
                .padding(.bottom, 12)

            Text(viewModel.savedWords.isEmpty ? "还没有收藏的单词" : "没有找到匹配结果")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentSoft)

            Text(viewModel.savedWords.isEmpty ? "拍张照片，开始收集吧" : "换个关键词试试")
                .font(.system(size: 13))
                .foregroundStyle(Color.subtle)
        }
    }
}
