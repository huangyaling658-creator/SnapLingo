import SwiftUI

struct LanguagePicker: View {
    let selectedLanguage: Language
    let onSelect: (Language) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Language.all) { lang in
                Button {
                    onSelect(lang)
                } label: {
                    HStack(spacing: 10) {
                        Text(lang.flag)
                            .font(.system(size: 18))
                        Text(lang.label)
                            .font(.system(size: 14, weight: lang.code == selectedLanguage.code ? .bold : .medium))
                            .foregroundStyle(lang.code == selectedLanguage.code ? Color.highlight : Color.textPrimary)
                        Spacer()
                        if lang.code == selectedLanguage.code {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.highlight)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(lang.code == selectedLanguage.code ? Color.highlightSoft : .clear)
                }
                if lang.code != Language.all.last?.code {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
        .frame(width: 160)
    }
}
