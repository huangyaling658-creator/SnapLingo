import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var sloganOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "1A1A1A").ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo icon
                ZStack {
                    // Camera body
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.8), lineWidth: 4)
                        .frame(width: 120, height: 88)

                    // Lens
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 4)
                        .frame(width: 56, height: 56)

                    // Center dot
                    Circle()
                        .fill(Color(hex: "FFD60A"))
                        .frame(width: 18, height: 18)

                    // Flash
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 24, height: 12)
                        .offset(x: 36, y: -38)

                    // "Aa" badge
                    Text("Aa")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "FFD60A"))
                        .offset(x: 0, y: 50)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                Text("拍照学外语")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(logoOpacity)

                // Slogan
                Text("看到什么，学什么")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(sloganOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                sloganOpacity = 1.0
            }
        }
    }
}
