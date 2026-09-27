import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: DashboardViewModel
    @State private var showFinalConfirmation = false
    @State private var isCleaning = false
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                List {
                    Section { HStack { Image(systemName: "shield.checkered").font(.title2).foregroundStyle(Color.brandGreen); VStack(alignment: .leading, spacing: 4) { Text("Final safety check").font(.headline); Text("Nothing is deleted until you confirm below.").font(.caption).foregroundStyle(.secondary) } } .padding(4) }
                Section("Photos & videos") { ForEach(model.selectedPhotos) { item in HStack { PhotoThumbnail(asset: item.asset).frame(width: 46, height: 46).clipShape(RoundedRectangle(cornerRadius: 8)); Text(item.byteEstimate.formattedBytes); Spacer(); Text(item.kind.rawValue).font(.caption).foregroundStyle(Color.inkMuted) } } }
                if !model.selectedContacts.isEmpty { Section("Contacts") { ForEach(model.selectedContacts) { item in Label(item.displayName, systemImage: "person.crop.circle") } } }
                Section { HStack { VStack(alignment: .leading, spacing: 3) { Text("Space to reclaim").font(.headline); Text("A final look before cleanup.").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(model.selectedBytes.formattedBytes).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(Color.brandCoral) } .padding(4) }
                Section { Button { showFinalConfirmation = true } label: { HStack { Spacer(); if isCleaning { ProgressView().tint(.white) } else { Label("Clean Up Space", systemImage: "sparkles") }; Spacer() } }.pressHaptic(.rigid).buttonStyle(.borderedProminent).tint(Color.brandCoral).disabled(isCleaning || (model.selectedPhotos.isEmpty && model.selectedContacts.isEmpty)) }
            }
            .scrollContentBackground(.hidden).navigationTitle("Review removal").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() }.pressHaptic(.light) } }
            .confirmationDialog("Remove selected items?", isPresented: $showFinalConfirmation, titleVisibility: .visible) { Button("Remove permanently", role: .destructive) { isCleaning = true; UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); Task { await model.commit(); isCleaning = false } }; Button("Cancel", role: .cancel) {} } message: { Text("This cannot be undone from ClearSpace. Photos will move to Recently Deleted according to your Photos settings.") }
            }
        }
    }
}
