import SwiftUI

// MARK: - MarkdownTestView

/// Debug view for A/B testing our markdown renderer against ChatGPT.
/// Shows comprehensive markdown samples rendered with our `MarkdownText` view.
///
/// To compare: paste the same `testMarkdown` string into ChatGPT and
/// compare the rendering side-by-side.
struct MarkdownTestView: View {

    @State private var selectedSample = 0
    @State private var customInput = ""
    @State private var showCustom = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Sample picker
                Picker("Sample", selection: $selectedSample) {
                    ForEach(MarkdownTestSamples.allSamples.indices, id: \.self) { i in
                        Text(MarkdownTestSamples.allSamples[i].name).tag(i)
                    }
                    Text("Custom Input").tag(-1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider()

                if selectedSample == -1 {
                    // Custom input mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Raw Markdown")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $customInput)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .border(Color.secondary.opacity(0.3))

                        Text("Rendered Output")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        MarkdownText(content: customInput)
                    }
                    .padding(.horizontal)
                } else {
                    let sample = MarkdownTestSamples.allSamples[selectedSample]

                    // Raw markdown (collapsible)
                    DisclosureGroup("Raw Markdown") {
                        Text(sample.markdown)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.horizontal)

                    Divider()

                    // Rendered output
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rendered Output")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        MarkdownText(content: sample.markdown)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle("Markdown A/B Test")
    }
}

// MARK: - Test Samples

enum MarkdownTestSamples {

    struct Sample {
        let name: String
        let markdown: String
    }

    static let allSamples: [Sample] = [
        oaiComparison,
        inlineFormatting,
        headings,
        codeBlocks,
        lists,
        tables,
        blockquotes,
        mixed,
        eddiResponse,
    ]

    // MARK: - OAI Comparison (exact ChatGPT response for pixel-diff)

    static let oaiComparison = Sample(
        name: "OAI Compare",
        markdown: """
        # Quicksort in Python

        ## ✅ Implementation

        ```python
        def quicksort(arr):
            if len(arr) <= 1:
                return arr

            pivot = arr[len(arr) // 2]
            left = [x for x in arr if x < pivot]
            middle = [x for x in arr if x == pivot]
            right = [x for x in arr if x > pivot]

            return quicksort(left) + middle + quicksort(right)

        # Example usage
        numbers = [10, 7, 8, 9, 1, 5]
        sorted_numbers = quicksort(numbers)
        print(sorted_numbers)
        ```

        ## 📘 Brief Explanation

        Quicksort is a divide-and-conquer algorithm:

        1. Choose a pivot element.
        2. Partition the list into:
           - Elements **less than** the pivot
           - Elements **equal to** the pivot
           - Elements **greater than** the pivot
        3. Recursively sort the sub-lists.

        **Time complexity:** `O(n log n)` average, `O(n²)` worst case.

        ## 📊 Sorting Algorithm Comparison

        | Algorithm | Best | Average | Worst | Space |
        |-----------|------|---------|-------|-------|
        | **Quicksort** | `O(n log n)` | `O(n log n)` | `O(n²)` | `O(log n)` |
        | **Merge Sort** | `O(n log n)` | `O(n log n)` | `O(n log n)` | `O(n)` |
        | **Heap Sort** | `O(n log n)` | `O(n log n)` | `O(n log n)` | `O(1)` |
        | **Bubble Sort** | `O(n)` | `O(n²)` | `O(n²)` | `O(1)` |
        | **Insertion Sort** | `O(n)` | `O(n²)` | `O(n²)` | `O(1)` |

        ## 🎯 When to Use Each

        - **Quicksort** — Best general-purpose sort; fast in practice with good cache behavior
        - **Merge Sort** — When you need *stable* sorting or are sorting linked lists
        - **Heap Sort** — When you need *guaranteed* `O(n log n)` with no extra memory
        - **Bubble Sort** — Only for tiny datasets or educational purposes
        - **Insertion Sort** — Best for *nearly sorted* data or very small arrays

        > 💡 **Pro tip:** Python's built-in `sorted()` uses **Timsort**, a hybrid of merge sort and insertion sort, optimized for real-world data.
        """
    )

    // MARK: - Individual Samples

    static let inlineFormatting = Sample(
        name: "Inline",
        markdown: """
        Here is **bold text**, *italic text*, and ***bold italic*** together.

        This has `inline code` and ~~strikethrough~~ text.

        Here's a [link to Apple](https://apple.com) and some **bold with `code` inside**.
        """
    )

