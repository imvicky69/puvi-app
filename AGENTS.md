# Puvi — Agent Guidelines & Architecture Handbook

> **Puvi** is a private, intimate couple's memories and relationship application built for **Puja & Vicky**.
> It serves as their digital sanctuary: tracking time together, milestones, shared memories, secret notes, love pings, and photo albums.

---

## 1. Project Overview & Tech Stack

- **Target Platform**: Android first (`in.xweet.puvi`), compatible with Web/iOS.
- **Framework**: Flutter 3.42+ (Channel beta) / Dart 3.12+ with sound null safety.
- **Design Framework**: Material 3 with custom tokens (`useMaterial3: true`).
- **Theme Mode**: **Strictly Light-Only**. No dark mode or system theme switching.
- **Backend**: Firebase (`puvi-love`):
  - Firebase Authentication (Email/Password & Google Sign-In)
  - Cloud Firestore (Shared couple documents & collections)
  - Firebase Cloud Storage (Photos, audio memos)
  - Firebase Cloud Messaging (FCM pings & push notifications)

---

## 2. Design System: "Love Letters" Aesthetic

The aesthetic is inspired by vintage stationery and warm editorial love letters: warm paper-like surfaces, serene ivory canvas, deep burgundy accents, playful soft-rounded components, and calm, restrained motion.

### A. Color Tokens (`lib/core/theme/app_colors.dart`)

| Token | Hex Value | Role & Usage |
|---|---|---|
| `AppColors.ivory` | `#F7F1E8` | Global scaffold background canvas |
| `AppColors.paper` | `#FFFCF8` | Card surfaces, dialogs, bottom sheets, search inputs |
| `AppColors.burgundy` | `#702D40` | Primary actions, CTA buttons, active state highlights |
| `AppColors.espresso` | `#302522` | Primary editorial text, reading copy, icons |
| `AppColors.dustyRose` | `#D9A6A1` | Romantic accents, favorite hearts, badges |
| `AppColors.blushSand` | `#EDE1D5` | Container fills, chip backgrounds, soft pill tags |
| `AppColors.taupe` | `#6F625C` | Secondary metadata, captions, timestamps, hint text |
| `AppColors.border` | `#E8DDD2` | Structural hair-line borders, subtle dividers |
| `AppColors.error` | `#B3261E` | Validation and destructive error states |
| `AppColors.success` | `#476B51` | Confirmation and success states |

> **Critical**: Always set `surfaceTintColor: Colors.transparent` on Material 3 components (Cards, AppBar, Dialogs, BottomSheet, NavigationBar) to prevent Material 3 purple overlay from washing out the custom ivory/paper tones.

### B. Typography (`lib/core/theme/app_typography.dart`)

| Category | Font Family | Sizes & Roles |
|---|---|---|
| **Editorial Headings** | **Cormorant Garamond** | `display` (40px, w600), `h1` (32px, w600), `h2` (26px, w600), `h3` (20px, w600). Used strictly for hero titles and section headers. |
| **Body & UI** | **DM Sans** | `bodyLarge` (16px, w400), `bodyMedium` (14px, w400), `label` (14px, w600), `caption` (12px, w500), `captionSmall` (11px, w500). Used for all reading copy, form fields, buttons, and navigation. |
| **Handwritten Accents** | **Caveat** | `handwrittenNote` (22px, w500), `handwrittenCaption` (15–16px, w400). Used sparingly for intimate love notes, salutations, and handwritten captions. |

### C. Spacing Grid (`lib/core/theme/app_spacing.dart`)

- Built on a **4px grid**:
  - `xxs`: 4.0
  - `xs`: 8.0
  - `sm`: 12.0
  - `md`: 16.0
  - `lg`: 24.0 (Default screen horizontal padding: `AppSpacing.screenPadding`)
  - `xl`: 32.0
  - `xxl`: 48.0
  - `xxxl`: 64.0
- **Touch Target**: Minimum interactive target constraint is **48×48** logical pixels (`AppSpacing.minTouchTarget`).
- Standard card padding is 16–20px (`AppSpacing.cardInsets`).

### D. Corner Radii (`lib/core/theme/app_radius.dart`)

