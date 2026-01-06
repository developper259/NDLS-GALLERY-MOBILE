# ImagePicker Permissions Setup

## Android Permissions

Add these permissions to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:

```xml
<!-- Permissions for accessing gallery -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

## iOS Permissions

Add these permissions to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<!-- Permissions for accessing photo library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to import images</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to photo library to save images</string>
```

## Additional Setup

### For iOS (if needed)

In your `ios/Runner/AppDelegate.swift`, make sure you have:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### For Android (if needed)

In your `android/app/src/main/AndroidManifest.xml`, add this to the `<activity>` tag if you face issues:

```xml
android:requestLegacyExternalStorage="true"
```

## Testing

After adding these permissions:

1. Clean the project: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Run the app: `flutter run`

The app should now properly request and handle gallery permissions.
