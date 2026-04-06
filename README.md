# 🚗 E-Park Mo — Smart Parking System

**Flutter + Firebase/Firestore | Thesis Project 2026**
*St. Louis College Valenzuela*
*Developers: John Cedrick Pasco, Lorenz Estrella*

---

## 📱 App Overview

E-Park Mo is a smart parking system prototype featuring:
- **Real-time** parking slot monitoring (6 slots)
- **Reservation system** with 15-minute countdown and auto-cancellation
- **Boom barrier control** (auto-closes after 5 seconds)
- **Role-based access**: Guest (reserve) and Admin (dashboard + audit log)
- **Firebase Firestore** backend with real-time streams
- **Mock mode** for UI testing without Firebase

---

## 🗂️ File Structure

```
lib/
├── main.dart                    # App entry point, Provider setup
├── constants/
│   └── app_constants.dart       # Colors, typography, theme, app strings
├── models/
│   ├── user_model.dart          # UserModel (uid, email, name, role)
│   ├── parking_slot.dart        # ParkingSlot (status, sensor, reservation)
│   ├── reservation.dart         # Reservation (timer, status, arrival)
│   └── parking_log.dart         # ParkingLog (audit entries + meta/icons)
├── services/
│   ├── auth_service.dart        # Firebase Auth + mock sign-in/register
│   └── parking_service.dart     # All parking logic: reserve, cancel, barrier, logs
├── providers/
│   └── parking_provider.dart    # ChangeNotifier: all UI state + actions
├── screens/
│   ├── splash_screen.dart       # 2.5s animated intro + auth routing
│   ├── login_screen.dart        # Email/password + demo credentials card
│   ├── register_screen.dart     # Registration with validation
│   └── main_screen.dart         # Glassmorphism bottom nav (3 tabs)
├── tabs/
│   ├── home_tab.dart            # Parking grid + stats + gate status
│   ├── reserve_tab.dart         # Slot selection + live countdown timer
│   ├── admin_dashboard.dart     # Reservation stats + audit log
│   └── profile_tab.dart         # User info + menu + about dialog
└── widgets/
    ├── slot_card.dart           # Individual parking slot card (color-coded)
    ├── stat_card.dart           # Small stats display card
    └── log_entry.dart           # Admin audit log entry row
```

---

## 🚀 Quick Start

### Option A: Mock Mode (No Firebase needed)
The app runs out-of-the-box in mock mode.

```bash
flutter pub get
flutter run
```

Demo credentials are pre-filled in the login screen:
- **Guest:** guest@epark.com / guest123
- **Admin:** admin@epark.com / admin123

### Option B: Firebase Mode

#### Step 1 — Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project named `epark-mo`
3. Enable **Authentication** (Email/Password provider)
4. Enable **Cloud Firestore** (start in test mode)

#### Step 2 — Add Flutter App
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure
flutterfire configure
```
This generates `lib/firebase_options.dart`.

#### Step 3 — Enable Firebase in main.dart
Uncomment the Firebase lines in `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### Step 4 — Switch off Mock Mode
In `lib/services/auth_service.dart`, change:
```dart
const bool kUseMockMode = false;
```

#### Step 5 — Seed Initial Data
```bash
# In Firebase Console → Firestore, manually create:
# Collection: parkingSlots
# Documents: slot-1 through slot-6 with fields:
#   slotNumber: 1-6
#   status: "available"
#   isSensorActive: false
#   distanceCm: null
#   userId: null

# Or run the seed script:
npm install firebase-admin
# Download serviceAccountKey.json from Firebase Console → Project Settings → Service Accounts
node firebase_seed.js
```

#### Step 6 — Create Demo Users
In Firebase Console → Authentication → Add users:
- `guest@epark.com` / `guest123`
- `admin@epark.com` / `admin123`

Then in Firestore → `users/{uid}` add:
```json
// Guest user doc
{
  "email": "guest@epark.com",
  "name": "Guest User",
  "role": "guest",
  "createdAt": <timestamp>
}

// Admin user doc
{
  "email": "admin@epark.com",
  "name": "Admin User",
  "role": "admin",
  "createdAt": <timestamp>
}
```

#### Step 7 — Apply Firestore Security Rules
Copy the contents of `firestore.rules` into Firebase Console → Firestore → Rules.

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary Teal | `#0FB9B1` |
| Dark Teal | `#0A8F89` |
| Available (Green) | `#2ECC71` |
| Reserved (Yellow) | `#F1C40F` |
| Occupied (Red) | `#E74C3C` |
| Background | `#F0FAFA` |
| Fonts | Outfit (headings) + Inter (body) |

---

## 🔧 ESP32 Integration (Hardware)

To connect real ultrasonic sensors via ESP32:

1. The ESP32 should write sensor readings to Firestore:
   ```
   /parkingSlots/{slotId}
     distanceCm: <reading>
     isSensorActive: true
     status: "occupied" // if distance < threshold
   ```

2. Use the Firebase REST API or the ESP32 Firebase library:
   - [ESP32 Firebase Arduino](https://github.com/mobizt/Firebase-ESP32)

3. Threshold for "occupied": distance < 20 cm

---

## 📦 Dependencies

```yaml
firebase_core: ^2.27.0       # Firebase setup
firebase_auth: ^4.17.0       # Authentication
cloud_firestore: ^4.15.0     # Realtime database
provider: ^6.1.2             # State management
google_fonts: ^6.2.1         # Outfit + Inter fonts
flutter_animate: ^4.5.0      # Animations
intl: ^0.19.0                # Date/time formatting
uuid: ^4.3.3                 # Unique IDs
shared_preferences: ^2.2.2   # Local storage
```

---

## 🧪 Testing

The app includes full mock mode with pre-seeded data:
- **Slot 3**: Occupied (sensor distance 8.5 cm)
- **Slot 5**: Reserved (12 min remaining)
- **Slots 1, 2, 4, 6**: Available
- Pre-populated audit log with 6 entries
- Barrier: Closed

---

## 📄 License

Thesis project — St. Louis College Valenzuela © 2026
