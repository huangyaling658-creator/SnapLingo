import SwiftUI

struct SkeletonView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            shimmerBar(width: 0.5)
            shimmerBar(width: 0.3)
            shimmerBar(width: 0.32, height: 32)
        }
        .padding(22)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }

    private func shimmerBar(width fraction: CGFloat, height: CGFloat = 12) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.border.opacity(0.3), Color.border, Color.border.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * fraction, height: height)
                .offset(x: shimmerOffset)
                .mask(
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: geo.size.width * fraction, height: height)
                )
        }
        .frame(height: height)
    }
}
