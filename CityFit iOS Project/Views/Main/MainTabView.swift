import SwiftUI

struct MainTabView: View {
    @State private var showChat = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.cityCard)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "map.fill") }
                MissionsView()
                    .tabItem { Label("Missions", systemImage: "target") }
                LeaderboardView()
                    .tabItem { Label("Ranks", systemImage: "trophy.fill") }
                CommunityView()
                    .tabItem { Label("Community", systemImage: "person.3.fill") }
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
            }
            .tint(.cityAccent)

            // Floating AI coach button — top-right, clear of the Start button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showChat = true
                    } label: {
                        Image(systemName: "bubble.left.fill")
                            .font(.game(size: 18))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.cityAccent)
                            .clipShape(Circle())
                            .shadow(color: .cityAccent.opacity(0.5), radius: 8)
                    }
                    .accessibilityLabel("AI Coach chat")
                    .padding(.trailing, 20)
                    .padding(.top, 56)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showChat) {
            AIChatView()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ProfileViewModel())
            .environmentObject(MissionViewModel())
            .environmentObject(AIViewModel())
            .environmentObject(LocationService())
    }
}
