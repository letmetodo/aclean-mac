import SwiftUI

/// Shared receipt action for user documents, duplicates and other Trash-based cleanup.
struct CleanupUndoButton: View {
    let report: CleanReport
    @EnvironmentObject private var state: AppState
    @State private var restored: Set<String> = []
    @State private var busy = false
    @State private var finished = false

    var body: some View {
        Button(L10n.localized(finished ? .receiptUndoDone : .receiptUndoCleanupButton)) {
            busy = true
            let items = report.outcomes.flatMap(\.restoreItems)
            let excluded = restored
            Task {
                let result = await Task.detached(priority: .userInitiated) {
                    CleanupRestoreService.restore(items, excluding: excluded)
                }.value
                guard state.report?.id == report.id else { return }
                busy = false
                restored.formUnion(result.restoredIDs)
                finished = !items.isEmpty && result.failedPaths.isEmpty
                state.toast = finished
                    ? L10n.format(.receiptUndoSuccessNotice, result.restoredIDs.count, Fmt.size(result.restoredBytes))
                    : L10n.localized(.reviewUndoIncomplete)
            }
        }
        .disabled(busy || finished)
        .onChange(of: report.id) { _ in restored = []; busy = false; finished = false }
    }
}
