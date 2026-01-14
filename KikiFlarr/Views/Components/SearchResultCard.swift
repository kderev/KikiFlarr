import SwiftUI

struct SearchResultCard: View {
    let result: OverseerrSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            PosterImageView(url: result.fullPosterURL, width: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.displayTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    MediaTypeBadge(mediaType: result.resolvedMediaType)
                }
                
                if !result.displayYear.isEmpty {
                    Text(result.displayYear)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let voteAverage = result.voteAverage, voteAverage > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(Formatters.formatVoteAverage(voteAverage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let overview = result.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let mediaInfo = result.mediaInfo {
                    StatusBadge(mediaInfo: mediaInfo)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MediaTypeBadge: View {
    let mediaType: MediaType
    
    var body: some View {
        Text(mediaType == .movie ? "Film" : "Série")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(mediaType == .movie ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
            .foregroundColor(mediaType == .movie ? .orange : .blue)
            .clipShape(Capsule())
    }
}

struct StatusBadge: View {
    let mediaInfo: OverseerrMediaInfo
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption2)
            Text(mediaInfo.statusDescription)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusIcon: String {
        if mediaInfo.isAvailable {
            return "checkmark.circle.fill"
        } else if mediaInfo.isPartiallyAvailable {
            return "circle.lefthalf.filled"
        } else if mediaInfo.isRequested {
            return "clock.fill"
        }
        return "circle"
    }
    
    private var statusColor: Color {
        if mediaInfo.isAvailable {
            return .green
        } else if mediaInfo.isPartiallyAvailable {
            return .orange
        } else if mediaInfo.isRequested {
            return .blue
        }
        return .gray
    }
}

#Preview {
    List {
        SearchResultCard(result: OverseerrSearchResult(
            id: 1,
            mediaType: .movie,
            popularity: 100,
            posterPath: nil,
            backdropPath: nil,
            voteCount: 1000,
            voteAverage: 8.5,
            genreIds: nil,
            overview: "Un film super avec une histoire incroyable...",
            originalLanguage: "en",
            title: "Titre du Film",
            originalTitle: nil,
            releaseDate: "2024-01-15",
            adult: false,
            video: false,
            name: nil,
            originalName: nil,
            firstAirDate: nil,
            originCountry: nil,
            mediaInfo: nil
        ))
    }
}
