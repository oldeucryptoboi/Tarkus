import Foundation

// MARK: - ExclusiveSelectionView

/// A view that participates in exclusive selection management.
/// When one view gains selection, others should lose theirs.
/// Mirrors OpenAI's `OAIMarkdown.ExclusiveSelectionView`.
protocol ExclusiveSelectionView: AnyObject {
}

// MARK: - MarkdownSelectionSource

/// A view that can be the source of a text selection.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownSelectionSource`.
protocol MarkdownSelectionSource: AnyObject {
}

// MARK: - TextFindableView

/// A view that supports text find/search operations.
/// Mirrors OpenAI's `OAIMarkdown.TextFindableView`.
protocol TextFindableView: AnyObject {
}

// MARK: - ExclusiveSelectionManager

/// Manages selection state across multiple views, ensuring only one view
/// has an active selection at a time.
/// Mirrors OpenAI's `OAIMarkdown.ExclusiveSelectionManager`.
final class ExclusiveSelectionManager {

    /// The currently selected view, held weakly to avoid retain cycles.
    private weak var currentSelection: ExclusiveSelectionView?

    init() {}

    /// Notifies the manager that a selection occurred in the given view.
    /// Any previously selected view loses its selection.
    func handleSelection(in view: ExclusiveSelectionView) {
        currentSelection = view
    }

    /// Notifies the manager that the given view is being removed.
    /// Clears the current selection if it matches.
    func handleRemoval(of view: ExclusiveSelectionView) {
        if currentSelection === view {
            currentSelection = nil
        }
    }
}
