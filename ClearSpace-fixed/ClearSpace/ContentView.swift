import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: DashboardViewModel

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            TabView(selection: $model.selectedTab) {
                NavigationStack { DashboardView() }
                    .tabItem { Label("Overview", systemImage: "circle.hexagongrid.fill") }
                    .tag(0)
                NavigationStack { LibraryView() }
                    .tabItem { Label("Clean", systemImage: "wand.and.stars") }
                    .tag(1)
                NavigationStack { ActivityView() }
                    .tabItem { Label("Activity", systemImage: "chart.bar.xaxis") }
                    .tag(2)
                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                    .tag(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(Color.brandCoral)
        .task { await model.start() }
        .sheet(isPresented: $model.isReviewPresented) { ReviewView() }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var model: DashboardViewModel
    @State private var showPermissions = false

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    storageCard
                    scanStatusCard
                    if model.photos.permission != .authorized && model.photos.permission != .limited || model.contacts.permission != .authorized {
                        PermissionBanner { showPermissions = true }
                    }
                    categorySection
                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await model.start() } } label: {
                    Image(systemName: model.photos.isScanning ? "hourglass" : "arrow.clockwise")
                        .frame(width: 34, height: 34)
                }
                .pressHaptic(.light)
                .disabled(model.photos.isScanning)
            }
        }
        .sheet(isPresented: $showPermissions) { PermissionView() }
        .refreshable { await model.start() }
    }

    private var storageCard: some View {
        HStack(spacing: 18) {
            StorageRing(fraction: model.storage.snapshot.usedFraction).frame(width: 112, height: 112)
            VStack(alignment: .leading, spacing: 8) {
                Text("Storage").font(.headline)
                Text(model.storage.snapshot.usedBytes.formattedBytes).font(.system(size: 30, weight: .bold, design: .default)).contentTransition(.numericText())
                Text("of \(model.storage.snapshot.totalBytes.formattedBytes) used").font(.subheadline).foregroundStyle(.secondary)
                Label(model.storage.snapshot.freeBytes.formattedBytes + " free", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(Color.brandGreen)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .glassCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cleanup categories").font(.title3.weight(.bold))
                    Text("Review items before removing them.").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if model.possibleBytes > 0 { Text(model.possibleBytes.formattedBytes).font(.caption.weight(.bold)).foregroundStyle(Color.brandCoral) }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CleanerCategory.allCases) { category in
                    NavigationLink(value: category) { CategoryCard(category: category, stats: model.categoryCounts[category] ?? (0, 0)) }.buttonStyle(.plain)
                }
            }
            .navigationDestination(for: CleanerCategory.self) { CategoryDetailView(category: $0) }
        }
    }

    private var scanStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: model.photos.isScanning || model.contacts.isScanning ? "waveform.path.ecg" : "checkmark.circle.fill")
                    .foregroundStyle(model.photos.isScanning || model.contacts.isScanning ? Color.brandCoral : Color.brandGreen)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.scanMessage).font(.subheadline.weight(.semibold))
                    Text(model.lastScanDate.map { "Updated \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Start a local scan to find cleanup candidates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.selectedCount > 0 {
                    Button { model.isReviewPresented = true } label: { Label("Review", systemImage: "checklist") }
                        .font(.caption.weight(.bold))
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandCoral)
                } else {
                    Button { Task { await model.start() } } label: { Image(systemName: "arrow.clockwise") }
                        .buttonStyle(.bordered)
                        .disabled(model.photos.isScanning || model.contacts.isScanning)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private var privacyNote: some View {
        Label("Everything stays on this iPhone. You review every item before it leaves.", systemImage: "lock.shield.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)
            .padding(.horizontal, 4)
    }
}

struct CategoryCard: View {
    let category: CleanerCategory
    let stats: (count: Int, bytes: Int64)
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: category.symbol).font(.title3.weight(.semibold)).foregroundStyle(category.tint).frame(width: 38, height: 38).background(category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Spacer(minLength: 0)
            Text(category.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
            HStack(alignment: .firstTextBaseline) {
                Text(stats.bytes > 0 ? stats.bytes.formattedBytes : "\(stats.count)").font(.headline.weight(.bold)).contentTransition(.numericText())
                Text(stats.bytes > 0 ? "to review" : "matches").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 16)
    }
}

struct PermissionBanner: View {
    let action: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield").foregroundStyle(Color.brandCoral)
            VStack(alignment: .leading, spacing: 3) { Text("Finish setting up ClearSpace").font(.subheadline.weight(.semibold)); Text("Allow local access to scan your library.").font(.caption).foregroundStyle(.secondary) }
            Spacer()
            Button("Review", action: action).font(.caption.weight(.bold)).pressHaptic(.light).buttonStyle(.borderedProminent).tint(Color.brandCoral)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }
}

struct ActivityView: View {
    @EnvironmentObject private var model: DashboardViewModel

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Your cleanup history").font(.title3.weight(.bold))
                    Text("A private snapshot of what ClearSpace has checked on this device.").font(.subheadline).foregroundStyle(.secondary)
                    activityCard(icon: "checkmark.shield.fill", color: .brandGreen, title: "Last scan", detail: lastScanDetail)
                    activityCard(icon: "sparkles", color: .brandCoral, title: "Ready to reclaim", detail: model.possibleBytes > 0 ? "\(model.possibleBytes.formattedBytes) across your cleanup categories" : "No cleanup candidates found yet")
                    activityCard(icon: "lock.fill", color: .infoBlue, title: "Privacy status", detail: "All analysis stays on this iPhone")
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How ClearSpace works").font(.headline)
                        step(number: "1", title: "Scan locally", detail: "Photos and contacts are inspected only after you grant access.")
                        step(number: "2", title: "Choose intentionally", detail: "You decide which screenshots, videos, and duplicates matter.")
                        step(number: "3", title: "Review, then remove", detail: "Every cleanup passes through a final confirmation screen.")
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    private var lastScanDetail: String {
        guard let date = model.lastScanDate else { return "Run your first scan from Overview" }
        return "Completed \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    private func activityCard(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(color).frame(width: 42, height: 42).background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private func step(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.caption.weight(.bold)).foregroundStyle(.white).frame(width: 24, height: 24).background(Color.brandCoral, in: Circle())
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: DashboardViewModel
    @State private var showPermissions = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            AmbientBackground()
            List {
                Section("Access") { Button { showPermissions = true } label: { settingsRow("Permissions", detail: permissionDetail, icon: "lock.shield.fill", color: .brandCoral) } }
                Section("Actions") {
                    Button { Task { await model.start() } } label: { settingsRow("Scan again", detail: model.scanMessage, icon: "arrow.clockwise", color: .infoBlue) }
                    Button { showAbout = true } label: { settingsRow("About ClearSpace", detail: "Local-first storage cleanup", icon: "info.circle.fill", color: .brandGreen) }
                }
                Section { Text("ClearSpace never deletes anything without your explicit confirmation. Photos are handled through the system Photos permission and deletion flow.").font(.footnote).foregroundStyle(.secondary) }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPermissions) { PermissionView() }
        .alert("ClearSpace", isPresented: $showAbout) { Button("Done", role: .cancel) {} } message: { Text("A focused, on-device cleanup companion for your photos and contacts.") }
    }

    private var permissionDetail: String {
        let photos = model.photos.permission == .authorized || model.photos.permission == .limited
        let contacts = model.contacts.permission == .authorized
        return photos && contacts ? "Photos and Contacts ready" : "Some access is still needed"
    }

    private func settingsRow(_ title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) { Text(title).foregroundStyle(.primary); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
        }
    }
}
