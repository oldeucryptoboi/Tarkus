import SwiftUI

// MARK: - MetricsBarView

/// Compact horizontal bar displaying token usage and cost metrics.
struct MetricsBarView: View {

    // MARK: - Properties

    let metrics: UsageMetrics?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            metricItem(label: "In", value: formatTokens(metrics?.inputTokens ?? 0))
            metricItem(label: "Out", value: formatTokens(metrics?.outputTokens ?? 0))
            Spacer()
            metricItem(label: "Cost", value: formatCost(metrics?.totalCost ?? 0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Components

    private func metricItem(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit().weight(.medium))
        }
    }

    // MARK: - Formatting

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func formatCost(_ cost: Double) -> String {
        String(format: "$%.4f", cost)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MetricsBarView(metrics: UsageMetrics(
            inputTokens: 12450,
            outputTokens: 3200,
            cacheReadTokens: 8000,
            cacheWriteTokens: 1000,
            totalCost: 0.0342
        ))
        MetricsBarView(metrics: nil)
    }
}
