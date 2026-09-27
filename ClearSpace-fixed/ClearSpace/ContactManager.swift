import Foundation
import Contacts

@MainActor
final class ContactManager: ObservableObject {
    @Published private(set) var permission: PermissionState = .notDetermined
    @Published private(set) var duplicateGroups: [DuplicateContactGroup] = []
    @Published private(set) var isScanning = false
    @Published var errorMessage: String?
    private let store = CNContactStore()

    init() { updatePermission() }

    func updatePermission() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: permission = .authorized
        case .limited: permission = .limited
        case .denied: permission = .denied
        case .restricted: permission = .restricted
        case .notDetermined: permission = .notDetermined
        @unknown default: permission = .denied
        }
    }

    func requestAccess() async {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            permission = granted ? .authorized : .denied
        } catch { permission = .denied; errorMessage = error.localizedDescription }
    }

    func scan() async {
        guard permission == .authorized else { return }
        isScanning = true
        let result = await Task.detached(priority: .userInitiated) {
            Self.fetchDuplicateGroups()
        }.value
        switch result {
        case .success(let groups): duplicateGroups = groups
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isScanning = false
    }

    nonisolated private static func fetchDuplicateGroups() -> Result<[DuplicateContactGroup], Error> {
        do {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
            let contacts = try store.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: keys)
            var buckets: [String: [ContactItem]] = [:]
            for contact in contacts {
                let phone = contact.phoneNumbers.map { $0.value.stringValue.filter { $0.isNumber } }.filter { !$0.isEmpty }.sorted().joined(separator: ",")
                let email = contact.emailAddresses.map { $0.value.lowercased }.sorted().joined(separator: ",")
                let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces).lowercased()
                let key = [name, phone, email].filter { !$0.isEmpty }.joined(separator: "|")
                guard !key.isEmpty else { continue }
                let display = CNContactFormatter.string(from: contact, style: .fullName) ?? name
                let detail = contact.phoneNumbers.first?.value.stringValue ?? contact.emailAddresses.first.map { String($0.value) } ?? ""
                buckets[key, default: []].append(ContactItem(id: contact.identifier, contact: contact, displayName: display, detail: detail, matchKey: key))
            }
            return .success(buckets.filter { $0.value.count > 1 }.map { DuplicateContactGroup(id: $0.key, items: $0.value) })
        } catch {
            return .failure(error)
        }
    }

    func delete(_ items: [ContactItem]) throws {
        let request = CNSaveRequest()
        items.forEach { request.delete($0.contact.mutableCopy() as! CNMutableContact) }
        try store.execute(request)
    }
}
