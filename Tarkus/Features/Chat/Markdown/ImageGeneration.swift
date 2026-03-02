import Foundation
import CoreGraphics

// MARK: - ImageGeneration

/// Represents an in-progress or completed image generation.
/// Mirrors OpenAI's `OAIMarkdown.ImageGeneration`.
struct ImageGeneration: Hashable {

    /// Unique identifier for this image generation.
    var imageGenerationID: String

    /// The conversation this generation belongs to, if applicable.
    var conversationID: String?

    /// Progress of the generation (0.0 to 1.0).
    var generationProgress: CGFloat

    /// URL of the generated image.
    var url: URL

    /// Whether the generated image has a transparent background.
    var isTransparent: Bool

    /// Direct download URL, if available.
    var directDownloadUrl: URL?

    /// Whether generation is complete (progress >= 1.0).
    var isComplete: Bool {
        generationProgress >= 1.0
    }

    /// Whether the image is entirely blurred (early generation stage).
    var isEntirelyBlurred: Bool {
        generationProgress < 0.3
    }

    /// Whether the image is almost complete (visible but still refining).
    var isAlmostComplete: Bool {
        generationProgress >= 0.8 && generationProgress < 1.0
    }

    init(
        imageGenerationID: String,
        conversationID: String? = nil,
        generationProgress: CGFloat = 0.0,
        url: URL,
        isTransparent: Bool = false,
        directDownloadUrl: URL? = nil
    ) {
        self.imageGenerationID = imageGenerationID
        self.conversationID = conversationID
        self.generationProgress = generationProgress
        self.url = url
        self.isTransparent = isTransparent
        self.directDownloadUrl = directDownloadUrl
    }
}

// MARK: - ImageGenerationRenderStyle

/// How an image generation should be visually rendered.
/// Mirrors OpenAI's `OAIMarkdown.ImageGenerationRenderStyle`.
enum ImageGenerationRenderStyle: Hashable, CaseIterable {
    /// Standard rendering with blur-to-clear transition.
    case standard
    /// Compact rendering for inline display.
    case compact

    static var allCases: [ImageGenerationRenderStyle] {
        [.standard, .compact]
    }
}
