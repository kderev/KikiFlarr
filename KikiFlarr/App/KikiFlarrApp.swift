import SwiftUI

@main
struct KikiFlarrApp: App {
    @StateObject private var instanceManager = InstanceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(instanceManager)
        }
    }
}
