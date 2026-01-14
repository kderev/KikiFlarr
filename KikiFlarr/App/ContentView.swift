import SwiftUI

struct ContentView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var watchedViewModel = WatchedViewModel()
    @State private var selectedTab: Tab = .discover
    
    enum Tab {
        case discover
        case library
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
                    
                    LibraryView()
                        .tabItem {
                            Label("Bibliothèque", systemImage: "books.vertical")
                        }
                        .tag(Tab.library)
                    
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
    }
}

#Preview {
    ContentView()
        .environmentObject(InstanceManager())
}
