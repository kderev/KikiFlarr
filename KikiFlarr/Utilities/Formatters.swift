import Foundation

enum Formatters {
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    static func formatSpeed(_ bytesPerSecond: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: bytesPerSecond))/s"
    }
    
    /// Formate une progression (0.0 à 1.0) en pourcentage
    static func formatProgress(_ progress: Double) -> String {
        // La progression est entre 0 et 1
        let percentage = progress * 100
        return String(format: "%.1f%%", percentage)
    }
    
    static func formatRatio(_ ratio: Double) -> String {
        String(format: "%.2f", ratio)
    }
    
    static func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)min"
        }
        return "\(mins)min"
    }
    
    static func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: date)
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: date)
        }
        
        if dateString.count >= 10 {
            return String(dateString.prefix(10))
        }
        
        return dateString
    }
    
    static func formatYear(_ dateString: String?) -> String {
        guard let dateString = dateString, dateString.count >= 4 else { return "" }
        return String(dateString.prefix(4))
    }
    
    static func formatVoteAverage(_ vote: Double?) -> String {
        guard let vote = vote else { return "N/A" }
        return String(format: "%.1f", vote)
    }
}
