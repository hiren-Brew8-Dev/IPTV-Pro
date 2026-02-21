import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0

    let pages = [
        OnboardingPage(
            title: "What is IPTV?",
            description:
                "IPTV (Internet Protocol Television) is a method of transmitting television signs, all you need is an internet connection to access your favorite channels and content.",
            icon: "tv"),
        OnboardingPage(
            title: "How can I watch TV?",
            description:
                "You have to add the M3U link or file with your channels in our Application.",
            icon: "doc.text"),
        OnboardingPage(
            title: "Chromecast to your TV!",
            description:
                "Cast the content from your device to your TV with chromecast support. We support Smart TVs, Android TV, Google TV, Fire TV, ChromeCast 1, 2 and 3.",
            icon: "airplayvideo"),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 40) {
                            Spacer()

                            Text(pages[index].title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            // Placeholder Icon
                            Image(systemName: pages[index].icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.red)
                                .padding()
                                .background(
                                    Circle().fill(Color.gray.opacity(0.2)).frame(
                                        width: 250, height: 250))

                            Text(pages[index].description)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String  // System name for now
}
