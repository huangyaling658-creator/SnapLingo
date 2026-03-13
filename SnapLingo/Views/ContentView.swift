import SwiftUI

struct ContentView: View {
    @State private var viewModel = SnapLingoViewModel()
    @State private var selectedTab = 0
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main app
            mainTabView
                .opacity(showSplash ? 0 : 1)

            // Splash overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            // Show splash for 1.2s then smooth fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("首页", systemImage: "camera.fill", value: 0) {
                homeNavigation
            }

            Tab("单词", systemImage: "character.book.closed.fill", value: 1) {
                WordbookView(viewModel: viewModel)
            }

            Tab("历史", systemImage: "clock.fill", value: 2) {
                HistoryView(viewModel: viewModel)
            }

            Tab("我的", systemImage: "person.fill", value: 3) {
                ProfileView()
            }
        }
        .tint(Color.textPrimary)
        .alert("提示", isPresented: $viewModel.showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.currentPage) {
            if viewModel.currentPage == .wordbook {
                selectedTab = 1
                viewModel.currentPage = .home
            }
        }
    }

    @ViewBuilder
    private var homeNavigation: some View {
        switch viewModel.currentPage {
        case .home:
            HomeView(viewModel: viewModel)
        case .results:
            ResultsView(viewModel: viewModel)
        case .wordbook:
            EmptyView()
        }
    }
}
