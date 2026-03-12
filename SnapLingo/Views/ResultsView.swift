import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: SnapLingoViewModel
    @State private var tagPositions: [String: CGPoint] = [:]  // absolute positions
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var containerSize: CGSize = .zero

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 0) {
                        imageWithOverlay
                            .padding(.horizontal, 12)
                            .padding(.top, 8)

                        if !viewModel.words.isEmpty {
                            Text("\(viewModel.words.count) 个单词")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.subtle)
                                .padding(.top, 10)
                        }

                        if viewModel.isAnalyzing {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text(viewModel.analysisStatus)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.subtle)
                            }
                            .padding(.top, 12)
                        }

                        speakAllButton
                            .padding(.top, 14)

                        Rectangle().fill(Color.border).frame(height: 1)
                            .padding(.horizontal, 16).padding(.top, 16)

                        wordList
                            .padding(.top, 8).padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .onChange(of: viewModel.words.count) {
            assignCircularPositions()
        }
    }

    // MARK: - Circular Layout

    private func assignCircularPositions() {
        let count = viewModel.words.count
        guard count > 0, containerSize.width > 0 else { return }
        let w = containerSize.width
        let h = containerSize.height
        let centerX = w / 2
        let centerY = h / 2
        let radiusX = w * 0.35
        let radiusY = h * 0.35

        for (i, word) in viewModel.words.enumerated() {
            if tagPositions[word.id] != nil { continue }  // Don't reset dragged tags
            let angle = (2 * .pi / Double(max(count, 1))) * Double(i) - .pi / 2
            let x = centerX + CGFloat(cos(angle)) * radiusX
            let y = centerY + CGFloat(sin(angle)) * radiusY
            tagPositions[word.id] = CGPoint(x: x, y: y)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { viewModel.goHome() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 16))
                }
                .foregroundStyle(Color.highlight)
            }

            Spacer()

            Text("拍照学外语")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button { generateShareImage() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.highlight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surface)
    }

    // MARK: - Image with Word Overlays

    private var imageWithOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w * 1.2

            ZStack {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                ForEach(Array(viewModel.words.enumerated()), id: \.element.id) { index, word in
                    WordTagView(
                        word: word,
                        isSelected: index == viewModel.selectedWordIndex,
                        isSaved: viewModel.isSaved(word),
                        position: tagPositions[word.id] ?? CGPoint(x: w / 2, y: h / 2),
                        onTap: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                viewModel.selectedWordIndex = index
                            }
                            viewModel.speak(word.word)
                        },
                        onSave: { viewModel.toggleSave(word) },
                        onDragEnd: { newPos in
                            tagPositions[word.id] = newPos
                        }
                    )
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .frame(width: w, height: h)
            .onAppear {
                containerSize = CGSize(width: w, height: h)
                assignCircularPositions()
            }
        }
        .aspectRatio(1 / 1.2, contentMode: .fit)
    }

    // MARK: - Speak All

    private var speakAllButton: some View {
        Button {
            let allWords = viewModel.words.map(\.word).joined(separator: ", ")
            viewModel.speak(allWords)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 14))
                Text("朗读单词").font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(Color.highlight)
            .clipShape(Capsule())
        }
        .opacity(viewModel.words.isEmpty ? 0.5 : 1)
        .disabled(viewModel.words.isEmpty)
    }

    // MARK: - Word List

    private var wordList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.words.enumerated()), id: \.element.id) { index, word in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        viewModel.selectedWordIndex = index
                    }
                    viewModel.speak(word.word)
                } label: {
                    HStack(spacing: 12) {
                        // Highlight bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == viewModel.selectedWordIndex ? Color(hex: "FFD60A") : Color.clear)
                            .frame(width: 4, height: 48)

                        // Word + phonetic + translation
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

                        // Speak
                        Button {
                            viewModel.speak(word.word)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.highlight)
                                .padding(8)
                        }

                        // Bookmark
                        Button {
                            viewModel.toggleSave(word)
                        } label: {
                            Image(systemName: viewModel.isSaved(word) ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 14))
                                .foregroundStyle(viewModel.isSaved(word) ? Color(hex: "FFD60A") : Color.subtle)
                                .padding(8)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                    .background(index == viewModel.selectedWordIndex ? Color(hex: "FFD60A").opacity(0.08) : Color.clear)
                }
                .buttonStyle(.plain)

                if index < viewModel.words.count - 1 {
                    Divider().padding(.leading, 20)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Share

    private func generateShareImage() {
        guard let capturedImage = viewModel.capturedImage else { return }
        let size = CGSize(width: 400, height: 480)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            capturedImage.draw(in: CGRect(origin: .zero, size: size))

            for (i, word) in viewModel.words.enumerated() {
                let count = viewModel.words.count
                let angle = (2 * .pi / Double(max(count, 1))) * Double(i) - .pi / 2
                let cx = size.width / 2 + CGFloat(cos(angle)) * size.width * 0.3
                let cy = size.height / 2 + CGFloat(sin(angle)) * size.height * 0.3
                let tagW: CGFloat = 90
                let tagH: CGFloat = 52
                let tagRect = CGRect(x: cx - tagW / 2, y: cy - tagH / 2, width: tagW, height: tagH)

                let path = UIBezierPath(roundedRect: tagRect, cornerRadius: 8)
                UIColor(red: 1, green: 0.84, blue: 0.04, alpha: 0.95).setFill()
                path.fill()

                let wordAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.black]
                let wordStr = word.word as NSString
                let ws = wordStr.size(withAttributes: wordAttr)
                wordStr.draw(at: CGPoint(x: tagRect.midX - ws.width / 2, y: tagRect.minY + 5), withAttributes: wordAttr)

                let phoneticAttr: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 9), .foregroundColor: UIColor.darkGray]
                let ps = (word.phonetic as NSString).size(withAttributes: phoneticAttr)
                (word.phonetic as NSString).draw(at: CGPoint(x: tagRect.midX - ps.width / 2, y: tagRect.minY + 21), withAttributes: phoneticAttr)

                let transAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
                let ts = (word.translation as NSString).size(withAttributes: transAttr)
                (word.translation as NSString).draw(at: CGPoint(x: tagRect.midX - ts.width / 2, y: tagRect.minY + 35), withAttributes: transAttr)
            }
        }
        shareImage = img
        showShareSheet = true
    }
}

