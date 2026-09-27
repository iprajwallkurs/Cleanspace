import Foundation
import Photos

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var isReviewPresented = false
    @Published var selectedPhotos: [PhotoItem] = []
    @Published var selectedContacts: [ContactItem] = []
    @Published var didFinishOnboarding = false
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var scanMessage = "Ready to scan"
    let storage = StorageManager()
    let photos = PhotoManager()
    let contacts = ContactManager()

    var selectedBytes: Int64 {
        selectedPhotos.reduce(0) { $0 + $1.byteEstimate }
    }
    var selectedCount: Int { selectedPhotos.count + selectedContacts.count }
    var possibleBytes: Int64 {
        photos.similarGroups.reduce(0) { $0 + $1.bytes } + photos.screenshots.reduce(0) { $0 + $1.byteEstimate } + photos.largeVideos.reduce(0) { $0 + $1.byteEstimate }
    }
    var categoryCounts: [CleanerCategory: (count: Int, bytes: Int64)] {
        [.similarPhotos: (photos.similarGroups.reduce(0) { $0 + $1.removableItems.count }, photos.similarGroups.reduce(0) { $0 + $1.bytes }), .screenshots: (photos.screenshots.count, photos.screenshots.reduce(0) { $0 + $1.byteEstimate }), .largeVideos: (photos.largeVideos.count, photos.largeVideos.reduce(0) { $0 + $1.byteEstimate }), .duplicateContacts: (contacts.duplicateGroups.reduce(0) { $0 + $1.items.count - 1 }, 0)]
    }

    func start() async {
        scanMessage = "Checking your device..."
        storage.refresh()
        async let photoScan: Void = scanPhotosIfAllowed()
        async let contactScan: Void = scanContactsIfAllowed()
        _ = await (photoScan, contactScan)
        lastScanDate = Date()
        scanMessage = "Scan complete"
    }

    private func scanPhotosIfAllowed() async {
        guard photos.permission == .authorized || photos.permission == .limited else { return }
        scanMessage = "Scanning photos and videos..."
        await photos.scan()
    }

    private func scanContactsIfAllowed() async {
        guard contacts.permission == .authorized else { return }
        scanMessage = "Checking duplicate contacts..."
        await contacts.scan()
    }

    func requestPermissionsIfNeeded() async {
        if photos.permission == .notDetermined { await photos.requestAccess() }
        if contacts.permission == .notDetermined { await contacts.requestAccess() }
        await start()
    }

    func toggle(_ item: PhotoItem) {
        if let index = selectedPhotos.firstIndex(where: { $0.id == item.id }) { selectedPhotos.remove(at: index) }
        else { selectedPhotos.append(item) }
    }

    func toggle(_ item: ContactItem) {
        if let index = selectedContacts.firstIndex(where: { $0.id == item.id }) { selectedContacts.remove(at: index) }
        else { selectedContacts.append(item) }
    }

    func commit() async {
        do {
            if !selectedPhotos.isEmpty { try await photos.delete(selectedPhotos) }
            if !selectedContacts.isEmpty { try contacts.delete(selectedContacts); await contacts.scan() }
            selectedPhotos.removeAll(); selectedContacts.removeAll(); storage.refresh(); isReviewPresented = false
        } catch { photos.errorMessage = error.localizedDescription }
    }
}
