# Live Activities Setup Guide

To enable Live Activities for HealthAI 2030, follow these steps:

## 1. Enable Live Activities Capability in Xcode

- Select your main app target in Xcode.
- Go to **Signing & Capabilities**.
- Click the **+ Capability** button.
- Add **Live Activities**.
- Repeat for your WidgetKit extension target if needed.

## 2. Update Info.plist for Live Activities

Add the following keys to your main app's Info.plist and the widget extension's Info.plist:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

## 3. Register Live Activity Widget in WidgetKit Extension

Ensure your WidgetKit extension contains a WidgetBundle with your Live Activity widget, e.g.:

```swift
@main
struct HealthAI2030LiveActivityBundle: WidgetBundle {
    var body: some Widget {
        HealthMonitoringLiveActivity()
    }
}
```

## 4. Testing Live Activities

- Build and run the app on a device (Live Activities are not supported in the simulator for all features).
- Use the in-app UI to start a Live Activity (e.g., from the Dashboard or a dedicated Live Activities screen).
- Lock the device or view the Dynamic Island to see the Live Activity in action.

## 5. Troubleshooting

- If the Live Activity does not appear, ensure the capability and Info.plist keys are present in both the app and widget extension.
- Make sure the app requests ActivityKit authorization and updates the Live Activity state.
- Check the Xcode console for errors related to ActivityKit or WidgetKit.

---

*For more details, see Apple's [Live Activities documentation](https://developer.apple.com/documentation/activitykit).* 