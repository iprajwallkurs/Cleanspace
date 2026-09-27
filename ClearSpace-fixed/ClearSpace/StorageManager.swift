import Foundation

@MainActor
final class StorageManager: ObservableObject {
    @Published private(set) var snapshot = StorageSnapshot(usedBytes: 0, freeBytes: 0, totalBytes: 0)

    func refresh() {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            snapshot = StorageSnapshot(usedBytes: max(0, total - free), freeBytes: free, totalBytes: total)
        } catch {
            snapshot = StorageSnapshot(usedBytes: 0, freeBytes: 0, totalBytes: 0)
        }
    }
}
