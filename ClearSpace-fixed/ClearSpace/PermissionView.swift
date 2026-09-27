import SwiftUI
import UIKit

struct PermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: DashboardViewModel
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "lock.shield.fill").font(.system(size: 42)).foregroundStyle(Color.brandCoral)
                Text("Your library stays yours").font(.title.bold())
                Text("ClearSpace uses Photos and Contacts only on this iPhone. Grant access so it can find items for your review. Nothing is removed automatically.").foregroundStyle(Color.inkMuted)
                Spacer()
                PermissionRow(title: "Photos", state: model.photos.permission, icon: "photo.on.rectangle")
                PermissionRow(title: "Contacts", state: model.contacts.permission, icon: "person.2")
                Button(action: handleAccess) {
                    Text(hasDeniedPermission ? "Open Settings" : "Grant access")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandCoral)
            }
            .padding(24)
            .background(Color.canvas)
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onAppear {
                model.photos.updatePermission()
                model.contacts.updatePermission()
            }
        }
    }

    private var hasDeniedPermission: Bool {
        model.photos.permission == .denied || model.contacts.permission == .denied
    }

    private func handleAccess() {
        if hasDeniedPermission {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } else {
            Task {
                await model.requestPermissionsIfNeeded()
                dismiss()
            }
        }
    }
}
struct PermissionRow: View { let title: String; let state: PermissionState; let icon: String; var body: some View { HStack { Image(systemName: icon).foregroundStyle(Color.brandCoral).frame(width: 28); Text(title).fontWeight(.semibold); Spacer(); Text(label).font(.caption.weight(.semibold)).foregroundStyle(state == .authorized || state == .limited ? Color.brandGreen : Color.inkMuted) } .padding(14).background(Color(uiColor: .secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)) }; private var label: String { switch state { case .authorized: return "Allowed"; case .limited: return "Limited"; case .denied: return "Open Settings"; case .restricted: return "Restricted"; case .notDetermined: return "Not yet" } } }
