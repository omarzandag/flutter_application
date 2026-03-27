# 🔧 Firebase Configuration Guide

> **After cloning this repository**, follow these steps to configure Firebase for your local environment.

---

## 📱 Android Setup

### Option A: Use Your Own Firebase Project 

1. **Go to [Firebase Console](https://console.firebase.google.com/)** and create a new project (or use existing).

2. **Register your Android app**:
   - Package name: Check `android/app/build.gradle` → `applicationId`
   - Example: `com.example.flutter_application`

3. **Download `google-services.json`** from Firebase Console.

4. **Place the file** in:

flutter_application/

└── android/

└── app/

└── google-services.json ✅


5. **Ensure dependencies exist** in `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15' // or latest
    }
}
```

6. Apply plugin in android/app/build.gradle:
```
apply plugin: 'com.google.gms.google-services'
```
