# 💊 Did I Take It?

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20watchOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/swift-SwiftUI-green.svg" alt="Swift">
  <img src="https://img.shields.io/badge/version-1.0-orange.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-yellow.svg" alt="License">
</p>

> ### ⏱️ Never forget your medication again!
> 
> A beautifully simple **Apple Watch-first** medication reminder app with a **companion iPhone app**. Built for people who take daily medications and just need certainty—not complexity.

---

## 🎯 Why Did I Take It?

| Feature | Description |
|---------|-------------|
| ⚡ **One-Tap Tracking** | Mark medications as taken with a single tap |
| ⌚ **Apple Watch Optimized** | Quick access right from your wrist |
| 📱 **iPhone Companion** | Full-featured management on your phone |
| 🔄 **Auto-Sync** | Data syncs between Watch and iPhone |
| 🔔 **Smart Reminders** | Local notifications with action buttons |
| 🎯 **Complications** | See status directly on your watch face |
| 🎤 **Siri Integration** | Voice commands to manage medications |

---

## 🚀 Getting Started

### Prerequisites

```
📱 iOS 16.0+
⌚ watchOS 9.0+
💻 Xcode 15.0+
🍎 Apple Developer Account (for device testing)
```

### Installation

#### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/DidITakeIt.git
cd DidITakeIt
```

#### 2️⃣ Open in Xcode
```bash
open DidITakeIt.xcodeproj
```

#### 3️⃣ Configure Signing
- Select your **Team** in Signing & Capabilities
- Update **Bundle Identifiers** if needed

#### 4️⃣ Build & Run
| Device | Select Scheme |
|--------|---------------|
| Apple Watch | `DidITakeIt Watch App` |
| iPhone | `DidITakeIt` |

---

## 📱 App Features

### iPhone App Screens

#### 🏠 Home Tab
```
┌─────────────────────────────┐
│  Today                     │
│  Jan 15, 2026              │
├─────────────────────────────┤
│  ┌───────────────────────┐  │
│  │ 💊 Aspirin           │  │
│  │ Taken at 8:00 AM  ✓  │  │
│  │ [Already Taken]      │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ 💊 Vitamin D          │  │
│  │ Not taken today       │  │
│  │ [Mark as Taken]       │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

#### 💊 Medications Tab
- View all medications
- Add/Edit/Delete medications
- Set reminder times
- Add custom notes

#### 📊 Statistics Tab
- Daily adherence tracking
- Visual progress indicators
- Completion status

---

### ⌚ Apple Watch App

#### Main Screen
```
┌──────────────────┐
│  ⏰ 10:30 AM    │
│  Jan 15, 2026  │
├──────────────────┤
│  💊 Aspirin     │
│  ✓ Taken       │
│  [Mark Taken]   │
├──────────────────┤
│  💊 Vitamin D   │
│  ○ Not taken   │
│  [Mark Taken]   │
└──────────────────┘
```

#### Features
- ✅ Large tap targets for easy interaction
- ✅ Digital Crown scrolling
- ✅ Current time display
- ✅ Haptic feedback on actions

---

## 🔔 Notifications

### Interactive Actions

| Action | Description |
|--------|-------------|
| ✅ **Mark Taken** | Instantly mark medication as taken |
| ⏰ **Snooze** | Remind again in 10 minutes |
| ❌ **Dismiss** | Close notification |

---

## 🎤 Siri Voice Commands

```
🗣️ "Mark my Aspirin as taken"
🗣️ "Is my Vitamin D taken?"
🗣️ "When should I take my medication?"
🗣️ "Show my medications"
```

---

## 📲 WatchConnectivity Sync

```
    📱 iPhone                    ⌚ Apple Watch
       │                              │
       │  ←─── Medication Data ────  │
       │                              │
       │  ──── Updates ─────────→    │
       │                              │
       │  ←─── Updates ──────────    │
       │                              │
```

- 🔄 **Automatic Sync** - Changes sync automatically
- 📴 **Offline Support** - Works without internet
- 🔒 **Private** - Data stays on your devices

---

## 🛠 Technical Architecture

### Project Structure
```
DidITakeIt/
├── 📁 DidITakeIt/              # iOS App
│   ├── 📄 DidITakeItApp.swift
│   ├── 📄 iOSContentView.swift
│   ├── 📁 Views/
│   │   ├── AddMedicationView.swift
│   │   ├── EditMedicationView.swift
│   │   └── MedicationDetailView.swift
│   ├── 📁 Services/
│   │   └── MedicationStore.swift
│   └── 📁 Models/
│       └── Medication.swift
│
├── 📁 DidITakeIt Watch App/    # watchOS App
│   ├── 📄 DidITakeItApp.swift
│   ├── 📄 watchOSContentView.swift
│   ├── 📄 ComplicationController.swift
│   ├── 📄 Intents.swift
│   ├── 📁 Services/
│   │   └── MedicationStore.swift
│   └── 📁 Models/
│       └── Medication.swift
│
└── 📁 Shared/                  # Shared Code
    ├── 📁 Models/
    ├── 📁 Services/
    └── 📁 Views/
```

### Technologies Used

| Technology | Purpose |
|------------|---------|
| 🖥️ **SwiftUI** | Modern declarative UI |
| ⌚ **WatchKit** | Watch app framework |
| 🔔 **UserNotifications** | Local notifications |
| 🎯 **ClockKit** | Watch complications |
| 🎤 **AppIntents** | Siri integration |
| 📡 **WatchConnectivity** | iPhone-Watch sync |

---

## 🐛 Troubleshooting

### ❓ Notifications not working?
1. Check **Settings → Notifications**
2. Enable **Allow Notifications**
3. Restart the app

### ❓ Complications not updating?
1. Re-add complication on watch face
2. Force close and reopen app
3. Restart your Apple Watch

### ❓ Sync not working?
1. Check both devices are signed into same iCloud
2. Ensure Bluetooth is enabled
3. Keep devices close together

---

## 📈 Roadmap

### ✅ Completed (v1.0)
- [x] Watch app with one-tap tracking
- [x] iPhone companion app
- [x] Local notifications
- [x] Watch complications
- [x] Siri integration
- [x] iPhone-Watch sync
- [x] Accessibility support

### 🔜 Coming Soon
- [ ] CloudKit sync
- [ ] HealthKit integration
- [ ] Weekly reports
- [ ] Family sharing

---

## 🤝 Contributing

Contributions are welcome! Please:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. ✏️ Make your changes
4. 📝 Submit a pull request

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👨‍💻 Author

**Bishal Paudel**  
📧 bishal@example.com  
🌐 [Website](#)

---

## 🙏 Acknowledgments

- ❤️ Built with SwiftUI
- 📖 Inspired by Apple Human Interface Guidelines
- 💡 Thanks to the Swift community

---

<p align="center">
  <strong>💊 Never miss a dose again!</strong>
</p>

<p align="center">
  Made with ❤️ using SwiftUI | Designed for Apple Watch
</p>

