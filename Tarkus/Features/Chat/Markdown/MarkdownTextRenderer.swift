import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownTextRenderer

/// TextKit 2 layout engine for rendering attributed text.
/// Tarkus-specific — this type does not exist in OAI's OAIMarkdown module.
/// OAI uses AppKit/UIKit text views directly; we use this as an internal
/// layout helper for our custom text block views.
///
/// Uses `NSTextLayoutManager` + `NSTextContentStorage` + `NSTextContainer`
/// for modern text layout with proper paragraph handling.
@MainActor
final class MarkdownTextRenderer {

    // MARK: - Properties

    var attributedString: NSAttributedString {
        didSet {
            textContentStorage.attributedString = attributedString
            invalidateLayout()
        }
    }

    var maxWidth: CGFloat = 0 {
        didSet {
            guard maxWidth != oldValue else { return }
            textContainer.size = CGSize(width: maxWidth, height: 0)
            invalidateLayout()
        }
    }

    private(set) var size: CGSize = .zero

    // MARK: - TextKit 2 Components

    lazy var textContainer: NSTextContainer = {
        let container = NSTextContainer(size: CGSize(width: maxWidth, height: 0))
        container.lineFragmentPadding = 0
        return container
    }()

    lazy var textContentStorage: NSTextContentStorage = {
        let storage = NSTextContentStorage()
        storage.attributedString = attributedString
        return storage
    }()

    lazy var textLayoutManager: NSTextLayoutManager = {
        let layoutManager = NSTextLayoutManager()
        layoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(layoutManager)
        return layoutManager
    }()

    // MARK: - Init

    init(attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    // MARK: - Layout

    func invalidateLayout() {
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        calculateSize()
    }

    func calculateSize() {
        var height: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            height = max(height, fragment.layoutFragmentFrame.maxY)
            return true
        }
        size = CGSize(width: maxWidth, height: ceil(height))
    }

    #if canImport(AppKit)
    func draw(in rect: CGRect) {
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            fragment.draw(at: fragment.layoutFragmentFrame.origin, in: NSGraphicsContext.current!.cgContext)
            return true
        }
    }
    #endif
}
