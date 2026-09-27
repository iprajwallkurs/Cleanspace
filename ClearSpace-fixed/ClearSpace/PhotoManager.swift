import Foundation
import Photos

@MainActor
final class PhotoManager: ObservableObject {
    private static let largeVideoThreshold: Int64 = 250 * 1_024 * 1_024
    @Published private(set) var permission: PermissionState = .notDetermined
    @Published private(set) var screenshots: [PhotoItem] = []
    @Published private(set) var largeVideos: [PhotoItem] = []
    @Published private(set) var similarGroups: [SimilarGroup] = []
    @Published private(set) var isScanning = false
    @Published var errorMessage: String?

    init() { updatePermission() }

    func updatePermission() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: permission = .authorized
        case .limited: permission = .limited
        case .denied: permission = .denied
        case .restricted: permission = .restricted
        case .notDetermined: permission = .notDetermined
        @unknown default: permission = .denied
        }
    }

    func requestAccess() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized: permission = .authorized
        case .limited: permission = .limited
        case .denied: permission = .denied
        case .restricted: permission = .restricted
        case .notDetermined: permission = .notDetermined
        @unknown default: permission = .denied
        }
    }

    func scan() async {
        guard permission == .authorized || permission == .limited else { return }
        isScanning = true
        let result = await Task.detached(priority: .userInitiated) {
            Self.fetchLocalAssets()
        }.value
        screenshots = result.screenshots
        largeVideos = result.videos
            .filter { $0.byteEstimate >= Self.largeVideoThreshold }
            .sorted { $0.byteEstimate > $1.byteEstimate }
        similarGroups = Self.makeSimilarGroups(from: result.photos)
        isScanning = false
    }

    func delete(_ items: [PhotoItem]) async throws {
        let assets = items.map(\.asset)
        guard !assets.isEmpty else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }) { success, error in
                if let error { continuation.resume(throwing: error) }
                else if success { continuation.resume() }
                else { continuation.resume(throwing: CocoaError(.fileWriteUnknown)) }
            }
        }
        await scan()
    }

    nonisolated private static func fetchLocalAssets() -> (photos: [PhotoItem], screenshots: [PhotoItem], videos: [PhotoItem]) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: options)
        var photos: [PhotoItem] = []
        var screenshots: [PhotoItem] = []
        var videos: [PhotoItem] = []
        assets.enumerateObjects { asset, _, _ in
            let bytes = estimateBytes(for: asset)
            let isScreenshot = asset.mediaType == .image && asset.mediaSubtypes.contains(.photoScreenshot)
            let item = PhotoItem(id: asset.localIdentifier, asset: asset, kind: isScreenshot ? .screenshots : (asset.mediaType == .video ? .largeVideos : .similarPhotos), byteEstimate: bytes, createdAt: asset.creationDate, pixelWidth: asset.pixelWidth, pixelHeight: asset.pixelHeight, duration: asset.duration, isBest: false)
            if isScreenshot { screenshots.append(item) }
            else if asset.mediaType == .video { videos.append(item) }
            else if asset.mediaType == .image { photos.append(item) }
        }
        return (photos, screenshots, videos)
    }

    nonisolated private static func estimateBytes(for asset: PHAsset) -> Int64 {
        if let resource = PHAssetResource.assetResources(for: asset).first,
           let number = resource.value(forKey: "fileSize") as? NSNumber {
            return number.int64Value
        }
        if asset.mediaType == .video { return Int64(max(asset.duration, 1) * 8_000_000) }
        return Int64(max(asset.pixelWidth * asset.pixelHeight, 1)) * 3 / 2
    }

    nonisolated private static func makeSimilarGroups(from photos: [PhotoItem]) -> [SimilarGroup] {
        let grouped = Dictionary(grouping: photos) { photo in
            let day = photo.createdAt.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
            return "\(photo.pixelWidth)x\(photo.pixelHeight)-\(day?.year ?? 0)-\(day?.month ?? 0)-\(day?.day ?? 0)"
        }
        return grouped.values.compactMap { items in
            guard items.count > 1 else { return nil }
            let ranked = items.sorted { lhs, rhs in
                let lhsPixels = lhs.pixelWidth * lhs.pixelHeight
                let rhsPixels = rhs.pixelWidth * rhs.pixelHeight
                if lhsPixels != rhsPixels { return lhsPixels > rhsPixels }
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
            let marked = ranked.enumerated().map { index, item in
                PhotoItem(id: item.id, asset: item.asset, kind: item.kind, byteEstimate: item.byteEstimate, createdAt: item.createdAt, pixelWidth: item.pixelWidth, pixelHeight: item.pixelHeight, duration: item.duration, isBest: index == 0)
            }
            return SimilarGroup(id: marked.map(\.id).joined(separator: ":"), items: marked)
        }.sorted { $0.bytes > $1.bytes }
    }
}
