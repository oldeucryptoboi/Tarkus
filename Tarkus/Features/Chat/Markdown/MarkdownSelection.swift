import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownSelection

/// Represents a user selection within markdown content, either images or video.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownSelection`.
enum MarkdownSelection {

    /// The user selected one or more images.
    case images(Images)

    /// The user selected a video URL.
    case video(URL)

    // MARK: - Images

    /// A selection of images from markdown content.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownSelection.Images`.
    struct Images: Hashable, Identifiable {

        /// The image that was initially selected/tapped.
        var selectedImage: Image

        /// All images in the group (for gallery navigation).
        var images: [Image]

        /// Whether to display URL attribution.
        var showAttribution: Bool

        /// Whether the user can save the image.
        var allowSave: Bool

        /// Whether the user can share the image.
        var allowShare: Bool

        /// Identity is the struct itself.
        var id: Images { self }

        init(
            selectedImage: Image,
            images: [Image],
            showAttribution: Bool = false,
            allowSave: Bool = true,
            allowShare: Bool = true
        ) {
            self.selectedImage = selectedImage
            self.images = images
            self.showAttribution = showAttribution
            self.allowSave = allowSave
            self.allowShare = allowShare
        }

        // MARK: - Image

        /// A single image within a markdown selection.
        struct Image: Hashable {

            /// The underlying markdown result image data.
            var image: MarkdownResult.Item.Image

            /// The source view displaying this image, for transition animations.
            var sourceView: PlatformView?

            /// Optional metadata about the image (generation progress, etc.).
            var imageMetadata: MarkdownContent.ImageMetadata?

            /// Whether to show the image URL.
            var showsURL: Bool

            /// Whether the image is still being generated.
            var isImageStillGenerating: Bool {
                imageMetadata?.isImageStillGenerating ?? false
            }

            /// Whether the image has a transparent background.
            var isTransparent: Bool {
                imageMetadata?.imageGenerationIsTransparent ?? false
            }

            init(
                image: MarkdownResult.Item.Image,
                sourceView: PlatformView? = nil,
                imageMetadata: MarkdownContent.ImageMetadata? = nil,
                showsURL: Bool = false
            ) {
                self.image = image
                self.sourceView = sourceView
                self.imageMetadata = imageMetadata
                self.showsURL = showsURL
            }

            // MARK: Hashable

            static func == (lhs: Image, rhs: Image) -> Bool {
                lhs.image == rhs.image &&
                lhs.showsURL == rhs.showsURL &&
                lhs.imageMetadata == rhs.imageMetadata
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(image)
                hasher.combine(showsURL)
                hasher.combine(imageMetadata)
            }
        }
    }
}