// MARK: - Word Tag (on image)

struct WordTagView: View {
    let word: Word
    let isSelected: Bool
    let isSaved: Bool
    let position: CGPoint
    let onTap: () -> Void
    let onSave: () -> Void
    let onDragEnd: (CGPoint) -> Void

    @State private var currentPos: CGPoint = .zero
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 2) {
            Text(word.word)
                .font(.system(size: isSelected ? 14 : 12, weight: .bold))
            Text(word.phonetic)
                .font(.system(size: isSelected ? 10 : 9))
                .italic()
            HStack(spacing: 4) {
                Text(word.translation)
                    .font(.system(size: isSelected ? 11 : 9, weight: .medium))
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 8))
                    .foregroundStyle(isSaved ? Color(hex: "FF6B00") : .white.opacity(0.6))
                    .onTapGesture { onSave() }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "FFD60A") : Color(hex: "FFE066").opacity(0.92))
                .shadow(color: .black.opacity(isDragging ? 0.4 : 0.25), radius: isDragging ? 8 : 4, y: 2)
        )
        .foregroundStyle(Color(hex: "1A1A1A"))
        .scaleEffect(isDragging ? 1.15 : (isSelected ? 1.05 : 1.0))
        .zIndex(isDragging ? 100 : (isSelected ? 50 : 0))
        .position(currentPos)
        .onAppear { currentPos = position }
        .onChange(of: position) { _, newVal in
            if !isDragging { currentPos = newVal }
        }
        .onTapGesture { onTap() }
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    isDragging = true
                    currentPos = CGPoint(
                        x: position.x + value.translation.width,
                        y: position.y + value.translation.height
                    )
                }
                .onEnded { value in
                    isDragging = false
                    let finalPos = CGPoint(
                        x: position.x + value.translation.width,
                        y: position.y + value.translation.height
                    )
                    currentPos = finalPos
                    onDragEnd(finalPos)
                }
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
