import SwiftUI

struct InstanceRow: View {
    let instance: ServiceInstance
    @State private var connectionStatus: ConnectionTestResult?
    @State private var isTesting = false
    @State private var freeSpace: Int64?

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

                    if let space = freeSpace {
                        HStack(spacing: 2) {
                            Image(systemName: "internaldrive")
                                .font(.caption2)
                            Text(Formatters.formatBytes(space))
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(storageColor(for: space).opacity(0.1))
                        .foregroundColor(storageColor(for: space))
                        .clipShape(Capsule())
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
        .task {
            if freeSpace == nil && instance.serviceType != .overseerr {
                freeSpace = await instanceManager.getStorageInfo(for: instance)
            }
        }
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

    private func storageColor(for bytes: Int64) -> Color {
        let gb = Double(bytes) / 1_000_000_000
        if gb < 50 {
            return .red
        } else if gb < 200 {
            return .orange
        } else {
            return .green
        }
    }

    private func testConnection() async {
        isTesting = true
        async let connectionResult = instanceManager.testConnection(for: instance)
        async let storageResult = instanceManager.getStorageInfo(for: instance)

        connectionStatus = await connectionResult
        freeSpace = await storageResult
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
