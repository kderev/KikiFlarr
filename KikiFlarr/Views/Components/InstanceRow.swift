import SwiftUI

struct InstanceRow: View {
    let instance: ServiceInstance
    @State private var connectionStatus: ConnectionTestResult?
    @State private var isTesting = false
    
    var instanceManager: InstanceManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: instance.serviceType.icon)
                .font(.title2)
                .foregroundColor(serviceColor)
                .frame(width: 40, height: 40)
                .background(serviceColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(instance.name)
                    .font(.headline)
                
                Text(instance.displayURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text(instance.serviceType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(serviceColor.opacity(0.1))
                        .foregroundColor(serviceColor)
                        .clipShape(Capsule())
                    
                    if let status = connectionStatus {
                        Image(systemName: status.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(status.success ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            if isTesting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button {
                    Task {
                        await testConnection()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var serviceColor: Color {
        switch instance.serviceType.color {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        default: return .gray
        }
    }
    
    private func testConnection() async {
        isTesting = true
        connectionStatus = await instanceManager.testConnection(for: instance)
        isTesting = false
    }
}

#Preview {
    List {
        InstanceRow(
            instance: ServiceInstance(
                name: "Radarr Maison",
                baseURL: "http://192.168.1.100:7878",
                serviceType: .radarr
            ),
            instanceManager: InstanceManager()
        )
        
        InstanceRow(
            instance: ServiceInstance(
                name: "Sonarr Seedbox",
                baseURL: "https://sonarr.example.com",
                serviceType: .sonarr
            ),
            instanceManager: InstanceManager()
        )
    }
}
