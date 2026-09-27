import SwiftUI
import PhotosUI
import UIKit

struct CategoryDetailView: View {
    @EnvironmentObject private var model: DashboardViewModel
    let category: CleanerCategory
    @State private var showReview = false

    var body: some View {
        Group {
            if category == .duplicateContacts { contactsView } else { photoView }
        }
        .background { AmbientBackground() }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showReview = true } label: { Image(systemName: "checklist") }.pressHaptic(.light).disabled(selectionCount == 0) } }
        .sheet(isPresented: $showReview) { ReviewView() }
    }

    private var selectionCount: Int { model.selectedPhotos.count + model.selectedContacts.count }
    private var items: [PhotoItem] { switch category { case .similarPhotos: return model.photos.similarGroups.flatMap(\.removableItems); case .screenshots: return model.photos.screenshots; case .largeVideos: return model.photos.largeVideos; case .duplicateContacts: return [] } }

    private var photoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(category == .similarPhotos ? "We keep the sharpest frame selected as your keeper. Review the rest before choosing what to remove." : "Select only the items you are ready to remove. They will still be reviewed once more before deletion.").font(.subheadline).foregroundStyle(.secondary)
                if items.isEmpty { EmptyState(title: model.photos.isScanning ? "Scanning your library..." : "Nothing here yet", icon: category.symbol) }
                else if category == .similarPhotos { ForEach(model.photos.similarGroups) { group in SimilarGroupView(group: group) } }
                else { LazyVStack(spacing: 10) { ForEach(items) { item in PhotoRow(item: item, selected: model.selectedPhotos.contains(where: { $0.id == item.id })) { model.toggle(item) } } } }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) { selectionBar }
    }

    private var contactsView: some View {
        List { ForEach(model.contacts.duplicateGroups) { group in Section { ForEach(group.items) { contact in ContactRow(item: contact, selected: model.selectedContacts.contains(where: { $0.id == contact.id })) { model.toggle(contact) } } } header: { Text("Possible duplicate") } } }
            .scrollContentBackground(.hidden)
            .overlay { if model.contacts.duplicateGroups.isEmpty { EmptyState(title: model.contacts.isScanning ? "Scanning contacts..." : "No duplicate contacts found", icon: category.symbol) } }
            .safeAreaInset(edge: .bottom) { selectionBar }
    }

    private var selectionBar: some View {
        Group {
            if selectionCount > 0 { Button { showReview = true } label: { Label("Review \(selectionCount) selected", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }.pressHaptic(.medium).buttonStyle(.borderedProminent).tint(.brandCoral).padding(.horizontal, 20).padding(.vertical, 10).background(.ultraThinMaterial) }
        }
    }
}

struct SimilarGroupView: View {
    @EnvironmentObject private var model: DashboardViewModel
    let group: SimilarGroup
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("\(group.items.count) similar shots").font(.subheadline.weight(.bold)); Spacer(); Text(group.bytes.formattedBytes).font(.caption.weight(.semibold)).foregroundStyle(Color.brandCoral) }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 10) { ForEach(group.items) { item in PhotoTile(item: item, selected: model.selectedPhotos.contains(where: { $0.id == item.id })) { if !item.isBest { model.toggle(item) } } } } }
        }
        .padding(14).glassCard(cornerRadius: 18)
    }
}

struct PhotoTile: View {
    let item: PhotoItem; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) { ZStack(alignment: .topTrailing) { PhotoThumbnail(asset: item.asset).frame(width: 118, height: 145).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)); if item.isBest { Text("KEEP").font(.system(size: 9, weight: .bold)).padding(5).background(Color.brandGreen).foregroundStyle(.white).clipShape(Capsule()).padding(6) } else { Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.title3).symbolRenderingMode(.palette).foregroundStyle(selected ? Color.brandCoral : .white, selected ? Color.brandCoral : .black.opacity(0.3)).padding(7).scaleEffect(selected ? 1 : 0.88).animation(.spring(response: 0.28, dampingFraction: 0.62), value: selected) } } }.pressHaptic(.light)
    }
}

struct PhotoRow: View {
    let item: PhotoItem; let selected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 12) { PhotoThumbnail(asset: item.asset).frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)); VStack(alignment: .leading, spacing: 4) { Text(item.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Photo").font(.subheadline.weight(.semibold)); Text(item.byteEstimate.formattedBytes + (item.duration > 0 ? "  •  \(Int(item.duration)) sec" : "")).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(selected ? Color.brandCoral : Color.inkMuted).scaleEffect(selected ? 1 : 0.88).animation(.spring(response: 0.28, dampingFraction: 0.62), value: selected) } }.buttonStyle(.plain).pressHaptic(.light).padding(10).glassCard(cornerRadius: 14) }
}

struct ContactRow: View { let item: ContactItem; let selected: Bool; let action: () -> Void; var body: some View { Button(action: action) { HStack { Image(systemName: "person.crop.circle.fill").font(.title).foregroundStyle(Color.brandGreen); VStack(alignment: .leading) { Text(item.displayName).font(.subheadline.weight(.semibold)); Text(item.detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundStyle(selected ? Color.brandCoral : Color.inkMuted).scaleEffect(selected ? 1 : 0.88).animation(.spring(response: 0.28, dampingFraction: 0.62), value: selected) } }.buttonStyle(.plain).pressHaptic(.light).padding(.vertical, 8) } }

struct PhotoThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?
    private static let cache = NSCache<NSString, UIImage>()

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemFill)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ProgressView().tint(Color.brandCoral)
            }
        }
        .task(id: asset.localIdentifier) { await load() }
    }

    private func load() async {
        let cacheKey = asset.localIdentifier as NSString
        if let cached = Self.cache.object(forKey: cacheKey) {
            image = cached
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        let size = CGSize(width: 300, height: 300)

        let result = await withCheckedContinuation { continuation in
            var didResume = false
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: image)
            }
        }
        if let result {
            Self.cache.setObject(result, forKey: cacheKey)
            image = result
        }
    }
}

struct EmptyState: View {
    let title: String
    let icon: String
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.brandCoral)
                .opacity(isPulsing ? 0.35 : 1)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear { isPulsing = true }
            Text(title).font(.headline)
            Text("Your device has a little more room to breathe.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}
