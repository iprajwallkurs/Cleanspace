import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var model: DashboardViewModel
    var body: some View {
        ZStack {
            AmbientBackground()
            List {
            Section { NavigationLink { CategoryDetailView(category: .similarPhotos) } label: { row(.similarPhotos) }; NavigationLink { CategoryDetailView(category: .screenshots) } label: { row(.screenshots) }; NavigationLink { CategoryDetailView(category: .largeVideos) } label: { row(.largeVideos) } } header: { Text("Photos & video") }
            Section { NavigationLink { CategoryDetailView(category: .duplicateContacts) } label: { row(.duplicateContacts) } } header: { Text("People") }
            Section { Text("All analysis happens on this device. ClearSpace only asks Photos and Contacts to read the items you choose to review.").font(.footnote).foregroundStyle(Color.inkMuted) }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Clean")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { model.isReviewPresented = true } label: { Image(systemName: "checklist") }.pressHaptic(.light).disabled(model.selectedPhotos.isEmpty && model.selectedContacts.isEmpty) } }
    }
    private func row(_ category: CleanerCategory) -> some View {
        let stats = model.categoryCounts[category] ?? (0, 0)
        return Label { VStack(alignment: .leading) { Text(category.rawValue); Text(stats.bytes > 0 ? stats.bytes.formattedBytes + " to review" : "\(stats.count) matches").font(.caption).foregroundStyle(Color.inkMuted) } } icon: { Image(systemName: category.symbol).foregroundStyle(category.tint).frame(width: 26) }
    }
}