    static let headings = Sample(
        name: "Headings",
        markdown: """
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6

        Regular paragraph text after headings.
        """
    )

    static let codeBlocks = Sample(
        name: "Code",
        markdown: """
        Here's a Swift function:

        ```swift
        func fibonacci(_ n: Int) -> Int {
            guard n > 1 else { return n }
            return fibonacci(n - 1) + fibonacci(n - 2)
        }

        let result = fibonacci(10)
        print("Fibonacci(10) = \\(result)")
        ```

        And some JavaScript:

        ```javascript
        const fetchData = async (url) => {
            const response = await fetch(url);
            const data = await response.json();
            return data.map(item => ({
                id: item.id,
                name: item.name.toUpperCase(),
                active: item.status === 'active'
            }));
        };
        ```

        And Python:

        ```python
        def merge_sort(arr):
            if len(arr) <= 1:
                return arr
            mid = len(arr) // 2
            left = merge_sort(arr[:mid])
            right = merge_sort(arr[mid:])
            return merge(left, right)
        ```

        And a shell command:

        ```bash
        curl -s https://api.example.com/data | jq '.results[] | {name, score}'
        ```
        """
    )

    static let lists = Sample(
        name: "Lists",
        markdown: """
        **Unordered list:**

        - First item
        - Second item with **bold**
        - Third item with `code`
          - Nested item A
          - Nested item B
            - Deep nested
        - Fourth item

        **Ordered list:**

        1. Step one
        2. Step two
        3. Step three
           1. Sub-step A
           2. Sub-step B
        4. Step four
        """
    )

    static let tables = Sample(
        name: "Tables",
        markdown: """
        | Feature | Status | Priority |
        |---------|--------|----------|
        | Markdown rendering | Done | High |
        | Code highlighting | Done | High |
        | Table support | Done | Medium |
        | Image support | Planned | Low |

        Right-aligned numbers:

        | Metric | Value | Change |
        |--------|------:|-------:|
        | Users | 1,234 | +12% |
        | Revenue | $45.6K | +8% |
        | Retention | 94.2% | -0.5% |
        """
    )

    static let blockquotes = Sample(
        name: "Quotes",
        markdown: """
        > This is a blockquote with **bold** and *italic* text.
        >
        > It can span multiple paragraphs.

        Regular text between quotes.

        > Another quote with `inline code` and a [link](https://example.com).
        """
    )

    static let mixed = Sample(
        name: "Mixed",
        markdown: """
        ## Project Status Report

        The project is progressing well. Here's a summary:

        ### Key Metrics

        | Metric | This Week | Last Week |
        |--------|-----------|-----------|
        | Commits | 47 | 32 |
        | PRs merged | 12 | 8 |
        | Issues closed | 15 | 11 |

        ### Highlights

        1. **Markdown renderer** — complete rewrite using cmark-gfm + Highlightr
        2. **Performance** — 3x faster rendering with TextKit 2
        3. **Code blocks** — syntax highlighting for 180+ languages

        ### Code Example

        ```swift
        struct ContentView: View {
            @State private var message = ""

            var body: some View {
                VStack {
                    MarkdownText(content: message)
                    TextField("Type here...", text: $message)
                }
            }
        }
        ```

        > **Note:** This is still in active development. See the [docs](https://docs.example.com) for details.

        ---

        *Last updated: March 2026*
        """
    )

    static let eddiResponse = Sample(
        name: "EDDIE",
        markdown: """
        Your Moltbook posts are performing well! Here's a breakdown:

        ### Post Performance (Last 7 Days)

        | Post | Views | Likes | Comments |
        |------|------:|------:|---------:|
        | "The Art of Delegation" | 1,247 | 89 | 23 |
        | "Why I Stopped Using To-Do Lists" | 3,891 | 312 | 67 |
        | "Building in Public: Week 12" | 892 | 45 | 12 |

        ### Key Takeaways

        - Your **most viral post** was "Why I Stopped Using To-Do Lists" with nearly 4K views
        - Engagement rate is **8.2%**, which is above the platform average of 5.1%
        - Comments are trending up — you're building a real community

        ### Recommended Next Steps

        1. Write a **follow-up** to the to-do list post (high demand in comments)
        2. Post during the `10am-12pm` window for best reach
        3. Try a **thread format** — they're getting 2x more impressions lately

        > 💡 **Pro tip:** Your audience responds best to *contrarian takes* backed by personal experience. Lean into that.

        Want me to draft the follow-up post?
        """
    )
}

// MARK: - Preview

#Preview {
    MarkdownTestView()
        .frame(width: 600, height: 800)
}
