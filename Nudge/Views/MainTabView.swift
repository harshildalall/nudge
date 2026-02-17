import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EventsListView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(0)

            NudgesView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Nudges")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(Theme.accent)
    }
}
