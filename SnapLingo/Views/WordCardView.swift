import SwiftUI

struct WordCardView: View {
    let word: Word
    let lang: Language
    let isSaved: Bool
    let onSave: () -> Void
    let onSpeak: (String) -> Void
    let index: Int

    @State private var isFlipped = false
    @State private var isSpeaking = false
    @State private var saveScale: CGFloat = 1

    var body: some View {
        ZStack {
            if !isFlipped { frontFace } else { backFace }
        }
        .animation(.easeInOut(duration: 0.25), value: isFlipped)
        .onTapGesture { isFlipped.toggle() }
        .modifier(AppearAnimationModifier(delay: Double(index) * 0.06))
    }

    // MARK: - Front Face

    private var frontFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            TypeBadge(type: word.type)
                .padding(.bottom, 8)

            Text(word.word)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, 4)

            Text(word.phonetic)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.subtle)
                .padding(.bottom, 8)

            Text(word.translation)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accentSoft)
                .padding(.bottom, 14)

            HStack {
                speakButton(text: word.word)
                Spacer()
                Text("点击看例句 →")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.subtle)
            }
        }
        .padding(18)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
        .overlay(alignment: .topTrailing) { saveButton }
    }

    // MARK: - Back Face

    private var backFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EXAMPLE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 10)

            Text(word.example ?? "")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(6)
                .padding(.bottom, 14)

            HStack {
                speakButton(text: word.example ?? word.word)
                Spacer()
                Text("← 点击返回")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(18)
        .background(Color.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) { saveButton }
    }

    // MARK: - Subviews

    private var saveButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) { saveScale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { saveScale = 1 }
            }
            onSave()
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16))
                .foregroundStyle(isFlipped ? .white : (isSaved ? Color.highlight : Color.subtle))
                .scaleEffect(saveScale)
        }
        .padding(.top, 16)
        .padding(.trailing, 16)
    }

    private func speakButton(text: String) -> some View {
        Button {
            isSpeaking = true
            onSpeak(text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { isSpeaking = false }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "play.fill")
                    .font(.system(size: 11))
                Text(isSpeaking ? "朗读中…" : (isFlipped ? "朗读例句" : "朗读"))
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isFlipped ? .white : Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isFlipped ? .white.opacity(0.15) : Color.bg)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Appear Animation

struct AppearAnimationModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                    appeared = true
                }
            }
    }
}
