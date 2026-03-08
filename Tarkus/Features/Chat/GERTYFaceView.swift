import SwiftUI

// MARK: - GERTYMood

/// The 8 GERTY mood states from Moon (2009), sent by the server's respond tool.
enum GERTYMood: String, CaseIterable {
    case happy
    case excited
    case sad
    case empathetic
    case neutral
    case concerned
    case confused
    case anxious

    /// The filename of the GERTY face image for this mood (without extension).
    var imageName: String {
        "gerty_\(rawValue)"
    }
}

// MARK: - GERTYFaceView

/// Displays the GERTY emoticon face image matching the current mood.
/// Images are the classic gold smiley faces from Moon (2009) in 4:3 aspect ratio.
struct GERTYFaceView: View {

    let mood: GERTYMood
    var width: CGFloat = 48
    var height: CGFloat = 36

    var body: some View {
        gertyImage
            .resizable()
            .interpolation(.high)
            .aspectRatio(4/3, contentMode: .fit)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var gertyImage: Image {
        let name = mood.imageName
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else {
            return Image(systemName: "face.smiling")
        }
        #if os(macOS)
        guard let nsImage = NSImage(contentsOf: url) else {
            return Image(systemName: "face.smiling")
        }
        return Image(nsImage: nsImage)
        #else
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return Image(systemName: "face.smiling")
        }
        return Image(uiImage: uiImage)
        #endif
    }
}

// MARK: - Preview

#Preview("GERTY Moods") {
    HStack(spacing: 16) {
        ForEach(GERTYMood.allCases, id: \.rawValue) { mood in
            VStack(spacing: 4) {
                GERTYFaceView(mood: mood)
                Text(mood.rawValue)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
