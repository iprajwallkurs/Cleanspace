import Foundation
import Photos
import Contacts

struct StorageSnapshot: Equatable {
    let usedBytes: Int64
    let freeBytes: Int64
    let totalBytes: Int64

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

enum CleanerCategory: String, CaseIterable, Identifiable, Hashable {
    case similarPhotos = "Similar photos"
    case screenshots = "Screenshots"
    case largeVideos = "Large videos"
    case duplicateContacts = "Duplicate contacts"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .similarPhotos: return "square.stack.3d.up"
        case .screenshots: return "camera.viewfinder"
        case .largeVideos: return "film.stack"
        case .duplicateContacts: return "person.2"
        }
    }
    var tintName: String {
        switch self {
        case .similarPhotos: return "coral"
        case .screenshots: return "gold"
        case .largeVideos: return "blue"
        case .duplicateContacts: return "green"
        }
    }
}

struct PhotoItem: Identifiable {
    let id: String
    let asset: PHAsset
    let kind: CleanerCategory
    let byteEstimate: Int64
    let createdAt: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    var isSelected = false
    var isBest = false
}

struct SimilarGroup: Identifiable {
    let id: String
    let items: [PhotoItem]
    var removableItems: [PhotoItem] { items.filter { !$0.isBest } }
    var bytes: Int64 { removableItems.reduce(0) { $0 + $1.byteEstimate } }
}

struct ContactItem: Identifiable {
    let id: String
    let contact: CNContact
    let displayName: String
    let detail: String
    let matchKey: String
    var isSelected = false
}

struct DuplicateContactGroup: Identifiable {
    let id: String
    let items: [ContactItem]
}

enum PermissionState: Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

extension Int64 {
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
