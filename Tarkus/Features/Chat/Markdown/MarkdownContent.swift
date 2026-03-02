import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownContent

/// Represents markdown content that can be compiled into a `MarkdownResult`.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownContent`.
enum MarkdownContent: Equatable {

    /// Plain markdown text.
    case markdown(String)

    /// Whether the content is empty.
    var isEmpty: Bool {
        switch self {
        case .markdown(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Compile this content into a `MarkdownResult`.
    /// Mirrors OpenAI's `MarkdownContent.compiled(plugins:customLinkParsers:traitCollection:options:appliesSourcePositionAttributes:)`.
    func compiled(
        plugins: [MarkdownPlugin] = [],
        customLinkParsers: [MarkdownLinkParser] = [],
        traitCollection: PlatformAppearance = MarkdownContent.defaultAppearance,
        options: MarkdownOptions = .init(),
        appliesSourcePositionAttributes: Bool = false
    ) -> MarkdownResult {
        switch self {
        case .markdown(let text):
            let compiler = MarkdownCompiler(
                plugins: plugins,
                customLinkParsers: customLinkParsers,
                traitCollection: traitCollection
            )
            return compiler.result(
                from: text,
                options: options,
                appliesSourcePositionAttributes: appliesSourcePositionAttributes
            )
        }
    }

    // MARK: - Default Appearance

    private static var defaultAppearance: PlatformAppearance {
        #if canImport(AppKit)
        return NSAppearance.current ?? NSAppearance(named: .aqua)!
        #else
        return UITraitCollection.current
        #endif
    }

    // MARK: - ImageMetadata

    /// Metadata about an image referenced in markdown content.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownContent.ImageMetadata`.
    struct ImageMetadata: Hashable {

        /// Unique ID for the image generation process.
        var imageGenerationID: String?

        /// Progress of image generation (0.0 to 1.0).
        var imageGenerationLoadedAmount: CGFloat?

        /// Whether the generated image has a transparent background.
        var imageGenerationIsTransparent: Bool?

        /// DALL-E specific generation ID.
        var dalleGenerationID: String?

        /// The prompt used for DALL-E generation.
        var dallePrompt: String?

        /// Image dimensions.
        var size: CGSize

        /// Whether the image is still being generated.
        var isImageStillGenerating: Bool {
            guard let progress = imageGenerationLoadedAmount else { return false }
            return progress < 1.0
        }

        init(
            imageGenerationID: String? = nil,
            imageGenerationLoadedAmount: CGFloat? = nil,
            imageGenerationIsTransparent: Bool? = nil,
            dalleGenerationID: String? = nil,
            dallePrompt: String? = nil,
            size: CGSize = .zero
        ) {
            self.imageGenerationID = imageGenerationID
            self.imageGenerationLoadedAmount = imageGenerationLoadedAmount
            self.imageGenerationIsTransparent = imageGenerationIsTransparent
            self.dalleGenerationID = dalleGenerationID
            self.dallePrompt = dallePrompt
            self.size = size
        }
    }
}

// MARK: - MarkdownContentUserRole

/// The role of the user whose content is being rendered, affecting layout alignment and available actions.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownContentUserRole`.
enum MarkdownContentUserRole: Hashable, CaseIterable {
    case user
    case assistant

    static var allCases: [MarkdownContentUserRole] {
        [.user, .assistant]
    }

    /// Text alignment for this role.
    var alignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .user: return .trailing
        case .assistant: return .leading
        }
    }

    /// Standard image menu items available for this role.
    var standardMenu: [MarkdownImageActionMenuItem] {
        switch self {
        case .user: return [.share]
        case .assistant: return [.share, .save]
        }
    }
}

import SwiftUI
