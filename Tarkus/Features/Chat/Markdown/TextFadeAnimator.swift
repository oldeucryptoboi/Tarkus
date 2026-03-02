import Foundation
import CoreGraphics

// MARK: - TextFadeAnimator

/// Manages fade-in animation for text blocks during streaming.
/// Mirrors OpenAI's `OAIMarkdown.TextFadeAnimator`.
final class TextFadeAnimator {

    private var configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    // MARK: - Configuration

    /// Configuration for text fade animation behavior.
    struct Configuration {
        /// Duration of the fade-in animation in seconds.
        var fadeDuration: CGFloat

        /// Delay between character fade-ins during streaming.
        var characterDelay: CGFloat

        init(fadeDuration: CGFloat = 0.3, characterDelay: CGFloat = 0.02) {
            self.fadeDuration = fadeDuration
            self.characterDelay = characterDelay
        }
    }
}