- Buttons & TextFields: **16px** (`AppRadius.borderButton`)
- Standard Cards: **20px** (`AppRadius.borderCard`)
- Hero & Feature Cards: **28px** (`AppRadius.borderLargeCard`)
- Chips & Pills: **999px** (`AppRadius.borderPill`)

### E. Motion & Curves (`lib/core/theme/app_motion.dart`)

- Durations: `fast` (150ms), `medium` (250ms), `slow` (350ms).
- Curves: `AppMotion.easeOut` (`Curves.easeOutCubic`), `AppMotion.easeInOut` (`Curves.easeInOut`).

---

## 3. Data Model & Firebase Architecture

### Verified Users
- **Puja**: UID `HfzubbPMBsgQugeC5AcNqyWbwlw2` | Email: `puja@puvi.com`
- **Vicky**: UID `bx3PgTysxeX7HMfkyPWiCwtqLZG3` | Email: `vicky@puvi.com`

### Relationship & Couple Anchor
- **Couple Document**: `couples/puvi_couple`
- **Members**: `["HfzubbPMBsgQugeC5AcNqyWbwlw2", "bx3PgTysxeX7HMfkyPWiCwtqLZG3"]`
- **Anniversary (`togetherSince`)**: `2026-04-11T00:00:00.000Z`
- Each user document has:
  - `partnerId`: Direct UID pointer to companion
  - `partnerName`: Companion display name
  - `partnerEmail`: Companion email
  - `coupleId`: `"puvi_couple"`
  - `togetherSince`: Anniversary ISO timestamp

### Existing Collections in Firebase (`puvi-love`)
- `timeline` (18 docs): Significant milestones (title, note, date, location, imageUrl).
- `gallery` (177 docs): Photos and memory snapshots stored in Firebase Storage.
- `chatMessages` (127 docs): In-app private couple chat logs.
- `pings` (76 docs): Quick "thinking of you" and love vibration pings.
- `bucketList` (9 docs): Shared goals and places to visit.
- `shared/stats`: Cumulative love count (`loveCount`) and parting/meeting timestamps.
- `garden`: Shared virtual love plant watering log.
- `moods`: Real-time daily mood status indicators.
- `apartLogs`: Distance and time-apart tracking.

---

## 4. Codebase Directory Structure

```text
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart       # Centralized color tokens & semantic mappings
│       ├── app_spacing.dart      # 4px grid spacing, paddings & touch targets
│       ├── app_radius.dart       # Border radii (buttons: 16, cards: 20, hero: 28)
│       ├── app_motion.dart       # Animation durations & easing curves
│       ├── app_typography.dart   # Cormorant Garamond, DM Sans & Caveat styles
│       └── app_theme.dart        # Global Material 3 light ThemeData
├── features/
│   ├── auth/
│   │   └── login_screen.dart     # Love letters entry screen (Email + Google)
│   ├── home/                     # (Upcoming) Main navigation & dashboard
│   ├── timeline/                 # (Upcoming) Milestones & memory log
│   ├── gallery/                  # (Upcoming) Photo albums & full screen viewer
│   ├── chat/                     # (Upcoming) Private couple chat & pings
│   └── profile/                  # (Upcoming) Anniversary, pins & settings
└── main.dart                     # App entry point & Firebase initialization
```

---

## 5. Non-Negotiable Agent Rules

1. **Never Hardcode Styling in Widgets**: Always reference tokens from `AppColors`, `AppSpacing`, `AppRadius`, and `AppTypography`. Never use ad-hoc inline hex codes or arbitrary padding numbers.
2. **Light-Only Theme**: Never introduce dark mode or system theme toggles unless explicitly directed. The aesthetic strictly depends on warm ivory paper.
3. **Android Package Name**: The package name is **`in.xweet.puvi`**. Because `in` is a reserved keyword in Kotlin, any Kotlin file must escape it with backticks: ``package `in`.xweet.puvi``.
4. **Security & Secrets**: Never stage or commit `serviceAccountKey.json`, `google-services.json`, `users.json`, or `old_app_data.json`.
5. **Quality Verification**: Always run `dart format lib/` and `flutter analyze` after creating or editing code. Maintain **0 warnings and 0 errors**.
