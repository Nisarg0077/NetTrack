# 🌐 NetTrack — Modern Data Usage & Network Telemetry Suite

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-informational?style=for-the-badge" alt="Platforms" />
  <img src="https://img.shields.io/badge/Design-Apple%20iOS%2026%20%2F%20macOS-blueviolet?style=for-the-badge" alt="Design" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 📖 Overview

**NetTrack** is a high-performance, privacy-first network monitoring and data usage tracking application for **Windows** and **Android**. Engineered with a unified, state-of-the-art **Apple iOS 26 and macOS Sequoia design system**, NetTrack delivers granular per-application bandwidth statistics, real-time interface telemetry, interactive trend charts, and export capabilities.

---

## ✨ Key Features

### 🎨 Apple iOS 26 & macOS Design System
- **Liquid Glass Acrylic Styling**: Centered floating capsule navigation with real-time acrylic blur (`sigma 30`), subtle hairline glass borders, and smooth sliding indicators.
- **Quick Search Island**: Reachable floating action bubble for instant application search and filtering.
- **Adaptive Inset Grouped Sections**: Squircle cards (`18px` border radius) with solid contrast against light (`#F2F2F7`) and true dark (`#000000`) system backgrounds.
- **Liquid Glass Modal Dialogs**: Apple dialogs with glowing icon badges, rich option cards, and smooth backdrop blurring.
- **Responsive Layout**: Desktop sidebar navigation with active network interface telemetry on large screens, seamlessly switching to a floating capsule on mobile.

---

### 📊 Real-Time Network Telemetry
- **Live Transfer Rates**: Continuous monitoring of current download and upload speeds.
- **Interface Breakdown**: Dynamic separation of Wi-Fi, Mobile Data (Cellular), and Ethernet network adapters.
- **Per-App Usage Tracking**: Detailed app-level upload/download consumption, session breakdown, and percentage metrics.
- **Active Adapter Inspection**: Network interface detection with hardware IP and MAC telemetry.

---

### 📈 Interactive Visual Analytics & Reports
- **Dynamic Charts**: Powered by `fl_chart` with interactive tooltips, data points, and date scaling.
- **Time Range Selector**: Filter metrics across **Today**, **Yesterday**, **This Week (7D)**, **This Month (30D)**, or specify a **Custom Date Range**.
- **Data Exporting (Excel & CSV)**: Generate `.xlsx` spreadsheets (with styled header formatting and totals) or standard `.csv` files.
- **Export History Management**: Built-in archive to open, share, or delete previously generated telemetry reports.

---

### ⚙️ Multi-Platform Background Services
- **Android Foreground Service**: Live notification monitoring with battery-efficient background sampling and restart protection.
- **Windows System Tray**: Minimizes directly to the system tray with live upload/download tooltips and quick actions.
- **Windows Auto-Start with Highest Privileges**: Integrated Windows Task Scheduler engine (`schtasks` with `/rl HIGHEST`) ensuring reliable launch on system startup and Fast Startup without UAC logon blocks.
- **Configurable Polling Frequencies**: Choose between Fast (30s), Recommended (1m), Eco Low Power (5m), or Manual polling.

---

### 🔒 100% Privacy & Local Storage
- All network statistics and logs are processed and stored strictly on the local device.
- Zero analytics, zero cloud logging, and zero external tracking.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technologies & Packages |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) & [Dart](https://dart.dev) |
| **State Management** | [Provider](https://pub.dev/packages/provider) |
| **Charts & Visuals** | [FL Chart](https://pub.dev/packages/fl_chart), [Google Fonts](https://pub.dev/packages/google_fonts) |
| **File Formats & Export** | [excel](https://pub.dev/packages/excel), [csv](https://pub.dev/packages/csv), [share_plus](https://pub.dev/packages/share_plus), [open_filex](https://pub.dev/packages/open_filex) |
| **System Integrations** | [system_tray](https://pub.dev/packages/tray_manager), [window_manager](https://pub.dev/packages/window_manager), [launch_at_startup](https://pub.dev/packages/launch_at_startup) |
| **Background Daemons** | [flutter_background_service](https://pub.dev/packages/flutter_background_service), [usage_stats](https://pub.dev/packages/usage_stats) |
| **Network & Updates** | [http](https://pub.dev/packages/http), [package_info_plus](https://pub.dev/packages/package_info_plus), [url_launcher](https://pub.dev/packages/url_launcher) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.19+ recommended)
- [Android Studio](https://developer.android.com/studio) (for Android compilation)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) with "Desktop development with C++" workload (for Windows compilation)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Nisarg0077/NetTrack.git
   cd NetTrack
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Windows**:
   ```bash
   flutter run -d windows
   ```

4. **Run on Android**:
   ```bash
   flutter run -d <device_id>
   ```

---

## 📦 Building Releases

### Windows Desktop (Installer EXE / Release Bundle)
```bash
flutter build windows --release
```
The compiled binaries will be located in `build/windows/x64/runner/Release/`.

### Android (APK & App Bundle)
```bash
# Build APK
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <b>NetTrack</b> • Crafted with Modern Apple iOS & macOS Design System
</p>
