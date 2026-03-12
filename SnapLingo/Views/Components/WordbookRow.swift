import SwiftUI

struct WordbookRow: View {
    let word: SavedWord
    let onSpeak: () -> Void
    let onDelete: () -> Void

    private var language: Language? {
        Language.all.first { $0.code == word.lang }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(language?.flag ?? "🌐")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    Text(word.phonetic)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.subtle)
                }
                Text(word.translation)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentSoft)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.highlight)
                        .padding(8)
                        .background(Color.highlightSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(8)
                        .background(Color(hex: "FFF0F0"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
    }
}
