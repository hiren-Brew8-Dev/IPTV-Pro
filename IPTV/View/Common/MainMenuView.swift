import SwiftUI

struct MainMenuView: View {
    @State private var selectedOption: MenuOption = .playlists
    @State private var isSidebarVisible = false

    var body: some View {
        ZStack {
            // Main Content
            NavigationView {
                VStack {
                    switch selectedOption {
                    case .playlists:
                        PlaylistListView()
                    case .favorites:
                        FavoritesView()
                    case .downloads:
                        DownloadsView()
                    case .settings:
                        SettingsView()
                    default:
                        Text("\(selectedOption.rawValue) Coming Soon")
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .disabled(isSidebarVisible)

            // Sidebar Overlay
            if isSidebarVisible {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isSidebarVisible.toggle()
                        }
                    }

                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("MegaIPTV Menu")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 50)
                            .padding(.leading)

                        ForEach(MenuOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                withAnimation {
                                    isSidebarVisible = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: option.icon)
                                        .frame(width: 30)
                                    Text(option.rawValue)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .foregroundColor(selectedOption == option ? .blue : .primary)
                                .background(
                                    selectedOption == option ? Color.blue.opacity(0.1) : Color.clear
                                )
                            }
                        }

                        Spacer()

                        Text("Copyright © 2026")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    .frame(width: 250)
                    .background(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.vertical)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
    }
}
