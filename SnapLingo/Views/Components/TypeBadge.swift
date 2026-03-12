import SwiftUI

struct TypeBadge: View {
    let type: Word.WordType

    private var label: String {
        switch type {
        case .noun: return "名词"
        case .adjective: return "形容词"
        case .verb: return "动词"
        case .adverb: return "副词"
        case .preposition: return "介词"
        case .pronoun: return "代词"
        case .conjunction: return "连词"
        case .interjection: return "感叹词"
        case .other: return "词汇"
        }
    }

    private var bgColor: Color {
        switch type {
        case .noun: return .nounBg
        case .adjective: return .adjBg
        case .verb: return .verbBg
        default: return Color(hex: "F3E8FD")
        }
    }

    private var textColor: Color {
        switch type {
        case .noun: return .nounText
        case .adjective: return .adjText
        case .verb: return .verbText
        default: return Color(hex: "6A1B9A")
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
