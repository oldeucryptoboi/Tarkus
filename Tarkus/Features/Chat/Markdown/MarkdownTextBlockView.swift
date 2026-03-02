import Foundation

#if canImport(AppKit)
import AppKit

// MARK: - MarkdownTextBlockView (macOS)

/// Core AppKit view that renders attributed text using TextKit 2.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlockView`.
///
/// - Non-editable, selectable
/// - Transparent background
/// - Self-sizing via intrinsicContentSize
class MarkdownTextBlockView: NSView, ExclusiveSelectionView, MarkdownSelectionSource, TextFindableView {

    // MARK: - OAI Public Properties

    var uniqueIdentifier: AnyHashable?
    var disableInstantMarkdownLinkTaps: Bool = false
    var selectionHandlers: MarkdownTextSelectionHandlers = .none
    var menus: MarkdownMenus = .none
    var highlightFramesUpdatedHandler: (([String: CGRect]) -> ())?
    var didInvalidateIntrinsicContentSize: () -> () = {}

    // MARK: - Properties

    private let textView: NSTextView
    private let textContainer: NSTextContainer

    var attributedText: NSAttributedString = NSAttributedString() {
        didSet {
            guard attributedText != oldValue else { return }
            textView.textStorage?.setAttributedString(attributedText)
            invalidateIntrinsicContentSize()
            needsLayout = true
        }
    }

    var currentSelection: NSAttributedString? {
        let range = textView.selectedRange()
        guard range.length > 0, let storage = textView.textStorage else { return nil }
        return storage.attributedSubstring(from: range)
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager = textView.layoutManager,
              let container = textView.textContainer else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 0)
        }
        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(usedRect.height))
    }

    // MARK: - Init

    override init(frame: NSRect) {
        // Set up TextKit stack
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = true
        textView.textContainerInset = .zero
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.isAutomaticLinkDetectionEnabled = true
        textView.autoresizingMask = [.width]

        super.init(frame: frame)

        addSubview(textView)
        textView.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout & Lifecycle

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        didInvalidateIntrinsicContentSize()
    }

    override func layout() {
        super.layout()
        let oldWidth = textContainer.containerSize.width
        textView.frame = bounds
        textContainer.containerSize = NSSize(width: bounds.width, height: .greatestFiniteMagnitude)
        // Only invalidate if the width actually changed to avoid infinite layout loops
        if bounds.width != oldWidth {
            invalidateIntrinsicContentSize()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func frame(forAlignmentRect alignmentRect: NSRect) -> NSRect {
        super.frame(forAlignmentRect: alignmentRect)
    }

    // MARK: - Cursor & Tracking

    override func resetCursorRects() {
        super.resetCursorRects()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
    }

    // MARK: - Key Events

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
    }

    // MARK: - Menus

    override func menu(for event: NSEvent) -> NSMenu? {
        super.menu(for: event)
    }

    // MARK: - First Responder

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
    }

    // MARK: - Accessibility

    override func accessibilityPerformPress() -> Bool {
        false
    }

    // MARK: - Menu Validation

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        true
    }

    // MARK: - Selection

    override func selectAll(_ sender: Any?) {
        textView.selectAll(sender)
    }

    func clearSelection() {
        textView.setSelectedRange(NSRange(location: 0, length: 0))
    }

    // MARK: - Reference Path

    func rects(for path: MarkdownReferencePath, relativeTo view: NSView) -> [CGRect] {
        []
    }
}

#else
import UIKit

// MARK: - MarkdownTextBlockView (iOS)

/// Core UIKit view that renders attributed text.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlockView`.
final class MarkdownTextBlockView: UIView {

    // MARK: - Properties

    private let textView: UITextView

    var attributedText: NSAttributedString = NSAttributedString() {
        didSet {
            textView.attributedText = attributedText
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = textView.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(size.height))
    }

    // MARK: - Init

    override init(frame: CGRect) {
        textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = .link

        super.init(frame: frame)

        addSubview(textView)
        textView.frame = bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.frame = bounds
        invalidateIntrinsicContentSize()
    }

    func clearSelection() {
        textView.selectedRange = NSRange(location: 0, length: 0)
    }
}

#endif
