import Foundation

// MARK: - AttributedStringRepresentation

/// Protocol for types that can serve as attributed string representations.
/// Mirrors OpenAI's `OAIMarkdown.AttributedStringRepresentation`.
///
/// `Foundation.AttributedString` conforms to this protocol in OAI's implementation.
/// We extend `NSAttributedString` as well for our NSAttributedString-based pipeline.
protocol AttributedStringRepresentation {
}

// MARK: - NSAttributedString Conformance

extension NSAttributedString: AttributedStringRepresentation {
}

// MARK: - Foundation.AttributedString Conformance

@available(macOS 12, iOS 15, *)
extension AttributedString: AttributedStringRepresentation {
}
