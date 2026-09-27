# ClearSpace 

**ClearSpace** is a local-first iOS application designed to help users discover and intelligently clean up device storage clutter—such as similar/duplicate photos, screenshots, oversized videos, and duplicate contacts—before making any deletion decisions.

---

##  App Interface & Visuals

| Overview & Activity | Category Browsing | Smart Detection & Review |
| :---: | :---: | :---: |
| <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.23.png" width="220" alt="Overview Dashboard" /> | <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.30.png" width="220" alt="Clean Categories" /> | <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.33.png" width="220" alt="Similar Photos" /> |
| *Live storage metrics & animated rings* | *Structured cleanup categories* | *Intelligent grouping & keeper selection* |

| Media Filtering | Large Files & History | Configuration & Settings |
| :---: | :---: | :---: |
| <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.38.png" width="220" alt="Screenshots" /> | <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.44.png" width="220" alt="Large Videos" /> | <img src="Assets/Simulator Screenshot - iPhone 17 Pro - 2026-09-27 at 12.57.54.png" width="220" alt="Settings" /> |
| *Targeted screenshot management* | *Oversized video identification* | *Privacy controls & system status* |

---

##  Features

* **Overview Dashboard:** Live storage usage statistics (used/free/total space) visualized with an animated ring chart, alongside quick status updates and one-tap re-scanning.
* **Cleanup Categories:** Dedicated browser for **Similar photos**, **Screenshots**, **Large videos**, and **Duplicate contacts**.
* **Smart Similar Photos:** Groups near-duplicate shots by capture date and resolution, automatically picking the sharpest frame as the "keeper."
* **Review, Then Remove:** Safety-first flow. Items are never deleted directly from browsing lists; selections funnel into a unified Review screen with a clear itemized summary and an explicit confirmation dialog.
* **Activity & History:** Plain-language summary of the latest storage scan results and privacy guarantees.
* **Settings & Controls:** Manage system permissions, trigger manual re-scans, and view app details.

---

##  Architecture & Technical Stack

Built natively with **SwiftUI** and structured using a clean **MVVM** pattern (`ObservableObject` / `@Published` with **no third-party dependencies**):

* **`FileResponsibilityDashboardViewModel`:** Top-level state management, tracking tabs, active selections, and orchestrating scans across managers.
* **`PhotoManager`:** Handles Photos framework permissions, screenshot filtering, large video detection, and similar-photo clustering.
* **`ContactManager`:** Manages Contacts permissions and duplicate-contact detection algorithms.
* **`StorageManager`:** Reads native device volume capacity using `URLResourceValues`.
* **UI-Safety:** All managers are `@MainActor`-isolated, with heavy scanning tasks offloaded to `Task.detached` to ensure zero UI stutter.

---

##  Privacy Guarantee

* **100% On-Device:** All analysis happens locally on your device. No data, metadata, or images are ever uploaded anywhere.
* **Safe Deletion:** Access to Photos and Contacts is strictly used to surface metadata candidates. Deletions go exclusively through Apple's native `PHPhotoLibrary` and `CNSaveRequest` APIs *only* after explicit user confirmation.

---

##  Requirements & Running

* **Requirements:** iOS 16.0+, iPhone X and later, Xcode 15+.
* **How to Run:**
  1. Clone or download the repository (`https://github.com/iprajwallkurs/Cleanspace`).
  2. Open `ClearSpace.xcodeproj` in Xcode.
  3. Select your team under **Signing & Capabilities** (not required for Simulator testing).
  4. Build and run on your target device or simulator.
  5. *Note:* On first launch, grant Photos and Contacts permissions via the setup banner on the Overview tab to view real results.

---

##  Known Limitations & Future Improvements

* **Configurable Thresholds:** The large-video threshold is currently hardcoded at 250MB; a future update will expose this in settings.
* **Advanced Similarity Heuristics:** Moving from a same-day/same-resolution heuristic to perceptual hashing (pHash) will catch broader burst-shot duplicates.
* **Testing:** Add unit tests for `PhotoManager` and `ContactManager` scanning/grouping logic.
* **iPad Adaptation:** Expand `TARGETED_DEVICE_FAMILY` to support responsive iPad layouts.
