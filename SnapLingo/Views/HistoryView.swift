import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: SnapLingoViewModel
    @State private var selectedRecord: LearningRecord?
    @State private var recordToDelete: LearningRecord?
    @State private var showDeleteConfirm = false

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
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                if let record = recordToDelete {
                    viewModel.deleteRecord(record)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，确定要删除这条学习记录吗？")
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
                    .contextMenu {
                        Button(role: .destructive) {
                            recordToDelete = record
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
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
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var savedToAlbum = false
    @State private var showDeleteConfirm = false

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

                    // Word list — entire row tappable for speech
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

                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.highlight)
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
                    HStack(spacing: 12) {
                        // Save to album — text only
                        Button {
                            let img = generateShareImage()
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                            savedToAlbum = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedToAlbum = false }
                        } label: {
                            Text(savedToAlbum ? "已保存" : "保存")
                                .font(.system(size: 15))
                                .foregroundStyle(savedToAlbum ? .green : Color.highlight)
                        }

                        // Share — text only
                        Button {
                            shareImage = generateShareImage()
                            showShareSheet = true
                        } label: {
                            Text("分享")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.highlight)
                        }

                        // Delete
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("删除")
                                .font(.system(size: 15))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                viewModel.deleteRecord(record)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，确定要删除这条学习记录吗？")
        }
    }

    // MARK: - Generate share image with word tags

    private func generateShareImage() -> UIImage {
        let baseImage = viewModel.loadHistoryImage(record.imageFileName)
        let canvasW: CGFloat = 400
        let canvasH: CGFloat = 480
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH))
        return renderer.image { _ in
            // Draw base image
            baseImage?.draw(in: CGRect(x: 0, y: 0, width: canvasW, height: canvasH))

            // Draw word tags
            let count = record.words.count
            for (i, word) in record.words.enumerated() {
                let px: CGFloat
                let py: CGFloat
                if let x = word.x, let y = word.y {
                    px = 40 + CGFloat(x) * (canvasW - 80)
                    py = 40 + CGFloat(y) * (canvasH - 80)
                } else {
                    let angle = (2 * .pi / Double(max(count, 1))) * Double(i) - .pi / 2
                    px = canvasW / 2 + CGFloat(cos(angle)) * canvasW * 0.3
                    py = canvasH / 2 + CGFloat(sin(angle)) * canvasH * 0.3
                }

                let tagW: CGFloat = 90, tagH: CGFloat = 52
                let tagRect = CGRect(x: px - tagW / 2, y: py - tagH / 2, width: tagW, height: tagH)

                UIBezierPath(roundedRect: tagRect, cornerRadius: 8).fill(with: .normal, alpha: 0.95)
                UIColor(red: 1, green: 0.84, blue: 0.04, alpha: 0.95).setFill()
                UIBezierPath(roundedRect: tagRect, cornerRadius: 8).fill()

                let wordAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.black]
                let ws = (word.word as NSString).size(withAttributes: wordAttr)
                (word.word as NSString).draw(at: CGPoint(x: tagRect.midX - ws.width / 2, y: tagRect.minY + 5), withAttributes: wordAttr)

                let phoneticAttr: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 9), .foregroundColor: UIColor.darkGray]
                let ps = (word.phonetic as NSString).size(withAttributes: phoneticAttr)
                (word.phonetic as NSString).draw(at: CGPoint(x: tagRect.midX - ps.width / 2, y: tagRect.minY + 21), withAttributes: phoneticAttr)

                let transAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
                let ts = (word.translation as NSString).size(withAttributes: transAttr)
                (word.translation as NSString).draw(at: CGPoint(x: tagRect.midX - ts.width / 2, y: tagRect.minY + 35), withAttributes: transAttr)
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
                if w > 0 {
                    containerSize = CGSize(width: w, height: h)
                    assignPositionsFromWords(width: w, height: h)
                }
            }
            .onChange(of: geo.size) { _, newSize in
                let newW = newSize.width
                let newH = newW * 1.2
                if newW > 0 && tagPositions.isEmpty {
                    containerSize = CGSize(width: newW, height: newH)
                    assignPositionsFromWords(width: newW, height: newH)
                }
            }
        }
        .aspectRatio(1 / 1.2, contentMode: .fit)
    }

    private func assignPositionsFromWords(width w: CGFloat, height h: CGFloat) {
        let count = record.words.count
        guard count > 0, w > 0 else { return }
        let margin: CGFloat = 50

        for (i, word) in record.words.enumerated() {
            // Use saved x/y from the Word (API-returned positions)
            if let xVal = word.x, let yVal = word.y {
                tagPositions[word.id] = CGPoint(
                    x: margin + CGFloat(xVal) * (w - margin * 2),
                    y: margin + CGFloat(yVal) * (h - margin * 2)
                )
            } else {
                // Fallback: circular layout
                let angle = (2 * .pi / Double(max(count, 1))) * Double(i) - .pi / 2
                tagPositions[word.id] = CGPoint(
                    x: w / 2 + CGFloat(cos(angle)) * w * 0.35,
                    y: h / 2 + CGFloat(sin(angle)) * h * 0.35
                )
            }
        }
    }
}
