import SwiftUI

struct ContentView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var watchedViewModel = WatchedViewModel()
    @State private var selectedTab: Tab = .discover

    enum Tab: String {
        case discover
        case requests
        case library
        case calendar
        case collection
        case downloads
        case settings
    }

    var body: some View {
        Group {
            if instanceManager.instances.isEmpty {
                OnboardingView()
            } else {
                TabView(selection: $selectedTab) {
                    DiscoverView()
                        .tabItem {
                            Label("Découvrir", systemImage: "sparkles")
                        }
                        .tag(Tab.discover)

                    RequestsView()
                        .tabItem {
                            Label("Requêtes", systemImage: "text.badge.plus")
                        }
                        .tag(Tab.requests)

                    LibraryView()
                        .tabItem {
                            Label("Bibliothèque", systemImage: "books.vertical")
                        }
                        .tag(Tab.library)

                    SonarrCalendarView()
                        .tabItem {
                            Label("Calendrier", systemImage: "calendar")
                        }
                        .tag(Tab.calendar)

                    CollectionView()
                        .tabItem {
                            Label("Collection", systemImage: "trophy.fill")
                        }
                        .tag(Tab.collection)

                    DownloadsView()
                        .tabItem {
                            Label("Transferts", systemImage: "arrow.down.circle")
                        }
                        .tag(Tab.downloads)

                    SettingsView()
                        .tabItem {
                            Label("Paramètres", systemImage: "gear")
                        }
                        .tag(Tab.settings)
                }
            }
        }
        .environmentObject(watchedViewModel)
        .onAppear {
            watchedViewModel.setInstanceManager(instanceManager)
            checkSiriDeepLink()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkSiriDeepLink()
        }
    }

    /// Vérifie si Siri a demandé l'ouverture d'un onglet spécifique
    private func checkSiriDeepLink() {
        if let tabName = UserDefaults.standard.string(forKey: "siri.openTab"),
           let tab = Tab(rawValue: tabName) {
            selectedTab = tab
            UserDefaults.standard.removeObject(forKey: "siri.openTab")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(InstanceManager())
}
