import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "fork.knife.circle.fill",
            title: "Welcome to Food Quiz",
            subtitle: "Discover fun facts about food and test your nutrition knowledge with real products.",
            gradient: [Color(red: 1.0, green: 0.42, blue: 0.21), Color(red: 1.0, green: 0.6, blue: 0.2)]
        ),
        OnboardingPage(
            icon: "gamecontroller.fill",
            title: "Play 5 Game Modes",
            subtitle: "Compare nutrients, guess countries and brands, estimate calories, and sort products.",
            gradient: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.35, green: 0.4, blue: 0.95)]
        ),
        OnboardingPage(
            icon: "barcode.viewfinder",
            title: "Scan Any Product",
            subtitle: "Point your camera at a barcode to instantly look up nutrition info from Open Food Facts.",
            gradient: [Color(red: 0.95, green: 0.45, blue: 0.2), Color(red: 0.9, green: 0.25, blue: 0.35)]
        ),
        OnboardingPage(
            icon: "magnifyingglass.circle.fill",
            title: "Search & Explore",
            subtitle: "Find products by name, brand, or barcode. Browse ingredients, allergens, and Nutri-Score.",
            gradient: [Color(red: 0.18, green: 0.75, blue: 0.55), Color(red: 0.1, green: 0.55, blue: 0.75)]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        onboardingPage(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                    .padding(.bottom, 16)

                actionButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 220, height: 220)

                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: currentPage)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index == currentPage ? 1 : 0.35))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation { currentPage += 1 }
                HapticService.selection()
            } else {
                completeOnboarding()
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(pages[currentPage].gradient[0])
        }
    }

    private func completeOnboarding() {
        HapticService.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView()
}
