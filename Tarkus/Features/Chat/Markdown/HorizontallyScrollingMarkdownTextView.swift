import Foundation

#if canImport(AppKit)
import AppKit

// MARK: - HorizontallyScrollingMarkdownTextView (macOS)

/// NSView that wraps a text view inside a horizontal scroll view.
/// Used for code blocks where content may exceed the available width.
/// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextView`.
class HorizontallyScrollingMarkdownTextView: NSView {

    // MARK: - OAI Public Properties

    var showsHorizontalScrollIndicator: Bool = false
    var didInvalidateIntrinsicContentSize: () -> () = {}
    var openURL: (() -> Void)?
    var markdownOptions: MarkdownOptions?

    // MARK: - Properties

    private let textView: NSTextView
    private let scrollView: NSScrollView

    var attributedText: NSAttributedString = NSAttributedString() {
        didSet {
            guard attributedText != oldValue else { return }
            textView.textStorage?.setAttributedString(attributedText)
            invalidateIntrinsicContentSize()
            needsLayout = true
        }
    }

    override var isFlipped: Bool { true }

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

    convenience init(frame: CGRect, markdownOptions: MarkdownOptions, openURL: (() -> Void)?) {
        self.init(frame: frame)
        self.markdownOptions = markdownOptions
        self.openURL = openURL
    }

    override init(frame: NSRect) {
        // Text view with unlimited width for horizontal scrolling
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let container = NSTextContainer(containerSize: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.widthTracksTextView = false
        container.heightTracksTextView = false
        layoutManager.addTextContainer(container)

        textView = NSTextView(frame: .zero, textContainer: container)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = true
        textView.textContainerInset = .zero
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        scrollView.horizontalScrollElasticity = .automatic

        super.init(frame: frame)

        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        didInvalidateIntrinsicContentSize()
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds

        // Ensure text view is at least as wide as scroll view
        guard let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }

        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        let textWidth = max(usedRect.width + 2, bounds.width)
        let textHeight = max(usedRect.height, bounds.height)
        textView.frame = NSRect(x: 0, y: 0, width: textWidth, height: textHeight)
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
    }
}

#else
import UIKit

// MARK: - HorizontallyScrollingMarkdownTextView (iOS)

/// UIView that wraps a text view inside a horizontal scroll view.
final class HorizontallyScrollingMarkdownTextView: UIView {

    // MARK: - Properties

    private let textView: UITextView
    private let scrollView: UIScrollView

    var attributedText: NSAttributedString = NSAttributedString() {
        didSet {
            textView.attributedText = attributedText
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = textView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
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
        textView.textContainer.lineBreakMode = .byClipping
        textView.textContainer.widthTracksTextView = false
        textView.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false

        super.init(frame: frame)

        scrollView.addSubview(textView)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds

        let size = textView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size

        invalidateIntrinsicContentSize()
    }
}

#endif
