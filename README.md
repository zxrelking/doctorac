<div align="center">

<img src="docs/banner.jpg" alt="Doctorac â€” Ø¯ÙƒØªÙˆØ±Ø§Ùƒ Healthcare Platform Banner" width="100%" />

<br />

# Doctorac | Ø¯ÙƒØªÙˆØ±Ø§Ùƒ

**ØªØ·Ø¨ÙŠÙ‚ Ø±Ø¹Ø§ÙŠØ© ØµØ­ÙŠØ© Ù…ØªÙƒØ§Ù…Ù„ Ø¨Ø§Ù„Ù„ØºØ© Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© (RTL) â€” All-in-One Arabic Healthcare Platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%2B%20Auth%20%2B%20Storage-1A6B54?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-52B79B?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![OpenStreetMap](https://img.shields.io/badge/Live%20Map-OSM%20%2B%20OSRM-1E88E5?style=for-the-badge&logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![Release](https://img.shields.io/github/v/release/mahmoudzxr/doctorac?style=for-the-badge&color=1A6B54&label=Android%20APK)](https://github.com/mahmoudzxr/doctorac/releases/latest)

[â¬‡ï¸ Download Android APK (`v1.0.0`)](https://github.com/mahmoudzxr/doctorac/releases/latest) Â· [ðŸ“± Explore Every Tab & Screen](#-app-showcase--every-tab-explained) Â· [ðŸ—ï¸ Architecture](#%EF%B8%8F-architecture--tech-stack) Â· [ðŸš€ Setup Guide](#-getting-started)

</div>

---

## âœ¨ About Doctorac (Ø¹Ù† Ø¯ÙƒØªÙˆØ±Ø§Ùƒ)

**Doctorac (Ø¯ÙƒØªÙˆØ±Ø§Ùƒ)** is a production-ready **Arabic (RTL)** mobile healthcare super-app built with **Flutter (Dart 3)**, **Feature-First Clean Architecture**, **Riverpod**, **GoRouter**, and **Supabase**.

It brings every medical service a patient needs across **all 27 Egyptian governorates** into one unified experience:
- ðŸ©º **Book Doctors** by specialty, rating, consultation fee, and real GPS proximity.
- ðŸ§ª **Medical Labs & Tests** with dynamic test pricing and fasting/preparation checklists.
- ðŸ’Š **Nearby Pharmacies** with real-time distance sorting and **prescription photo upload** to Supabase Storage.
- ðŸ©» **Radiology Centers** (MRI, CT, X-Ray, Ultrasound) with automatic lowest-price discovery and safety advisories.
- ðŸ—ºï¸ **Live Nearby GPS Map** (`flutter_map` + OpenStreetMap + OSRM) with a pulsing live blue dot, in-app blue road navigation, Google Maps handoff, and direct in-sheet booking & medicine ordering.
- âŒ **Instant Cancellation & Rescheduling** with one-tap red `X` cancellation dialogs on both **My Bookings** and **My Orders**.

---

## ðŸ“± App Showcase â€” Every Tab Explained

### 1. Persistent Bottom Navigation Tabs (Ø´Ø±ÙŠØ· Ø§Ù„ØªÙ†Ù‚Ù„ Ø§Ù„Ø³ÙÙ„ÙŠ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ)

The app uses GoRouter's `StatefulShellRoute.indexedStack` to preserve each tab's scroll and state seamlessly across **5 tabs**: **Home (Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©)**, **Live Map (Ø§Ù„Ø®Ø±ÙŠØ·Ø©)**, **My Bookings (Ù…ÙˆØ§Ø¹ÙŠØ¯ÙŠ)**, **My Orders (Ø·Ù„Ø¨Ø§ØªÙŠ)**, and **Profile (Ø­Ø³Ø§Ø¨ÙŠ)**.

| Home Â· Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ© | My Bookings Â· Ù…ÙˆØ§Ø¹ÙŠØ¯ÙŠ | My Orders Â· Ø·Ù„Ø¨Ø§ØªÙŠ | Profile Â· Ø­Ø³Ø§Ø¨ÙŠ |
| :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/05-home.png" width="210" alt="Home Tab" /> | <img src="docs/screenshots/11-my-bookings.png" width="210" alt="My Bookings Tab" /> | <img src="docs/screenshots/18-my-orders.png" width="210" alt="My Orders Tab" /> | <img src="docs/screenshots/19-profile.png" width="210" alt="Profile Tab" /> |

- **ðŸ  Home Tab (`Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©`):** Displays the user's real profile avatar, live GPS location selector (covering all 27 Egyptian governorates), personalized Arabic greeting with ECG wave graphics, a **Global Unified Search bar** (searches doctors, labs, pharmacies, and radiology simultaneously), a 2Ã—2 Services Grid, and top nearby doctors.
- **ðŸ—ºï¸ Live Nearby Map Tab (`Ø§Ù„Ø®Ø±ÙŠØ·Ø©`):** Interactive OpenStreetMap view powered by `flutter_map` + `geolocator` live streaming (`distanceFilter: 5m`). Shows a pulsing blue dot for the user's live GPS location, color-coded pins with place names for **Hospitals, Pharmacies, and Doctors**, quick category filter chips, an in-app **OSRM blue road polyline** with ETA & distance, external **Google Maps** launch, and an interactive bottom sheet for instant appointment booking or medicine ordering.
- **ðŸ“… My Bookings Tab (`Ù…ÙˆØ§Ø¹ÙŠØ¯ÙŠ`):** Splits appointments into **Upcoming (Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©)** and **Past (Ø§Ù„Ø³Ø§Ø¨Ù‚Ø©)** with color-coded status badges (`Ù…Ø¤ÙƒØ¯`, `Ù…Ø¬Ø¯ÙˆÙ„`, `Ù…Ù„ØºÙŠ`), booking reference codes, appointment detail sheets, live **Rescheduling**, and a circular **Red `X` cancel button** with confirmation dialog synced directly to Supabase.
- **ðŸ›ï¸ My Orders Tab (`Ø·Ù„Ø¨Ø§ØªÙŠ`):** Filterable by **All / Medications / Labs & Radiology**. Supports step-by-step **Order Tracking**, one-tap **Re-order**, an interactive **Lab Results Viewer** comparing patient values against normal ranges, and a **Red `X` cancel button** for active pharmacy orders.
- **ðŸ‘¤ Profile Tab (`Ø­Ø³Ø§Ø¨ÙŠ`):** Loads and updates real authenticated user data from Supabase (`profiles` + `auth.users` metadata), uploads custom avatars from Camera/Gallery to **Supabase Storage (`avatars`)**, includes a one-tap **GPS auto-fill address** button, and cleanly invalidates cached Riverpod state on sign-out.

---

### 2. Onboarding & Authentication Flow (Ø´Ø§Ø´Ø§Øª Ø§Ù„Ø¨Ø¯Ø§ÙŠØ© ÙˆØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„)

| Splash Â· Ø´Ø§Ø´Ø© Ø§Ù„Ø¨Ø¯Ø§ÙŠØ© | Login Â· ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ | Sign Up Â· Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨ | Reset Password Â· ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± |
| :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/01-splash.png" width="210" alt="Splash Screen" /> | <img src="docs/screenshots/02-login.png" width="210" alt="Login Screen" /> | <img src="docs/screenshots/03-signup.png" width="210" alt="Sign Up Screen" /> | <img src="docs/screenshots/04-reset-password.png" width="210" alt="Reset Password Screen" /> |

- **Splash Screen:** Smooth fade & scale entrance animation with Doctorac's custom `CustomPainter` 3D emerald cross logo, automatically checking the active Supabase session to route users to `/home` or `/login`.
- **Login Screen:** Email & password sign-in with instant Arabic error translation, password recovery modal, and live **Google OAuth** login via Android deep link (`io.doctorac.app://login-callback/`).
- **Sign Up Screen:** Collects real patient details (full name, email, phone, password, and GPS-detected address) and persists them immediately into Supabase Auth and the `profiles` table.
- **Reset Password Screen:** Real-time password strength checklist (minimum 8 characters + letters & numbers) that highlights green as requirements are met and updates credentials via `client.auth.updateUser`.

---

### 3. Doctors Discovery & End-to-End Booking Flow (Ø§Ù„Ø£Ø·Ø¨Ø§Ø¡ ÙˆØ­Ø¬Ø² Ø§Ù„Ù…ÙˆØ§Ø¹ÙŠØ¯)

| Doctors Â· Ø§Ù„Ø£Ø·Ø¨Ø§Ø¡ | Doctor Details Â· ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø·Ø¨ÙŠØ¨ | Date & Time Â· Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ù…ÙˆØ¹Ø¯ | Confirmation Â· ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø¬Ø² | Success Â· ØªÙ… Ø§Ù„Ø­Ø¬Ø² Ø¨Ù†Ø¬Ø§Ø­ |
| :---: | :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/06-doctors-list.png" width="175" alt="Doctors List" /> | <img src="docs/screenshots/07-doctor-details.png" width="175" alt="Doctor Details" /> | <img src="docs/screenshots/08-select-date-time.png" width="175" alt="Select Date and Time" /> | <img src="docs/screenshots/09-booking-confirmation.png" width="175" alt="Booking Confirmation" /> | <img src="docs/screenshots/10-booking-success.png" width="175" alt="Booking Success" /> |

- **Doctors List (`Ø§Ù„Ø£Ø·Ø¨Ø§Ø¡`):** Instant search by name, specialty, or governorate + 6 specialty filter chips, sorted automatically by nearest real-world Haversine distance to the user.
- **Doctor Details (`ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø·Ø¨ÙŠØ¨`):** Full doctor profile, experience, rating, consultation fee, waiting time, interactive clinic map card with Google Maps directions, and a persistent sticky bottom CTA bar.
- **Select Date & Time (`Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ù…ÙˆØ¹Ø¯`):** Reusable Arabic `TableCalendar` + 3Ã—2 time-slot grid shared across Doctors, Labs, Radiology, and Rescheduling flows.
- **Booking Confirmation (`ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø¬Ø²`):** Auto-fills patient details from the user's real profile (with an inline edit dialog when booking for a family member), displays zero-fee transparent pricing, and saves the booking to Supabase.
- **Booking Success (`ØªÙ… Ø§Ù„Ø­Ø¬Ø² Ø¨Ù†Ø¬Ø§Ø­`):** Generates a unique booking reference (`DRC-...` / `LAB-...` / `RAD-...`), includes a one-tap **Add to Google Calendar** button, and clears the confirmation stack to prevent duplicate bookings.

---

### 4. Medical Labs, Pharmacies & Radiology (Ø§Ù„Ù…Ø¹Ø§Ù…Ù„ØŒ Ø§Ù„ØµÙŠØ¯Ù„ÙŠØ§Øª ÙˆØ§Ù„Ø£Ø´Ø¹Ø©)

| Labs Â· Ø§Ù„Ù…Ø¹Ø§Ù…Ù„ | Lab Details Â· ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ù…Ø¹Ù…Ù„ | Pharmacies Â· Ø§Ù„ØµÙŠØ¯Ù„ÙŠØ§Øª | Pharmacy Details Â· ØªÙØ§ØµÙŠÙ„ Ø§Ù„ØµÙŠØ¯Ù„ÙŠØ© | Radiology Â· Ø§Ù„Ø£Ø´Ø¹Ø© | Radiology Details Â· ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø£Ø´Ø¹Ø© |
| :---: | :---: | :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/12-labs-list.png" width="150" alt="Labs List" /> | <img src="docs/screenshots/13-lab-details.png" width="150" alt="Lab Details" /> | <img src="docs/screenshots/14-pharmacies-list.png" width="150" alt="Pharmacies List" /> | <img src="docs/screenshots/15-pharmacy-details.png" width="150" alt="Pharmacy Details" /> | <img src="docs/screenshots/16-radiology-list.png" width="150" alt="Radiology List" /> | <img src="docs/screenshots/17-radiology-details.png" width="150" alt="Radiology Details" /> |

- **Medical Labs (`Ø§Ù„Ù…Ø¹Ø§Ù…Ù„ ÙˆØ§Ù„ØªØ­Ø§Ù„ÙŠÙ„`):** Flattened searchable catalog across 15 Egyptian labs & 26 tests. Selecting any test in **Lab Details** dynamically updates the sticky bottom price bar and the **"Before Your Visit" (`Ù‚Ø¨Ù„ Ø²ÙŠØ§Ø±ØªÙƒ`)** fasting/preparation instructions in real time.
- **Pharmacies (`Ø§Ù„ØµÙŠØ¯Ù„ÙŠØ§Øª`):** 20 nationwide pharmacies sorted live by GPS distance with **"Open Now"** and **"Home Delivery"** filters. Inside **Pharmacy Details**, patients can snap or pick a **prescription image** (uploaded directly to Supabase Storage bucket `prescriptions`) or type medications to create a live order in `My Orders`.
- **Radiology (`Ø§Ù„Ø£Ø´Ø¹Ø©`):** Features a custom 3D MRI hero card and automatically computes the lowest starting price for **MRI, CT, X-Ray, and Ultrasound** across 12 radiology centers. **Radiology Details** dynamically updates pricing and scan-specific safety advisories (e.g., metal implant warnings for MRI).

---

## ðŸ—ï¸ Architecture & Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter (Dart 3, Null Safety, Material 3, RTL `ar_EG`) |
| **Architecture** | Feature-First Clean Architecture (`domain` / `data` / `presentation`) |
| **State Management** | `flutter_riverpod` (`FutureProvider`, `AsyncNotifierProvider`, `StateNotifierProvider`) |
| **Navigation** | `go_router` with 5-tab `StatefulShellRoute.indexedStack` |
| **Backend & Database** | **Supabase** â€” PostgreSQL (9 tables + RLS + Triggers), Auth (Email + Google OAuth), Storage |
| **Maps & Live GPS** | `flutter_map` + OpenStreetMap + `geolocator` + `geocoding` + **OSRM Routing API** |
| **Design System** | Medical Teal `#1A6B54`, Soft Mint `#EBF5F1`, Off-White `#F8FAF9`, `Cairo` via `google_fonts` |

```text
doctorac/
â”œâ”€â”€ assets/
â”‚   â”œâ”€â”€ icon/app_icon.png              # Custom 3D emerald cross launcher icon
â”‚   â””â”€â”€ images/mri_banner.jpg          # 3D MRI hero visual for Radiology section
â”œâ”€â”€ docs/
â”‚   â”œâ”€â”€ banner.jpg                     # GitHub README hero banner
â”‚   â””â”€â”€ screenshots/                   # 19 screen showcase images (01..19)
â”œâ”€â”€ supabase_schema.sql                # 9 PostgreSQL tables, RLS policies, Storage buckets & Triggers
â”œâ”€â”€ supabase_seed.sql                  # Nationwide Egyptian healthcare dataset (27 governorates)
â””â”€â”€ lib/
    â”œâ”€â”€ main.dart                      # App bootstrap, portrait lock, Arabic locale & Supabase init
    â”œâ”€â”€ app.dart                       # Enforced RTL Directionality, Cairo theme & GoRouter
    â”œâ”€â”€ core/
    â”‚   â”œâ”€â”€ config/supabase_config.dart
    â”‚   â”œâ”€â”€ location/                  # 27 Egypt governorates, Haversine distance, real GPS provider
    â”‚   â”œâ”€â”€ router/app_router.dart     # Full route graph + 5-tab StatefulShellRoute
    â”‚   â”œâ”€â”€ theme/                     # AppColors & AppTheme
    â”‚   â”œâ”€â”€ utils/                     # ArabicDateFormatter & external Maps/Calendar launcher
    â”‚   â””â”€â”€ widgets/                   # 3D CustomPainter logo, MainShellScaffold, StickyBottomBar...
    â””â”€â”€ features/
        â”œâ”€â”€ auth/                      # Splash, Login, SignUp, Reset Password
        â”œâ”€â”€ home/                      # Home, Global Unified Search & Egypt Location Picker
        â”œâ”€â”€ map/                       # Live Nearby Map, OSRM Blue Route & Booking/Order Bottom Sheet
        â”œâ”€â”€ doctors/                   # Doctors List & Doctor Details
        â”œâ”€â”€ bookings/                  # Select Date/Time, Confirmation, Success & My Bookings
        â”œâ”€â”€ labs/                      # Labs List & Dynamic Lab Details
        â”œâ”€â”€ pharmacies/                # GPS-Sorted Pharmacies & Prescription Upload
        â”œâ”€â”€ radiology/                 # Radiology List (MRI Banner) & Radiology Details
        â”œâ”€â”€ orders/                    # My Orders, Tracking Stepper & Lab Results Viewer
        â””â”€â”€ profile/                   # Real Editable Profile & Avatar Storage Upload
```

---

## ðŸ—„ï¸ Supabase Database Overview

The PostgreSQL schema in [`supabase_schema.sql`](supabase_schema.sql) defines **9 relational tables** secured with **Row Level Security (RLS)**:
- **Public Medical Catalog:** `doctors`, `labs`, `lab_tests`, `pharmacies`, `radiology_centers`, `radiology_scans`.
- **Private User Tables (`auth.uid() = user_id`):** `profiles`, `bookings`, `orders`.
- **Automation:** `handle_new_user()` trigger automatically creates a real user profile row on registration, and Supabase Storage hosts `avatars`, `prescriptions`, and `lab_results`.

---

## ðŸš€ Getting Started

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/mahmoudzxr/doctorac.git
cd doctorac
flutter pub get
```

### 2. Configure Supabase
1. Create a free project on [Supabase](https://supabase.com/).
2. Run [`supabase_schema.sql`](supabase_schema.sql) followed by [`supabase_seed.sql`](supabase_seed.sql) in the **SQL Editor**.
3. Enable **Google** under **Authentication â†’ Providers** and add `io.doctorac.app://login-callback/` to **URL Configuration â†’ Redirect URLs**.

### 3. Run or Build APK
```bash
# Run on a connected Android device/emulator
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Build release APK
flutter build apk --release
```

---

<div align="center">
  <sub>Built with â¤ï¸ using Flutter & Supabase â€” <strong>Doctorac (Ø¯ÙƒØªÙˆØ±Ø§Ùƒ)</strong></sub>
</div>

