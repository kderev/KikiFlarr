import SwiftUI

struct TorrentCard: View, Equatable {
    let torrent: QBittorrentTorrent
    let instanceName: String
    let onPause: () -> Void
    let onResume: () -> Void
    let onDelete: () -> Void
    
    @State private var isActionInProgress = false
    
    static func == (lhs: TorrentCard, rhs: TorrentCard) -> Bool {
        lhs.torrent.hash == rhs.torrent.hash &&
        lhs.torrent.progress == rhs.torrent.progress &&
        lhs.torrent.state == rhs.torrent.state &&
        lhs.torrent.dlspeed == rhs.torrent.dlspeed &&
        lhs.torrent.upspeed == rhs.torrent.upspeed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            infoRow
            progressSection
            speedsRow
            actionButtons
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: torrent.stateIcon)
                .foregroundColor(stateColor)
            
            Text(torrent.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Spacer()
            
            if isActionInProgress {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var infoRow: some View {
        HStack {
            Text(instanceName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
            
            Text(torrent.stateDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(Formatters.formatBytes(torrent.size))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 4) {
            ProgressView(value: torrent.progress)
                .tint(progressColor)
            
            HStack {
                Text(Formatters.formatProgress(torrent.progress))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var speedsRow: some View {
        HStack {
            if torrent.isDownloading {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                    Text(Formatters.formatSpeed(torrent.dlspeed))
                        .font(.caption)
                }
                .foregroundColor(.blue)
                
                Text("ETA: \(torrent.formattedETA)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if torrent.isUploading || torrent.upspeed > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text(Formatters.formatSpeed(torrent.upspeed))
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption2)
                Text(Formatters.formatRatio(torrent.ratio))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if torrent.isPaused {
                Button {
                    performAction(onResume)
                } label: {
                    actionButtonContent(icon: "play.fill", text: "Reprendre", color: .green)
                }
                .disabled(isActionInProgress)
            } else {
                Button {
                    performAction(onPause)
                } label: {
                    actionButtonContent(icon: "pause.fill", text: "Pause", color: .orange)
                }
                .disabled(isActionInProgress)
            }
            
            Button {
                onDelete()
            } label: {
                actionButtonContent(icon: "trash.fill", text: "Supprimer", color: .red)
            }
            .disabled(isActionInProgress)
        }
    }
    
    private func actionButtonContent(icon: String, text: String, color: Color) -> some View {
        HStack {
            if isActionInProgress && (text == "Reprendre" || text == "Pause") {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)
            } else {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.caption)
        .fontWeight(.medium)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActionInProgress ? color.opacity(0.6) : color)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func performAction(_ action: @escaping () -> Void) {
        isActionInProgress = true
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isActionInProgress = false
        }
    }
    
    private var stateColor: Color {
        switch torrent.stateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    private var progressColor: Color {
        if torrent.progress >= 1.0 {
            return .green
        } else if torrent.isDownloading {
            return .blue
        } else {
            return .gray
        }
    }
}

#Preview {
    VStack {
        TorrentCard(
            torrent: QBittorrentTorrent(
                hash: "abc123",
                name: "Example.Torrent.2024.1080p.BluRay",
                size: 4_500_000_000,
                progress: 0.65,
                dlspeed: 15_000_000,
                upspeed: 2_000_000,
                priority: 1,
                numSeeds: 50,
                numComplete: 100,
                numLeechs: 10,
                numIncomplete: 20,
                ratio: 1.25,
                eta: 3600,
                state: "downloading",
                seqDl: false,
                fLPiecePrio: false,
                category: nil,
                tags: nil,
                superSeeding: false,
                forceStart: false,
                savePath: nil,
                addedOn: nil,
                completionOn: nil,
                tracker: nil,
                dlLimit: nil,
                upLimit: nil,
                downloaded: nil,
                uploaded: nil,
                downloadedSession: nil,
                uploadedSession: nil,
                amountLeft: nil,
                completed: nil,
                maxRatio: nil,
                maxSeedingTime: nil,
                autoTmm: nil,
                timeActive: nil,
                contentPath: nil
            ),
            instanceName: "Seedbox",
            onPause: {},
            onResume: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
