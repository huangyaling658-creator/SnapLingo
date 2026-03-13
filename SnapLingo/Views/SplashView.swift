import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var sloganOpacity: Double = 0

    var body: some View {
        ZStack {
            // Bright gradient background
            LinearGradient(
                colors: [Color(hex: "FFF8E1"), Color(hex: "FFFDE7")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Simple bright logo
                ZStack {
                    // Yellow circle background
                    Circle()
                        .fill(Color(hex: "FFD60A"))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "FFD60A").opacity(0.4), radius: 20, y: 4)

                    // Camera icon + text
                    VStack(spacing: 2) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Aa")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                Text("拍照学外语")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "333333"))
                    .opacity(logoOpacity)

                // Slogan
                Text("看到什么，学什么")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "999999"))
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
