import Foundation
import SwiftUI

struct InstanceGroup: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var colorName: String
    var order: Int
    
    init(id: UUID = UUID(), name: String, icon: String = "server.rack", colorName: String = "blue", order: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.order = order
    }
    
    var color: Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
    
    static let availableColors = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "gray"]
    
    static let availableIcons = [
        "server.rack",
        "externaldrive.connected.to.line.below",
        "cloud",
        "house",
        "building.2",
        "network",
        "desktopcomputer",
        "laptopcomputer",
        "internaldrive",
        "opticaldiscdrive"
    ]
}
