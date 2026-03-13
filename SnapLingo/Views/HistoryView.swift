import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: SnapLingoViewModel
    @State private var selectedRecord: LearningRecord?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty {
                    emptyState
                } else {
                    imageGrid
                }
            }
            .background(Color.bg)
            .navigationTitle("学习历史")
        }
        .sheet(item: $selectedRecord) { record in
            HistoryDetailSheet(record: record, viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.subtle)
                .padding(.bottom, 8)
            Text("还没有学习记录")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("拍张照片开始学习吧")
                .font(.system(size: 14))
                .foregroundStyle(Color.subtle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.history) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        historyCard(record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func historyCard(_ record: LearningRecord) -> some View {
        let lang = Language.all.first { $0.code == record.lang }
        return VStack(spacing: 0) {
            if let img = viewModel.loadHistoryImage(record.imageFileName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.border)
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30, weight: .thin))
                            .foregroundStyle(Color.subtle)
                    }
            }

            HStack(spacing: 6) {
                Text(lang?.flag ?? "🌐")
                    .font(.system(size: 14))
                Text("\(record.wordCount)词")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(record.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.subtle)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
    }
}

// MARK: - History Detail Sheet (in-place, no navigation away)

struct HistoryDetailSheet: View {
    let record: LearningRecord
    @Bindable var viewModel: SnapLingoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdx: Int = -1
    @State private var tagPositions: [String: CGPoint] = [:]
    @State private var containerSize: CGSize = .zero

    private var lang: Language? {
        Language.all.first { $0.code == record.lang }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Image with word overlays
                    imageWithTags
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    Text("\(record.words.count) 个单词")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.subtle)
                        .padding(.top, 10)

                    // Word list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(record.words.enumerated()), id: \.element.id) { index, word in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedIdx = index
                                }
                                if let l = lang {
                                    SpeechService.speak(text: word.word, voiceLanguage: l.voiceId)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index == selectedIdx ? Color(hex: "FFD60A") : Color.clear)
                                        .frame(width: 4, height: 48)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(word.word)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(Color.textPrimary)
                                        Text(word.phonetic)
                                            .font(.system(size: 12, design: .monospaced))
                                            .italic()
                                            .foregroundStyle(Color.subtle)
                                    }

                                    Spacer()

                                    Text(word.translation)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.accentSoft)

                                    Button {
                                        if let l = lang {
                                            SpeechService.speak(text: word.word, voiceLanguage: l.voiceId)
                                        }
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.highlight)
                                            .padding(8)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.trailing, 12)
                                .background(index == selectedIdx ? Color(hex: "FFD60A").opacity(0.08) : Color.clear)
                            }
                            .buttonStyle(.plain)

                            if index < record.words.count - 1 {
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.bg)
            .navigationTitle(record.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let l = lang {
                        HStack(spacing: 4) {
                            Text(l.flag)
                            Text(l.label)
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(Color.subtle)
                    }
                }
            }
        }
    }

    private var imageWithTags: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w * 1.2

            ZStack {
                if let img = viewModel.loadHistoryImage(record.imageFileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                ForEach(Array(record.words.enumerated()), id: \.element.id) { index, word in
                    WordTagView(
                        word: word,
                        isSelected: index == selectedIdx,
                        isSaved: viewModel.isSaved(word),
                        position: tagPositions[word.id] ?? CGPoint(x: w / 2, y: h / 2),
                        onTap: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedIdx = index
                            }
                            if let l = lang {
                                SpeechService.speak(text: word.word, voiceLanguage: l.voiceId)
                            }
                        },
                        onSave: { viewModel.toggleSave(word) },
                        onDragEnd: { newPos in tagPositions[word.id] = newPos }
                    )
                }
            }
            .frame(width: w, height: h)
            .onAppear {
                containerSize = CGSize(width: w, height: h)
                assignCircularPositions(width: w, height: h)
            }
        }
        .aspectRatio(1 / 1.2, contentMode: .fit)
    }

    private func assignCircularPositions(width w: CGFloat, height h: CGFloat) {
        let count = record.words.count
        guard count > 0 else { return }
        let cx = w / 2, cy = h / 2
        let rx = w * 0.35, ry = h * 0.35

        for (i, word) in record.words.enumerated() {
            let angle = (2 * .pi / Double(max(count, 1))) * Double(i) - .pi / 2
            tagPositions[word.id] = CGPoint(
                x: cx + CGFloat(cos(angle)) * rx,
                y: cy + CGFloat(sin(angle)) * ry
            )
        }
    }
}
