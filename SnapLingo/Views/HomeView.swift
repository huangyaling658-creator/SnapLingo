import SwiftUI
import PhotosUI

struct HomeView: View {
    @Bindable var viewModel: SnapLingoViewModel
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                scrollContent
            }

            // Language picker overlay — positioned absolutely, no layout shift
            if viewModel.showLanguagePicker {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            viewModel.showLanguagePicker = false
                        }
                    }
                    .zIndex(50)

                VStack {
                    HStack {
                        Spacer()
                        LanguagePicker(selectedLanguage: viewModel.selectedLanguage) { lang in
                            viewModel.selectLanguage(lang)
                        }
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .padding(.top, 56) // Below header
                .zIndex(100)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: viewModel.showLanguagePicker)
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera) { image in
                viewModel.setImageAndAnalyze(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.setImageAndAnalyze(image)
                }
                selectedPhotoItem = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("拍照学外语")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Language button
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    viewModel.showLanguagePicker.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Text(viewModel.selectedLanguage.flag)
                        .font(.system(size: 15))
                    Text(viewModel.selectedLanguage.label)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.bg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.surface)
        .zIndex(20)
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title section
                VStack(spacing: 6) {
                    Text("看到什么，就学什么")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("拍照或上传图片，AI 自动识别 \(viewModel.selectedLanguage.flag) \(viewModel.selectedLanguage.label)单词")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subtle)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Image preview area
                imagePreview

                // Action buttons
                actionButtons

                // Loading state
                if viewModel.isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(viewModel.analysisStatus)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.subtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        Group {
            if let image = viewModel.capturedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        viewModel.clearImage()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(10)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.subtle)
                    Text("点击下方按钮拍照或选择图片")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subtle)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.border, style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15))
                    Text("拍照")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 15))
                    Text("相册")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            }
        }
    }
}
