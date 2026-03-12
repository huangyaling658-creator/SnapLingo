import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: SnapLingoViewModel

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
                        viewModel.loadRecord(record)
                    } label: {
                        historyCard(record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func historyCard(_ record: LearningRecord) -> some View {
        let lang = Language.all.first { $0.code == record.lang }
        return VStack(spacing: 0) {
            // Image thumbnail
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

            // Info bar
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
