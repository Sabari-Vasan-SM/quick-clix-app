# 🚀 Quickclix: Convert Web Wrapper into a Native Mobile App

## 📌 Pull Request Description

This PR refactors the Quickclix Flutter app from a browser-based wrapper into a fully native mobile application while keeping the same user flow and visual style as the Quickclix client.

### ✨ What Changed
- 🎨 Replaced the WebView shell with a native Flutter UI that matches the Quickclix client experience.
- 🧩 Split the monolithic `main.dart` into a clean folder structure for better maintainability.
- 🔌 Added a dedicated API service layer for upload, retrieve, and download operations.
- 📂 Implemented native file picking, file download, and file opening support.
- 📋 Added clipboard copy support for retrieved text content.
- 🖼️ Preserved the branded hero, footer, and contact links from the web client.
- 🏷️ Updated the app name to **Quickclix** and version to **2.0.0+2**.
- 🧪 Verified the Flutter app with `flutter analyze` successfully.

### 🛠️ Technical Notes
- 📱 The app now runs as a real mobile application instead of loading the deployed website in a browser view.
- 🌐 The app communicates directly with the Quickclix backend API.
- ⚙️ Release build workflow remains compatible with GitHub Actions.
- 🔐 Production release signing is still a separate follow-up if a store-ready APK is required.

### ✅ Validation
- ✅ `flutter analyze`
- ✅ `flutter pub get`
- ✅ Native app launch verified on Android emulator

### 📦 Outcome
- 🚫 No more browser wrapper
- 🚀 Native mobile UX
- 🧼 Cleaner codebase
- 📲 Ready for further Android/iOS production hardening
