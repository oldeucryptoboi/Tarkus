import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownPlugin

/// Plugin protocol for pre/post-processing markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownPlugin`.
///
/// Plugins run in two phases:
/// 1. `preprocess` — mutate the raw markdown string before parsing
/// 2. `postProcess` — mutate the compiled result after parsing
///
/// OAI constrains this to `AnyObject` (class-only).
protocol MarkdownPlugin: AnyObject {
    func preprocess(markdown: inout String)
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance)
}

// Default implementations — plugins can opt into either or both phases.
extension MarkdownPlugin {
    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}
