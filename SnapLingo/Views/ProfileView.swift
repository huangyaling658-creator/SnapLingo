import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 52, weight: .thin))
                            .foregroundStyle(Color.subtle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("拍照学外语")
                                .font(.system(size: 18, weight: .semibold))
                            Text("AI 识别图片，轻松学单词")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.subtle)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("设置") {
                    Label("语言偏好", systemImage: "globe")
                    Label("识别模型", systemImage: "cpu")
                }

                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color.subtle)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}
