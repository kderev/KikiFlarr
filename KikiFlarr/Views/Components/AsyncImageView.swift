import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    let placeholder: String
    
    var body: some View {
        CachedAsyncImage(url: url) {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: placeholder)
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PosterImageView: View {
    let url: URL?
    let width: CGFloat
    
    var body: some View {
        AsyncImageView(url: url, placeholder: "photo")
            .frame(width: width, height: width * 1.5)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct BackdropImageView: View {
    let url: URL?
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            CachedAsyncImage(url: url) {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: geometry.size.width, height: height)
            .clipped()
        }
        .frame(height: height)
    }
}

#Preview {
    VStack {
        PosterImageView(url: nil, width: 100)
        BackdropImageView(url: nil, height: 200)
    }
}
