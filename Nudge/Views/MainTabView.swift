import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    private let tabs: [(label: String, icon: String)] = [
        ("Events", "calendar"),
        ("Nudges", "alarm"),
        ("Settings", "gearshape.fill")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content — no default tab chrome
            Group {
                switch selectedTab {
                case 0: EventsListView()
                case 1: NudgesView()
                case 2: SettingsView()
                default: EventsListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom floating pill tab bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                let tab = tabs[idx]
                let isSelected = selectedTab == idx
                Button(action: { selectedTab = idx }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color.nudgeButton : Color(hex: "ABABAB"))
                        Text(tab.label)
                            .font(.albertSans(11, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color.nudgeButton : Color(hex: "ABABAB"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nudgeButton.opacity(0.1))
                                    .padding(.horizontal, 6)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
